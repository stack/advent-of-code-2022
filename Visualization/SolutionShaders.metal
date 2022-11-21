//
//  SolutionShaders.metal
//  Advent of Code 2022 Common
//
//  Created by Stephen H. Gerstacker on 2022-11-03.
//  Copyright © 2022 Stephen H. Gerstacker. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

struct VertexIn {
    float2 position          [[attribute(0)]];
    float2 textureCoordinate [[attribute(1)]];
};

struct VertexOut {
    float4 position [[position]];
    float2 textureCoordinate;
};

vertex VertexOut VertexShader(VertexIn in [[stage_in ]]) {
    VertexOut out;
    out.position = float4(in.position, 0.0, 1.0);
    out.textureCoordinate = in.textureCoordinate;
    
    return out;
}

fragment float4 FragmentShader(VertexOut out [[ stage_in ]],
                               texture2d<float, access::sample> texture [[ texture(0) ]])
{
    constexpr sampler textureSampler(mag_filter::nearest, min_filter::nearest);
    
    const float4 color = texture.sample(textureSampler, out.textureCoordinate);
    
    return color;
}

enum AccessMode : uint8_t {
    AccessModeValue,
    AccessModeTexture
};

enum LightType : uint {
    LightTypeDirectional,
    LightTypeOmnidirectional,
};

struct Light {
    float4x4 viewProjectionMatrix;
    float3 intensity; // product of color and intensity
    float3 position; // world-space position
    float3 direction; // view-space direction
    LightType type;
};

struct SolutionVertexIn {
    float3 position  [[attribute(0)]];
    float3 normal    [[attribute(1)]];
    float3 tangents  [[attribute(2)]];
    float2 texCoords [[attribute(3)]];
};

struct SolutionVertexOut {
    float4 position [[position]];
    float3 worldPosition;
    float3 viewPosition;
    float3 normal;
    float2 texCoords;
};

struct NodeConstants {
    float4x4 modelMatrix;
};

struct MaterialConstants {
    AccessMode albedoMode;
    float3 albedoValue;
    
    AccessMode metallicMode;
    float metallicValue;
    
    AccessMode roughnessMode;
    float roughnessValue;
    
    AccessMode normalMode;
    float3 normalValue;
    
    AccessMode emissiveMode;
    float3 emissiveValue;
    
    AccessMode ambientOcclusionMode;
    float ambientOcclusionValue;
};

struct FrameConstants {
    float4x4 projectionMatrix;
    float4x4 viewMatrix;
    uint lightCount;
};

float DistanceAttenuation(constant Light &light, float3 toLight) {
    switch (light.type) {
        case LightTypeOmnidirectional: {
            float lightDistSq = dot(toLight, toLight);
            return 1.0f / max(lightDistSq, 1e-4);
            break;
        }
        default:
            return 1.0;
    }
}

float DistributionGGX(float3 N, float3 H, float roughness) {
    float a = roughness * roughness;
    float a2 = a * 2;
    
    float NdotH = max(dot(N, H), 0.0);
    float NdotH2 = NdotH * NdotH;
    
    float numerator = a2;
    float denominator = (NdotH2 * (a2 - 1.0) + 1.0);
    denominator = M_PI_F * denominator * denominator;
    
    return numerator / denominator;
}

float3 FresnelSchlick(float cosTheta, float3 f0) {
    return f0 + (1.0 - f0) * pow(clamp(1.0 - cosTheta, 0.0, 1.0), 5.0);
}

float GeometorySchlickGGX(float NdotV, float roughtness) {
    float r = (roughtness + 1.0);
    float k = (r * r) / 8.0;
    
    float numerator = NdotV;
    float denominator = NdotV * (1.0 - k) + k;
    
    return numerator / denominator;
}

float GeometrySmith(float3 N, float3 V, float3 L, float roughess) {
    float NdotV = max(dot(N, V), 0.0);
    float NdotL = max(dot(N, L), 0.0);
    float ggx2 = GeometorySchlickGGX(NdotV, roughess);
    float ggx1 = GeometorySchlickGGX(NdotL, roughess);
    
    return ggx1 * ggx2;
}

#define SRGB_ALPHA 0.055

float LinearFromSRGB(float x) {
    if (x <= 0.04045)
        return x / 12.92;
    else
        return powr((x + SRGB_ALPHA) / (1.0 + SRGB_ALPHA), 2.4);
}

float3 LinearFromSRGB(float3 rgb) {
    return float3(LinearFromSRGB(rgb.r), LinearFromSRGB(rgb.g), LinearFromSRGB(rgb.b));
}

float3 NormalFromMap(texture2d<float> map, SolutionVertexOut in) {
    constexpr sampler normalSampler(filter::nearest);
    
    float3 tangentNormal = map.sample(normalSampler, in.texCoords).xyz;
    
    float3 q1 = dfdx(in.viewPosition);
    float3 q2 = dfdy(in.viewPosition);
    float2 st1 = dfdx(in.texCoords);
    float2 st2 = dfdy(in.texCoords);
    
    float3 N = normalize(in.normal);
    float3 T = normalize(q1 * st2.y - q2 * st1.y);
    float3 B = -normalize(cross(N, T));
    float3x3 TBN = float3x3(T, B, N);
    
    return normalize(TBN * tangentNormal);
}

vertex SolutionVertexOut SolutionVertex(SolutionVertexIn in [[stage_in]],
                                        constant NodeConstants* nodes [[buffer(2)]],
                                        constant FrameConstants &frame [[buffer(3)]],
                                        uint instanceID [[instance_id]])
{
    constant NodeConstants& node = nodes[instanceID];
    
    float4x4 modelMatrix = node.modelMatrix;
    float4x4 modelViewMatrix = frame.viewMatrix * node.modelMatrix;

    float4 worldPosition = modelMatrix * float4(in.position, 1.0);

    float4 viewPosition = frame.viewMatrix * worldPosition;
    float4 viewNormal = modelViewMatrix * float4(in.normal, 0.0);

    SolutionVertexOut out;
    out.position = frame.projectionMatrix * viewPosition;
    out.worldPosition = worldPosition.xyz;
    out.viewPosition = viewPosition.xyz;
    out.normal = viewNormal.xyz;
    out.texCoords = in.texCoords;
    
    return out;
}

fragment float4 SolutionFragment(SolutionVertexOut in [[stage_in]],
                                 constant FrameConstants& frame [[buffer(3)]],
                                 constant Light* lights [[buffer(4)]],
                                 constant MaterialConstants& material [[buffer(5)]],
                                 texture2d<float, access::sample> albedoTexture [[texture(0)]],
                                 texture2d<float, access::sample> metallicTexture [[texture(1)]],
                                 texture2d<float, access::sample> roughnessTexture [[texture(2)]],
                                 texture2d<float, access::sample> normalTexture [[texture(3)]],
                                 texture2d<float, access::sample> emissiveTexture [[texture(4)]],
                                 texture2d<float, access::sample> ambientOcclusionTexture [[texture(5)]],
                                 sampler textureSampler [[sampler(0)]])
{
    float3 albedo;
    float alpha;
    
    if (material.albedoMode == AccessModeValue) {
        albedo = material.albedoValue;
        alpha = 1.0;
    } else {
        float4 color = albedoTexture.sample(textureSampler, in.texCoords);
        albedo = LinearFromSRGB(color.xyz);
        alpha = color.w;
    }
    
    float metallic;
    
    if (material.metallicMode == AccessModeValue) {
        metallic = material.metallicValue;
    } else {
        metallic = metallicTexture.sample(textureSampler, in.texCoords).x;
    }
    
    float roughness;
    
    if (material.roughnessMode == AccessModeValue) {
        roughness = material.roughnessValue;
    } else {
        roughness = roughnessTexture.sample(textureSampler, in.texCoords).x;
    }
    
    float3 ambientOcclusion;
    
    if (material.ambientOcclusionMode == AccessModeValue) {
        ambientOcclusion = material.ambientOcclusionValue;
    } else {
        ambientOcclusion = ambientOcclusionTexture.sample(textureSampler, in.texCoords).xyz;
    }
    
    float3 emissive;
    
    if (material.emissiveMode == AccessModeValue) {
        emissive = material.emissiveValue;
    } else {
        emissive = emissiveTexture.sample(textureSampler, in.texCoords).xyz;
    }
    
    float3 N;
    
    if (material.normalMode == AccessModeValue) {
        N = normalize(in.normal);
    } else {
        N = NormalFromMap(normalTexture, in);
    }
    
    float3 V = normalize(float3(0) - in.viewPosition);
    
    float3 f0 = float3(0.04);
    f0 = mix(f0, albedo, metallic);
    
    float3 l0 = float3(0.0);
    
    for (uint i = 0; i < frame.lightCount; ++i) {
        constant Light &light = lights[i];
        
        float3 L;
        float attenuation;
        
        switch (light.type) {
            case LightTypeDirectional:
                L = normalize(-light.direction);
                attenuation = 1.0;
                
                break;
            case LightTypeOmnidirectional:
                float3 toLight = (light.position - in.worldPosition);
                
                L = normalize(toLight);
                attenuation = DistanceAttenuation(light, toLight);
                
                break;
        }
        
        float3 H = normalize(L + V);
        float3 radiance = light.intensity * attenuation;
        
        float NDF = DistributionGGX(N, H, roughness);
        float G = GeometrySmith(N, V, L, roughness);
        float3 F = FresnelSchlick(clamp(dot(H, V), 0.0, 1.0), f0);
        
        float3 numerator = NDF * G * F;
        float denominator = 4.0 * max(dot(N, V), 0.0) * max(dot(N, L), 0.0) + 0.0001;
        float3 specular = numerator / denominator;
        
        float3 kS = F;
        float3 kD = float3(1.0) - kS;
        
        kD *= 1.0 - metallic;
        
        float NdotL = max(dot(N, L), 0.0);
        
        l0 += (kD * albedo / M_PI_F + specular) * radiance * NdotL;
    }
    
    float3 ambient = float3(0.03) * albedo * ambientOcclusion;
    
    float3 color = ambient + l0 + emissive;
    color = color / (color + float3(1.0));
    color = pow(color, float3(1.0 / 2.4));
    
    return float4(color * alpha, alpha);
}

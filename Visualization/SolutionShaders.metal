//
//  SolutionShaders.metal
//  Advent of Code 2022 Common
//
//  Created by Stephen H. Gerstacker on 2022-11-03.
//  Copyright © 2022 Stephen H. Gerstacker. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

// MARK: - Presentation Shaders

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

// MARK: - Rendering Shaders

enum {
    VertexAttributePosition,
    VertexAttributeNormal,
    VertexAttributeTangent,
    VertexAttributeTexCoords
};

enum class VertexBuffer : int {
    vertexAttributes = 0,
    nodeConstants = 8,
    frameConstants = 9,
    lightConstants = 10
};
    
enum class FragmentBuffer: int {
    frameConstants,
    lightConstants,
    materialConstants,
};
    
enum class FragmentTexture : int {
    baseColor,
    emissive,
    normal,
    metallic,
    roughness,
    ambientOcclusion
};
    
struct FrameConstants {
    float4x4 viewMatrix;
    float4x4 viewProjectionMatrix;
    uint lightCount;
};
    
struct NodeConstants {
    float4x4 modelMatrix;
    float3x3 normalMatrix;
};
    
struct MaterialConstants {
    float4 baseColor;
    float4 emissiveColor;
    float metallicFactor;
    float roughnessFactor;
    float occlusionWeight;
    float opacity;
};
    
struct Material {
    float4 baseColor;
    float metalness;
    float roughness;
    float ambientOcclusion;
};
    
struct Surface {
    float3 reflected { 0 };
    float3 emitted { 0 };
};

struct Light {
    float4 position;
    float4 direction; // w = 1 means punctual; w = 0 means directional
    float4 intensity; // product of color and intensity
    
    float3 directionToPoint(float3 p) {
        if (direction.w == 0) {
            return -direction.xyz;
        } else {
            return p - position.xyz;
        }
    }
    
    float3 evaluateIntensity(float3 toLight) {
        if (direction.w == 0) {
            return intensity.rgb;
        } else {
            float lightDistanceSquared = dot(toLight, toLight);
            float attenuation = 1.0f / max(lightDistanceSquared, 1e-4);
            
            return attenuation * intensity.rgb;
        }
    }
};

struct SolutionVertexIn {
    float3 position  [[attribute(VertexAttributePosition)]];
    float3 normal    [[attribute(VertexAttributeNormal)]];
    float4 tangent   [[attribute(VertexAttributeTangent)]];
    float2 texCoords [[attribute(VertexAttributeTexCoords)]];
};

struct SolutionVertexOut {
    float4 clipPosition [[position]];
    float3 eyePosition;
    float3 eyeNormal;
    float3 eyeTangent;
    float tangentSign [[flat]];
    float2 texCoords;
};

constexpr float3 F0FromIoR(float ior) {
    float k = (1.0f - ior) / (1.0f + ior);
    return k * k;
}

float G1_GGX(float alphaSq, float NdotX) {
    float cosSq = NdotX * NdotX;
    float tanSq = (1.0f - cosSq) / max(cosSq, 1e-4);
    return 2.0f / (1.0f + sqrt(1.0f + alphaSq * tanSq));
}

float GJointSmith(float alphaSq, float NdotL, float NdotV) {
    return G1_GGX(alphaSq, NdotL) * G1_GGX(alphaSq, NdotV);
}

float DTrowbridgeReitz(float alphaSq, float NdotH) {
    float c = (NdotH * NdotH) * (alphaSq - 1.0f) + 1.0f;
    return step(0.0f, NdotH) * alphaSq / (M_PI_F * (c * c));
}
float3 FSchlick(float3 F0, float VdotH) {
    return F0 + (1.0f - F0) * powr(1.0f - abs(VdotH), 5.0f);
}

float3 Lambertian(float3 diffuseColor) {
    return diffuseColor * (1.0f / M_PI_F);
}

float3 BRDF(thread Material &material, float NdotL, float NdotV, float NdotH, float VdotH) {
    float3 baseColor = material.baseColor.rgb;
    float3 diffuseColor = mix(baseColor, float3(0.0f), material.metalness);

    float3 fd = Lambertian(diffuseColor) * material.ambientOcclusion;

    const float3 DielectricF0 = 0.04f; // This results from assuming an IOR of 1.5, the average for common dielectrics
    float3 F0 = mix(DielectricF0, baseColor, material.metalness);
    float alpha = material.roughness * material.roughness;
    float alphaSq = alpha * alpha;

    float D = DTrowbridgeReitz(alphaSq, NdotH);
    float G = GJointSmith(alphaSq, NdotL, NdotV);
    float3 F = FSchlick(F0, VdotH);

    float3 fs = (D * G * F) / (4.0f * abs(NdotL) * abs(NdotV));

    return fd + fs;
}

float remap(float sourceMin, float sourceMax, float destMin, float destMax, float t) {
    float f = (t - sourceMin) / (sourceMax - sourceMin);
    return mix(destMin, destMax, f);
}

vertex SolutionVertexOut SolutionVertex(SolutionVertexIn in [[stage_in]],
                                        constant NodeConstants* nodes [[buffer(VertexBuffer::nodeConstants)]],
                                        constant FrameConstants &frame [[buffer(VertexBuffer::frameConstants)]],
                                        uint instanceID [[instance_id]])
{
    constant NodeConstants& node = nodes[instanceID];
    
    float4 modelPosition = float4(in.position, 1.0f);
    float4 worldPosition = node.modelMatrix * modelPosition;
    float4 eyePosition = frame.viewMatrix * worldPosition;
    
    SolutionVertexOut out;
    out.clipPosition = frame.viewProjectionMatrix * worldPosition;
    out.eyePosition = eyePosition.xyz;
    out.eyeNormal = normalize(node.normalMatrix * in.normal);
    out.eyeTangent = normalize(node.normalMatrix * in.tangent.xyz);
    out.tangentSign = in.tangent.w;
    out.texCoords = in.texCoords;
    
    return out;
}

fragment float4 SolutionFragment(SolutionVertexOut in                                     [[stage_in]],
                                 constant FrameConstants& frame                           [[buffer(FragmentBuffer::frameConstants)]],
                                 constant Light* lights                                   [[buffer(FragmentBuffer::lightConstants)]],
                                 constant MaterialConstants& materialProperties           [[buffer(FragmentBuffer::materialConstants)]],
                                 texture2d<float, access::sample> baseColorTexture        [[texture(FragmentTexture::baseColor)]],
                                 texture2d<float, access::sample> emissiveTexture         [[texture(FragmentTexture::emissive)]],
                                 texture2d<float, access::sample> normalTexture           [[texture(FragmentTexture::normal)]],
                                 texture2d<float, access::sample> metallicTexture         [[texture(FragmentTexture::metallic)]],
                                 texture2d<float, access::sample> roughnessTexture        [[texture(FragmentTexture::roughness)]],
                                 texture2d<float, access::sample> ambientOcclusionTexture [[texture(FragmentTexture::ambientOcclusion)]])
{
    constexpr sampler repeatSampler(filter::linear, mip_filter::linear, address::repeat);
    
    float ambientOcclusion = is_null_texture(ambientOcclusionTexture) ? 1.0f : mix(1.0f, ambientOcclusionTexture.sample(repeatSampler, in.texCoords).r, materialProperties.occlusionWeight);
    float4 baseColor = is_null_texture(baseColorTexture) ? materialProperties.baseColor : baseColorTexture.sample(repeatSampler, in.texCoords) * materialProperties.baseColor;
    float authoredRoughness = is_null_texture(roughnessTexture) ? materialProperties.roughnessFactor : roughnessTexture.sample(repeatSampler, in.texCoords).g * materialProperties.roughnessFactor;
    float metalness = is_null_texture(metallicTexture) ? materialProperties.metallicFactor : metallicTexture.sample(repeatSampler, in.texCoords).b * materialProperties.metallicFactor;
    
    Material material;
    material.baseColor = baseColor;
    material.roughness = remap(0.0f, 1.0f, 0.045f, 1.0f, authoredRoughness);
    material.metalness = metalness;
    material.ambientOcclusion = ambientOcclusion;
    
    float3 V = normalize(-in.eyePosition);
    float3 Ng = normalize(in.eyeNormal);
    
    float3 N;
    
    if (!is_null_texture(normalTexture)) {
        float3 T = normalize(in.eyeTangent);
        float3 B = cross(in.eyeNormal, in.eyeTangent) * in.tangentSign;
        float3x3 TBN = { T, B, Ng };
        float3 Nt = normalTexture.sample(repeatSampler, in.texCoords).xyz * 2.0f - 1.0f;
        N = TBN * Nt;
    } else {
        N = Ng;
    }
    
    Surface surface;
    surface.emitted = is_null_texture(emissiveTexture) ? materialProperties.emissiveColor.rgb : emissiveTexture.sample(repeatSampler, in.texCoords).rgb;
    
    for (uint lightIndex = 0; lightIndex < frame.lightCount; lightIndex += 1) {
        Light light = lights[lightIndex];
        
        float3 lightToPoint = light.directionToPoint(in.eyePosition);
        float3 intensity = light.evaluateIntensity(lightToPoint);
        
        float3 L = normalize(-lightToPoint);
        float3 H = normalize(L + V);
        
        float NdotL = dot(N, L);
        float NdotV = dot(N, V);
        float NdotH = dot(N, H);
        float VdotH = dot(V, H);
        
        float diffuse = saturate(NdotL);
        float3 specular = BRDF(material, NdotL, NdotV, NdotH, VdotH);
        
        surface.reflected += intensity * diffuse * specular;
    }
    
    float3 color = surface.emitted + surface.reflected;
    float alpha = material.baseColor.a * materialProperties.opacity;
    
    return float4(color * alpha, alpha);
}

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

enum LightType : uint {
    LightTypeAmbient,
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
    float2 texCoords [[attribute(2)]];
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
    float3 color;
};

struct FrameConstants {
    float4x4 projectionMatrix;
    float4x4 viewMatrix;
    uint lightCount;
};

vertex SolutionVertexOut SolutionVertex(SolutionVertexIn in [[stage_in]],
                                        constant NodeConstants &node [[buffer(2)]],
                                        constant FrameConstants &frame [[buffer(3)]])
{
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

static float shadow(float3 worldPosition,
                    depth2d<float, access::sample> depthMap,
                    constant float4x4 &viewProjectionMatrix)
{
    float4 shadowNDC = (viewProjectionMatrix * float4(worldPosition, 1));
    shadowNDC.xyz /= shadowNDC.w;
    float2 shadowCoords = shadowNDC.xy * 0.5 + 0.5;
    shadowCoords.y = 1 - shadowCoords.y;

    constexpr sampler shadowSampler(coord::normalized,
                                    address::clamp_to_edge,
                                    filter::linear,
                                    compare_func::greater_equal);
    float depthBias = 5e-3f;
    float shadowCoverage = depthMap.sample_compare(shadowSampler, shadowCoords, shadowNDC.z - depthBias);
    return shadowCoverage;
}

float distanceAttenuation(constant Light &light, float3 toLight) {
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

fragment float4 SolutionFragment(SolutionVertexOut in [[stage_in]],
                                 constant NodeConstants &node [[buffer(2)]],
                                 constant FrameConstants &frame [[buffer(3)]],
                                 constant Light *lights [[buffer(4)]],
                                 texture2d<float, access::sample> textureMap [[texture(0)]],
                                 sampler textureSampler [[sampler(0)]],
                                 depth2d<float, access::sample> shadowMap [[texture(1)]])
{
    float4 baseColor = float4(0.0f);
    
    if (is_null_texture(textureMap)) {
        baseColor = float4(node.color, 1.0);
    } else {
        baseColor = textureMap.sample(textureSampler, in.texCoords);
    }
    
    float specularExponent = 50.0;

    float3 N = normalize(in.normal);
    float3 V = normalize(float3(0) - in.viewPosition);

    float3 litColor { 0 };

    for (uint i = 0; i < frame.lightCount; ++i) {
        float ambientFactor = 0;
        float diffuseFactor = 0;
        float specularFactor = 0;

        constant Light &light = lights[i];

        switch(light.type) {
            case LightTypeAmbient:
                ambientFactor = 1;
                break;
            case LightTypeDirectional: {
                float shadowFactor = 1 - shadow(in.worldPosition, shadowMap, light.viewProjectionMatrix);

                float3 L = normalize(-light.direction);
                float3 H = normalize(L + V);
                diffuseFactor = shadowFactor * saturate(dot(N, L));
                specularFactor = shadowFactor * powr(saturate(dot(N, H)), specularExponent);
                
                break;
            }
            case LightTypeOmnidirectional: {
                float3 toLight = (light.position - in.worldPosition);
                float attenuation = distanceAttenuation(light, toLight);

                float3 L = normalize(toLight);
                float3 H = normalize(L + V);
                diffuseFactor = attenuation * saturate(dot(N, L));
                specularFactor = attenuation * powr(saturate(dot(N, H)), specularExponent);
                
                break;
            }
        }

        litColor += (ambientFactor + diffuseFactor + specularFactor) * light.intensity * baseColor.rgb;
    }

    return float4(litColor * baseColor.a, baseColor.a);
}

vertex float4 SolutionShadow(SolutionVertexIn in [[stage_in]],
                             constant float4x4 &modelViewProjectionMatrix [[buffer(2)]])
{
    return modelViewProjectionMatrix * float4(in.position, 1.0);
}

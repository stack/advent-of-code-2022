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
    float3 baseColor;
    float3 ambientColor;
    float3 diffuseColor;
    float3 specularColor;
    float specularExponent;
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
                                 sampler textureSampler [[sampler(0)]])
{
    float4 baseColor = float4(node.baseColor, 1.0);
    baseColor *= textureMap.sample(textureSampler, in.texCoords);

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
                float3 L = normalize(-light.direction);
                float3 H = normalize(L + V);
                
                diffuseFactor = saturate(dot(N, L));
                specularFactor = powr(saturate(dot(N, H)), node.specularExponent);
                
                break;
            }
            case LightTypeOmnidirectional: {
                float3 toLight = (light.position - in.worldPosition);
                float attenuation = distanceAttenuation(light, toLight);

                float3 L = normalize(toLight);
                float3 H = normalize(L + V);
                
                diffuseFactor = attenuation * saturate(dot(N, L));
                specularFactor = attenuation * powr(saturate(dot(N, H)), node.specularExponent);
                
                break;
            }
        }
        
        float3 ambient = ambientFactor * node.ambientColor;
        float3 diffuse = diffuseFactor * node.diffuseColor;
        float3 specular = specularFactor * node.specularColor;
        
        litColor += (ambient + diffuse + specular) * light.intensity;
    }
    
    litColor = litColor * baseColor.rgb;

    return float4(litColor * baseColor.a, baseColor.a);
}

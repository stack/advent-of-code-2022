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

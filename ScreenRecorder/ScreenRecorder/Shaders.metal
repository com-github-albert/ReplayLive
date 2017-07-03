//
//  Shaders.metal
//  ScreenRecorder
//
//  Created by JT Ma on 03/07/2017.
//  Copyright © 2017 JT Ma. All rights reserved.
//

#include <metal_stdlib>
#include <simd/simd.h>

// Include header shared between this Metal shader code and C code executing Metal API commands
#import "ShaderTypes.h"

using namespace metal;

// Per-vertex inputs fed by vertex buffer laid out with MTLVertexDescriptor in Metal API
typedef struct
{
    float3 position [[attribute(kVertexAttributePosition)]];
    float2 texCoord [[attribute(kVertexAttributeTexcoord)]];
    half3 normal    [[attribute(kVertexAttributeNormal)]];
} Vertex;

// Vertex shader outputs and per-fragmeht inputs.  Includes clip-space position and vertex outputs
//  interpolated by rasterizer and fed to each fragment genterated by clip-space primitives.
typedef struct
{
    float4 position [[position]];
    float2 texCoord;
    half3  eyePosition;
    half3  normal;
} ColorInOut;

// Vertex function
vertex ColorInOut vertexTransform(Vertex in [[stage_in]],
                                  constant Uniforms & uniforms [[ buffer(kBufferIndexUniforms) ]])
{
    ColorInOut out;

    // Make position a float4 to perform 4x4 matrix math on it
    float4 position = float4(in.position, 1.0);

    // Calculate the position of our vertex in clip space and output for clipping and rasterization
    out.position = uniforms.projectionMatrix * uniforms.modelViewMatrix * position;

    // Pass along the texture coordinate of our vertex such which we'll use to sample from texture's
    //   in our fragment function
    out.texCoord = in.texCoord;

    // Calculate the positon of our vertex in eye space
    out.eyePosition = half3((uniforms.modelViewMatrix * position).xyz);

    // Rotate our normals by the normal matrix
    half3x3 normalMatrix = half3x3(uniforms.normalMatrix);
    out.normal = normalize(normalMatrix * in.normal);

    return out;
}

// Fragment function
fragment float4 fragmentLighting(ColorInOut in [[stage_in]],
                                 constant Uniforms & uniforms [[ buffer(kBufferIndexUniforms) ]],
                                 texture2d<half> colorMap     [[ texture(kTextureIndexColor) ]])
{
    constexpr sampler colorSampler(mip_filter::linear,
                                   mag_filter::linear,
                                   min_filter::linear);

    half4 colorSample   = colorMap.sample(colorSampler, in.texCoord.xy);

    float3 normal = float3(in.normal);

    // Calculate the contribution of the directional light as a sum of diffuse and specular terms
    float3 directionalContribution = float3(0);
    {
        // Light falls off based on how closely aligned the surface normal is to the light direction
        float nDotL = saturate(dot(normal, -uniforms.directionalLightDirection));

        // The diffuse term is then the product of the light color, the surface material
        // reflectance, and the falloff
        float3 diffuseTerm = uniforms.directionalLightColor * nDotL;

        // Apply specular lighting...

        // 1) Calculate the halfway vector between the light direction and the direction they eye is looking
        float3 halfwayVector = normalize(-uniforms.directionalLightDirection - float3(in.eyePosition));

        // 2) Calculate the reflection angle between our reflection vector and the eye's direction
        float reflectionAngle = saturate(dot(normal, halfwayVector));

        // 3) Calculate the specular intensity by multiplying our reflection angle with our object's
        //    shininess
        float specularIntensity = saturate(powr(reflectionAngle, uniforms.materialShininess));

        // 4) Obtain the specular term by multiplying the intensity by our light's color
        float3 specularTerm = uniforms.directionalLightColor * specularIntensity;

        // Calculate total contribution from this light is the sum of the diffuse and specular values
        directionalContribution = diffuseTerm + specularTerm;
    }

    // The ambient contribution, which is an approximation for global, indirect lighting, is
    // the product of the ambient light intensity multiplied by the material's reflectance
    float3 ambientContribution = uniforms.ambientLightColor;

    // Now that we have the contributions our light sources in the scene, we sum them together
    // to get the fragment's lighting value
    float3 lightContributions = ambientContribution + directionalContribution;

    // We compute the final color by multiplying the sample from our color maps by the fragment's
    // lighting value
    float3 color = float3(colorSample.xyz) * lightContributions;

    // We use the color we just computed and the alpha channel of our
    // colorMap for this fragment's alpha value
    return float4(color, colorSample.w);
}

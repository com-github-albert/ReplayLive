//
//  ShaderTypes.h
//  ScreenRecorder
//
//  Created by JT Ma on 03/07/2017.
//  Copyright © 2017 JT Ma. All rights reserved.
//

//
//  Header containing types and enum constants shared between Metal shaders and C/ObjC source
//
#ifndef ShaderTypes_h
#define ShaderTypes_h

#include <simd/simd.h>


// Buffer index values shared between shader and C code to ensure Metal shader buffer inputs match
//   Metal API buffer set calls
typedef enum BufferIndices
{
    kBufferIndexMeshPositions = 0,
    kBufferIndexMeshGenerics  = 1,
    kBufferIndexUniforms      = 2
} BufferIndices;

// Attribute index values shared between shader and C code to ensure Metal shader vertex
//   attribute indices match the Metal API vertex descriptor attribute indices
typedef enum VertexAttributes
{
    kVertexAttributePosition  = 0,
    kVertexAttributeTexcoord  = 1,
    kVertexAttributeNormal    = 2,
} VertexAttributes;

// Texture index values shared between shader and C code to ensure Metal shader texture indices
//   match indices of Metal API texture set calls
typedef enum TextureIndices
{
    kTextureIndexColor    = 0,
} TextureIndices;

// Structure shared between shader and C code to ensure the layout of uniform data accessed in
//    Metal shaders matches the layout of uniform data set in C code
typedef struct
{
    // Per Frame Uniforms
    matrix_float4x4 projectionMatrix;
    matrix_float4x4 viewMatrix;

    // Per Mesh Uniforms
    float materialShininess;
    matrix_float4x4 modelViewMatrix;
    matrix_float3x3 normalMatrix;

    // Per Light Properties
    vector_float3 ambientLightColor;
    vector_float3 directionalLightDirection;
    vector_float3 directionalLightColor;

} Uniforms;

#endif /* ShaderTypes_h */


#ifndef UNIVERSAL_PASS_INCLUDED
#define UNIVERSAL_PASS_INCLUDED

struct ShadowCasterA2V
{
    float4 vertex : POSITION;
    float2 uv : TEXCOORD0;
    float3 normal : NORMAL;
    UNITY_VERTEX_INPUT_INSTANCE_ID 
};

struct ShadowCasterV2F
{
    float4 vertex : SV_POSITION;
    float2 uv : TEXCOORD0;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};


struct DepthOnlyA2V
{
    float4 position : POSITION;
    float2 texcoord : TEXCOORD0;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct DepthOnlyV2F
{
    float2 uv : TEXCOORD0;
    float4 positionCS : SV_POSITION;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct PBRForwardA2V
{
    float4 positionOS : POSITION;
    float2 uv : TEXCOORD0;
    float3 normal : NORMAL;
    float4 tangent : TANGENT;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct PBRForwardV2F
{
    float4 positionCS : SV_POSITION;
    float2 uv : TEXCOORD0;
    float3 positionWS : TEXCOORD1;
    float3 normal_dir : TEXCOORD2;
    float3 tangent_dir : TEXCOORD3;
    float3 binormal_dir : TEXCOORD4;
    UNITY_VERTEX_INPUT_INSTANCE_ID   
};



#endif

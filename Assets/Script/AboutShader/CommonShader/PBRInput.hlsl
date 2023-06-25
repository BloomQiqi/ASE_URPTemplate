#ifndef PBR_INPUT
#define PBR_INPUT

struct PBRData
{
    half3 MRA_map;
    half3 albedo_color;
    half _MetaControll;
    half _RoughControll;
    half _AoIntensity;
    half NdotH;
};

struct BlendData
{
    float4 _BlendNoiseMap_ST;
    half4 _BlendColorR_a;
    half4 _BlendColorR_b;
    half4 _BlendColorG_a;
    half4 _BlendColorG_b;
    half4 _BlendColorB_a;
    half4 _BlendColorB_b;
    half4 _BlendColorA_a;
    half4 _BlendColorA_b;
    half _BlendPowerR;
    half _BlendPowerG;
    half _BlendPowerB;
    half _BlendPowerA;
    half _BlendIntensity;
    float3 positionWS;
    half3 normal_dir;
};

struct UpBlendColorData
{
    half4 _NormalBlendColor;
    half _NormalBlendPower;
    half _NormalBlendRange;
    half _NormalBlendContrast;
    half4 _NoiseColorST;
    half _NoiseColorIntensity;
    float2 uv;
    half3 normal_dir;
};

struct UpBlendMapData
{
    half4 _NormalBlendMap_ST;
    half _NormalBlendPowerMap;
    half _NormalBlendRangeMap;
    half _NormalBlendContrastMap;
    half4 _NoiseMapST;
    half _NoiseMapIntensity;
    float3 positionWS;
    float2 uv;
    half3 normal_dir;
};

struct HeightBlendData
{
    half4 _HeightBlendColor;
    half _HeightBlendPower;
    half _HeightBlendRange;
    half _HeightBlendContrast;
};

struct PBRInputData
{
    float3 positionWS;
    half3  normalWS;
    half3  viewDirectionWS;
    half3  lightDirWS;
    half3  halfdirWS;
    half VdotH;
    half NdotL;
    half NdotH;
    half NdotV;
};

#endif
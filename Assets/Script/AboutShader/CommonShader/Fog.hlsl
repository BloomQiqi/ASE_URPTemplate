#include "Assets/Script/AboutShader/CommonShader/PBRInput.hlsl"
#ifndef FOG
#define FOG

float LinearFogFactor(float start, float end, float distance)
{
    return 1 - saturate((end - distance) / (end - start));
}
float ExponentialFogFactor(float density, float distance)
{
    return saturate(exp(-density)*abs(distance));
}
float ExponentialSquaredFogFactor(float density, float distance)
{
    return saturate(exp(-pow((density*abs(distance)),2)));
}

CBUFFER_START(FogFactor)
//if fog open
    float _FogHeightStart;
    float _FogHeightEnd;
    float _FogHeightDensity;
    float _FogDistanceStart;
    float _FogDistanceEnd;
    float _SunFogRange;
    float _SunFogIntensity;
    float4 _FogColor;
    float4 _SunFogColor;
    float _HeightFalloff;
CBUFFER_END

float UE4ExponentialFogFactor(float density, float positionWSY, float distance)
{
    float fogDensity = density * exp2(-_HeightFalloff * (_WorldSpaceCameraPos.y - _FogHeightEnd));
    float falloff = _HeightFalloff * (positionWSY - _WorldSpaceCameraPos.y);
    float fogFactor = (1 - exp2(-falloff)) / falloff * distance;
    float fog = fogDensity * fogFactor;
    // fog *= max(distance - _FogDistanceStart, 0);
    return saturate(fog);
}

void AddFogEffect(PBRInputData inputData, inout half3 final_color)
{
    float3 fog_view_dir = normalize(inputData.positionWS - _WorldSpaceCameraPos.xyz);
    float sunfog = saturate(pow(dot(fog_view_dir, inputData.lightDirWS) * 0.5 + 0.5, _SunFogRange)) * _SunFogIntensity;
    float fog_distance_factor = LinearFogFactor(_FogDistanceStart, _FogDistanceEnd, distance(inputData.positionWS, _WorldSpaceCameraPos.xyz));
    float fog_Height_factor = 1 - ExponentialFogFactor(_FogHeightDensity, inputData.positionWS.y);
    float fog_Height_factor2 = UE4ExponentialFogFactor(_FogHeightDensity, inputData.positionWS.y, fog_distance_factor);
    float fog_factor = min(fog_distance_factor, fog_Height_factor);
    _FogColor = pow(_FogColor, 2.2);
    _SunFogColor = pow(_SunFogColor, 1 / 2.2);
    float4 fog_color = lerp(_FogColor, _SunFogColor, sunfog);
    final_color = lerp(final_color, fog_color, fog_factor);
    final_color = lerp(final_color, fog_color, fog_factor);
}

#endif
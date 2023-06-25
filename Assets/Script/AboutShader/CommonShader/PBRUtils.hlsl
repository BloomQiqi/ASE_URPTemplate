#include "Assets/Script/AboutShader/CommonShader/CommonUtils.hlsl"
#include "Assets/Script/AboutShader/CommonShader/ColorPostProcessing.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
#include "Assets/Script/AboutShader/CommonShader/PBRInput.hlsl"
#include "Assets/Script/AboutShader/CommonShader/Fog.hlsl"
#ifndef PBR_UTILS
#define PBR_UTILS

//Epic Diffuse in Real Shading in Unreal Engine 4 2013
half calcD(half NdotH, half r_2)
{
    half alpha_2 = pow(r_2, 2);
    return alpha_2 / (PI * pow(pow(NdotH, 2) * (alpha_2 - 1) + 1, 2) + 0.00001f);
}

half calcG(half NdotL, half NdotV, half r)
{
    half k = pow(r + 1, 2) / 8;
    half NV = max(NdotV, 0.0);
    half NL = max(NdotL, 0.0);
    half GL = NL / lerp(NL, 1, k);
    half GV = NV / lerp(NV, 1, k);
    return GV * GL;
}

half4 calcF(half4 F0, half VdotH)
{
    return lerp(exp2((-5.55473 * VdotH - 6.98316) * VdotH), 1, F0);
}

half4 PBRSpecular(half NdotH, half NdotL, half NdotV, half VdotH, half r, half4 speculerColor)
{
    half D = calcD(NdotH, pow(r, 2));
    half G = calcG(NdotL, NdotV, r);
    half4 F = calcF(speculerColor, VdotH);
    return D * G * F / (4 * NdotL * NdotV + 0.00001f);
}
half FresnelLerp(half3 c0, half3 c1, half NdotV)
{
    half t = pow(1 - NdotV, 5);
    return lerp(c0, c1, t).r;
}
half3 IndirSpeFactor(half roughness, half metallic, half3 specular, half3 F0, half NdotV)
{
    half surfaceReduction = 1.0 / (roughness * roughness + 1.0);
    half oneMinusReflectivity = kDielectricSpec.a - kDielectricSpec.a * metallic;
    half grazingTerm = saturate((1 - roughness) + (1 - oneMinusReflectivity));
    half3 iblSpecularResult = surfaceReduction * specular * FresnelLerp(F0, grazingTerm.xxx, NdotV);
    return iblSpecularResult;
}
half3 IndirFakeGlassSpeFactor(half roughness, half metallic, half3 specular)
{
    half surfaceReduction = 1.0 / (roughness * roughness + 1.0);
    half oneMinusReflectivity = kDielectricSpec.a - kDielectricSpec.a * metallic;
    half grazingTerm = saturate((1 - roughness) + (1 - oneMinusReflectivity));
    half3 iblSpecularResult = surfaceReduction * specular ;
    return iblSpecularResult;
}
half GetDistanceFade(half3 positionWS)
{
    half4 posVS = mul(GetWorldToViewMatrix(), half4(positionWS, 1));
    //return posVS.z;
    #if UNITY_REVERSED_Z
        half vz = -posVS.z;
    #else
        half vz = posVS.z;
    #endif
    half fade = 1 - smoothstep(60, 80.0, vz);
    return fade;
}

half2 GetParallaxDistort(int sampleTimes, inout half2 uv, half3 view_dir_tangent, Texture2D _MRAMap, sampler sampler_MRAMap, half _ParallaxOffset)
{
    half2 uv_parallax = uv;
    for (int j = 0; j < sampleTimes; j++)
    {
        half height = SAMPLE_TEXTURE2D(_MRAMap, sampler_MRAMap, uv_parallax).a;
        //偏移公式
        uv_parallax = uv_parallax - (0.5 - height) * (view_dir_tangent.xy / view_dir_tangent.z) * _ParallaxOffset * 0.01f;
    }
    return uv_parallax;
}

half AddSelfShadowEffects(float3 positionWS, half3 normal_dir, half NdotL, inout half4 diffuse, inout half4 specular)
{
    float4 SHADOW_COORDS = TransformWorldToShadowCoord(positionWS + normal_dir * 0.3);
    Light mainLight = GetMainLight(SHADOW_COORDS);
    half shadow = mainLight.shadowAttenuation;
    half shadowFadeOut = GetDistanceFade(positionWS);
    shadow = lerp(1, shadow, shadowFadeOut);
    // shadow = saturate(min(max(NdotL, 0), shadow));
    diffuse *= shadow;
    specular *= shadow;
    return shadow;
}

half AddSelfShadowEffects(float3 positionWS, half3 normal_dir, inout half4 diffuse, inout half4 specular)
{
    float4 SHADOW_COORDS = TransformWorldToShadowCoord(positionWS + normal_dir * 0.3);
    Light mainLight = GetMainLight(SHADOW_COORDS);
    half shadow = mainLight.shadowAttenuation;
    half shadowFadeOut = GetDistanceFade(positionWS);
    shadow = lerp(1, shadow, shadowFadeOut);
    diffuse *= shadow;
    specular *= shadow;
    return shadow;
}

half AddSelfShadowEffectsNPC(float3 positionWS, half3 normal_dir, half NdotL)
{
    float4 SHADOW_COORDS = TransformWorldToShadowCoord(positionWS + normal_dir * 0.3);
    Light mainLight = GetMainLight(SHADOW_COORDS);
    half shadow = mainLight.shadowAttenuation;
    half shadowFadeOut = GetDistanceFade(positionWS);
    shadow = lerp(1, shadow, shadowFadeOut);

    // shadow = min(max(NdotL, 0), shadow);
    
    // shadow = saturate(shadow);
    // shadow = saturate(smoothstep(-0.5, 1, shadow));

    // shadow = saturate(smoothstep(-0.35, 1, shadow));
    // shadow = lerp(shadow, 1, shadow);
    return shadow;
}
void AddAdditionalLightSimpleEffects(half3 normal_dir, half3 view_dir, half3 albedo_color, float3 positionWS, inout half4 diffuse, inout half4 specular)
{
    uint pixelLightCount = GetAdditionalLightsCount();
    for (uint lightIndex = 0; lightIndex < pixelLightCount; ++lightIndex)
    {
        Light light = GetAdditionalLight(lightIndex, positionWS);
        half3 light_dir = normalize(light.direction);
        half NdotL = max(0, dot(normal_dir, light_dir));

        half3 half_dir = SafeNormalize(view_dir + light_dir);
        half NdotH = max(0, dot(normal_dir, half_dir));
        
        diffuse += half4(light.color * light.distanceAttenuation * light.shadowAttenuation * albedo_color * NdotL, 1);
        specular += half4(light.color * light.distanceAttenuation * light.shadowAttenuation * NdotH * (1 - step(NdotL, 0)), 1) ;
    }
}

void AddAdditionalLightEffects(half3 normal_dir, half3 view_dir, half NdotV, half roughness, half3 F0, half3 albedo_color, float3 positionWS, inout half4 diffuse, inout half4 specular)
{
    uint pixelLightCount = GetAdditionalLightsCount();
    for (uint lightIndex = 0; lightIndex < pixelLightCount; ++lightIndex)
    {
        Light light = GetAdditionalLight(lightIndex, positionWS);
        half3 light_dir_add = light.direction;
        half NdotL_add = max(dot(normal_dir, light_dir_add), 0.00001f);
        half3 half_dir_add = normalize(view_dir + light_dir_add);
        half NdotH_add = max(dot(normal_dir, half_dir_add), 0.00001f);
        half VdotH_add = max(dot(view_dir, half_dir_add), 0.00001f);

        // half shadow_add = light.shadowAttenuation;
        // half shadowFadeOut_add = GetDistanceFade(positionWS);
        // shadow_add = lerp(1, shadow_add, shadowFadeOut_add);
        // shadow_add = saturate(min(max(NdotL_add, 0), shadow_add - 0.2f));
        diffuse += half4(light.color * light.distanceAttenuation * albedo_color * NdotL_add, 1);
        specular += PBRSpecular(NdotH_add, NdotL_add, NdotV, VdotH_add, roughness, half4(F0, 1)) * PI * half4(light.color, 1) * NdotL_add * light.distanceAttenuation ;
    }
}


half3 custom_sh(half3 normal_dir)
{
    float4 CUSTOM_SHAR = float4(0.0083, -0.0023, 0.0084, 0.0061);
    float4 CUSTOM_SHAG = float4(0.0083, -0.0026, 0.0084, 0.0066);
    float4 CUSTOM_SHAB = float4(0.0083, -0.0011, 0.0085, 0.0062);
    float4 CUSTOM_SHBR = float4(-0.0020, -0.0020, 0.0028, 0.0111);
    float4 CUSTOM_SHBG = float4(-0.0019, -0.0020, 0.0028, 0.0110);
    float4 CUSTOM_SHBB = float4(-0.0020, -0.0021, 0.0029, 0.0111);
    float4 CUSTOM_SHC = float4(0.0026, 0.0026, 0.0027, 1.0000);
    half4 normalForSH = half4(normal_dir, 1.0);
    half3 x;
    x.r = dot(CUSTOM_SHAR, normalForSH);
    x.g = dot(CUSTOM_SHAG, normalForSH);
    x.b = dot(CUSTOM_SHAB, normalForSH);
    half3 x1, x2;
    half4 vB = normalForSH.xyzz * normalForSH.yzzx;
    x1.r = dot(CUSTOM_SHBR, vB);
    x1.g = dot(CUSTOM_SHBG, vB);
    x1.b = dot(CUSTOM_SHBB, vB);
    half vC = normalForSH.x * normalForSH.x - normalForSH.y * normalForSH.y;
    x2 = CUSTOM_SHC.rgb * vC;
    half3 sh = max(half3(0.0, 0.0, 0.0), (x + x1 + x2));
    sh = pow(sh, 1.0 / 2.2);
    return sh;
}
half3 custom_sh_character(half3 normal_dir)
{
    float4 CHARACTER_CUSTOM_SHAR = float4(0.0344, -0.0512, 0.0220, 0.3159);
    float4 CHARACTER_CUSTOM_SHAG = float4(0.0259, -0.0193, 0.0184, 0.4584);
    float4 CHARACTER_CUSTOM_SHAB = float4(0.0231, -0.2944, 0.0065, 0.5083);
    float4 CHARACTER_CUSTOM_SHBR = float4(0.0023, -0.0153, 0.0164, 0.0291);
    float4 CHARACTER_CUSTOM_SHBG = float4(0.0021, -0.0112, 0.0126, 0.0256);
    float4 CHARACTER_CUSTOM_SHBB = float4(-0.0137, -0.0209, 0.0256, 0.0342);
    float4 CHARACTER_CUSTOM_SHC = float4(0.0131, 0.0071, 0.0173, 1.0000);
    half4 normalForSH = half4(normal_dir, 1.0);
    half3 x;
    x.r = dot(CHARACTER_CUSTOM_SHAR, normalForSH);
    x.g = dot(CHARACTER_CUSTOM_SHAG, normalForSH);
    x.b = dot(CHARACTER_CUSTOM_SHAB, normalForSH);
    half3 x1, x2;
    half4 vB = normalForSH.xyzz * normalForSH.yzzx;
    x1.r = dot(CHARACTER_CUSTOM_SHBR, vB);
    x1.g = dot(CHARACTER_CUSTOM_SHBG, vB);
    x1.b = dot(CHARACTER_CUSTOM_SHBB, vB);
    half vC = normalForSH.x * normalForSH.x - normalForSH.y * normalForSH.y;
    x2 = CHARACTER_CUSTOM_SHC.rgb * vC;
    half3 sh = max(half3(0.0, 0.0, 0.0), (x + x1 + x2));
    sh = pow(sh, 1.0 / 2.2);
    return sh;
}

void GetPBRValues(PBRData pbrData, out half metallic, out half roughness, out half ao, out half3 F0)
{
    metallic = pbrData.MRA_map.r * pbrData._MetaControll;
    roughness = pbrData.MRA_map.g * pbrData._RoughControll;
    ao = pbrData.MRA_map.b;
    ao = lerp(1, ao, pbrData._AoIntensity);
    
    //直接光计算
    F0 = lerp(0.04, pbrData.albedo_color.r, metallic);
    //half3 F = F0 + (1 - F0) * exp2((-5.55473 * VdotH - 6.98316) * VdotH);
    //half diffuseK = (1 - F.x) * (1 - metallic);

}

half4 GetSHIndirectColorCharacter(half4 _EnvMap_HDR, half3 albedo_color, half3 normal_dir, half3 view_dir, TextureCube _EnvMap, sampler sampler_EnvMap, half roughness, half metallic, half3 F0, half NdotV)
{
    half4 indirect_diffuse = half4(custom_sh_character(normal_dir) * albedo_color, 1);
    float mip_level = roughness * (1.7 - 0.7 * roughness);
    half3 reflect_dir = reflect(-view_dir, normal_dir);
    half4 color_cubemap = SAMPLE_TEXTURECUBE_LOD(_EnvMap, sampler_EnvMap, reflect_dir, mip_level * 4);
    half3 spec_color = DecodeHDREnvironment(color_cubemap, _EnvMap_HDR);
    half3 indirect_spec = IndirSpeFactor(roughness, metallic, spec_color, F0, NdotV);
    // half4 indirect_color = (half4(indirect_spec, 1)) * ao;
    half4 indirect_color = (indirect_diffuse + half4(indirect_spec, 1));

    return indirect_color;
}

half4 GetSHIndirectColor(half4 _EnvMap_HDR, half3 albedo_color, half3 normal_dir, half3 view_dir, TextureCube _EnvMap, sampler sampler_EnvMap, half roughness, half metallic, half3 F0, half NdotV)
{
    half4 indirect_diffuse = half4(custom_sh(normal_dir) * albedo_color, 1);
    float mip_level = roughness * (1.7 - 0.7 * roughness);
    half3 reflect_dir = reflect(-view_dir, normal_dir);
    half4 color_cubemap = SAMPLE_TEXTURECUBE_LOD(_EnvMap, sampler_EnvMap, reflect_dir, mip_level * 4);
    half3 spec_color = DecodeHDREnvironment(color_cubemap, _EnvMap_HDR);
    half3 indirect_spec = IndirSpeFactor(roughness, metallic, spec_color, F0, NdotV);
    // half4 indirect_color = (half4(indirect_spec, 1)) * ao;
    half4 indirect_color = (indirect_diffuse + half4(indirect_spec, 1));

    return indirect_color;
}
half4 GetFakeGlassSHIndirectColor(half4 _EnvMap_HDR, half3 albedo_color, half3 normal_dir, half3 view_dir, TextureCube _EnvMap, sampler sampler_EnvMap, half roughness, half metallic)
{
    half4 indirect_diffuse = half4(custom_sh(normal_dir) * albedo_color, 1);
    float mip_level = roughness * (1.7 - 0.7 * roughness);
    half3 reflect_dir = reflect(-view_dir, normal_dir);
    half4 color_cubemap = SAMPLE_TEXTURECUBE_LOD(_EnvMap, sampler_EnvMap, reflect_dir, mip_level * 4);
    half3 spec_color = DecodeHDREnvironment(color_cubemap, _EnvMap_HDR);
    half3 indirect_spec = IndirFakeGlassSpeFactor(roughness, metallic, spec_color);
    // half4 indirect_color = (half4(indirect_spec, 1)) * ao;
    half4 indirect_color = (indirect_diffuse + half4(indirect_spec, 1));

    return indirect_color;
}

void InitBlendData(half4 _BlendColorA_a, half4 _BlendColorA_b, half4 _BlendColorB_a, half4 _BlendColorB_b, half4 _BlendColorG_a, half4 _BlendColorG_b,
half4 _BlendColorR_a, half4 _BlendColorR_b, half _BlendIntensity, float4 _BlendNoiseMap_ST, half _BlendPowerA,
half _BlendPowerB, half _BlendPowerG, half _BlendPowerR, half3 normal_dir, float3 positionWS, out BlendData blendData)
{
    blendData._BlendColorA_a = _BlendColorA_a,
    blendData._BlendColorA_b = _BlendColorA_b,
    blendData._BlendColorB_a = _BlendColorB_a,
    blendData._BlendColorB_b = _BlendColorB_b,
    blendData._BlendColorG_a = _BlendColorG_a,
    blendData._BlendColorG_b = _BlendColorG_b,
    blendData._BlendColorR_a = _BlendColorR_a,
    blendData._BlendColorR_b = _BlendColorR_b,
    blendData._BlendIntensity = _BlendIntensity,
    blendData._BlendNoiseMap_ST = _BlendNoiseMap_ST,
    blendData._BlendPowerA = _BlendPowerA,
    blendData._BlendPowerB = _BlendPowerB,
    blendData._BlendPowerG = _BlendPowerG,
    blendData._BlendPowerR = _BlendPowerR, 
    blendData.normal_dir = normal_dir;
    blendData.positionWS = positionWS;
}
 
void AddBlendedColor(BlendData blendData, float3 centerWS, Texture2D _BlendNoiseMap, sampler sampler_BlendNoiseMap, inout half3 albedo_color)
{
    float2 blend_uv_xy = float2(blendData.positionWS.x, blendData.positionWS.y) * blendData._BlendNoiseMap_ST.xy * 0.01 + blendData._BlendNoiseMap_ST.zw;
    float2 blend_uv_xz = float2(blendData.positionWS.x, blendData.positionWS.z) * blendData._BlendNoiseMap_ST.xy * 0.01 + blendData._BlendNoiseMap_ST.zw;
    float2 blend_uv_zy = float2(blendData.positionWS.z, blendData.positionWS.y) * blendData._BlendNoiseMap_ST.xy * 0.01 + blendData._BlendNoiseMap_ST.zw;
    half3 blend_absnormalWS = TriplanarNormalWS(blendData.normal_dir);
    half4 blend_noise = TriplanarDiffuse(_BlendNoiseMap, sampler_BlendNoiseMap, blend_uv_xz, blend_uv_xy, blend_uv_zy, blend_absnormalWS);
    blend_noise = saturate(blend_noise);
    half3 blend_colorR = lerp(blendData._BlendColorR_b, blendData._BlendColorR_a, blend_noise.r).rgb;
    half3 blend_colorG = lerp(blendData._BlendColorG_b, blendData._BlendColorG_a, blend_noise.g).rgb;
    half3 blend_colorB = lerp(blendData._BlendColorB_b, blendData._BlendColorB_a, blend_noise.b).rgb;
    half3 blend_colorA = lerp(blendData._BlendColorA_b, blendData._BlendColorA_a, blend_noise.a).rgb;
    albedo_color = lerp(albedo_color, blend_colorR, blendData._BlendPowerR * blendData._BlendIntensity);
    albedo_color = lerp(albedo_color, blend_colorG, blendData._BlendPowerG * blendData._BlendIntensity);
    albedo_color = lerp(albedo_color, ColorBlendSoftLight(albedo_color, blend_colorB), blendData._BlendPowerB * blendData._BlendIntensity);
    albedo_color = lerp(albedo_color, ColorBlendOverlay(albedo_color, blend_colorA), blendData._BlendPowerA * blendData._BlendIntensity);
}

void InitUPBlendColorData(half _NoiseColorIntensity, half4 _NoiseColorST, half4 _NormalBlendColor, half _NormalBlendContrast, 
half _NormalBlendPower, half _NormalBlendRange, half3 normal_dir, half2 uv, out UpBlendColorData upBlendColorData)
{
    upBlendColorData._NoiseColorIntensity = _NoiseColorIntensity;
    upBlendColorData._NoiseColorST = _NoiseColorST;
    upBlendColorData._NormalBlendColor = _NormalBlendColor;
    upBlendColorData._NormalBlendContrast = _NormalBlendContrast;
    upBlendColorData._NormalBlendPower = _NormalBlendPower;
    upBlendColorData._NormalBlendRange = _NormalBlendRange;
    upBlendColorData.normal_dir = normal_dir;
    upBlendColorData.uv = uv;
}

void AddUpBlendColor(UpBlendColorData upBlendColorData, inout float upnoise, inout half3 albedo_color)
{
    upnoise = FBMvalueNoise(upBlendColorData.uv * upBlendColorData._NoiseColorST.xy + upBlendColorData._NoiseColorST.zw);
    upnoise = lerp(1, upnoise, upBlendColorData._NoiseColorIntensity);
    half upcolor_mask = saturate((dot(upBlendColorData.normal_dir, half3(0, 1, 0)) * upnoise - lerp(1, -1, upBlendColorData._NormalBlendRange)) / upBlendColorData._NormalBlendContrast) * upBlendColorData._NormalBlendPower;
    albedo_color = lerp(albedo_color, upBlendColorData._NormalBlendColor.rgb, upcolor_mask);
}


void InitUpBlendMapData(half _NoiseMapIntensity, half4 _NoiseMapST, half _NormalBlendContrastMap, half4 _NormalBlendMap_ST, half _NormalBlendPowerMap,
                                     half _NormalBlendRangeMap, half3 normal_dir, float3 positionWS, half2 uv, out UpBlendMapData upBlendMapData)
{
    upBlendMapData._NoiseMapIntensity = _NoiseMapIntensity;
    upBlendMapData._NoiseMapST = _NoiseMapST;
    upBlendMapData._NormalBlendContrastMap = _NormalBlendContrastMap;
    upBlendMapData._NormalBlendMap_ST = _NormalBlendMap_ST;
    upBlendMapData._NormalBlendPowerMap = _NormalBlendPowerMap;
    upBlendMapData._NormalBlendRangeMap = _NormalBlendRangeMap;
    upBlendMapData.normal_dir = normal_dir;
    upBlendMapData.positionWS = positionWS;
    upBlendMapData.uv = uv;
}

void AddUpBlendMap(UpBlendMapData upBlendMapData, Texture2D _NormalBlendMap, sampler sampler_NormalBlendMap, inout float upnoise, inout half3 albedo_color)
{
    upnoise = FBMvalueNoise(upBlendMapData.uv * upBlendMapData._NoiseMapST.xy + upBlendMapData._NoiseMapST.zw);
    upnoise = lerp(1, upnoise, upBlendMapData._NoiseMapIntensity);
    half upmap_mask = saturate((dot(upBlendMapData.normal_dir, half3(0, 1, 0)) * upnoise - lerp(1, -1, upBlendMapData._NormalBlendRangeMap)) / upBlendMapData._NormalBlendContrastMap) * upBlendMapData._NormalBlendPowerMap;
    half3 upblend_map = SAMPLE_TEXTURE2D(_NormalBlendMap, sampler_NormalBlendMap, upBlendMapData.positionWS.xz * upBlendMapData._NormalBlendMap_ST.xy + upBlendMapData._NormalBlendMap_ST.zw).rgb;
    albedo_color = lerp(albedo_color, upblend_map, upmap_mask);
}


void InitHeightBlendData(half4 _HeightBlendColor, half _HeightBlendContrast, half _HeightBlendPower, half _HeightBlendRange, out HeightBlendData heightBlendData)
{
    heightBlendData._HeightBlendColor = _HeightBlendColor;
    heightBlendData._HeightBlendContrast = _HeightBlendContrast;
    heightBlendData._HeightBlendPower = _HeightBlendPower;
    heightBlendData._HeightBlendRange = _HeightBlendRange;
}

void AddHeightBlend(HeightBlendData heightBlendData, half heightblendfactor, inout half3 albedo_color)
{
    half heightcolor_mask = saturate((heightblendfactor - lerp(1, -1, heightBlendData._HeightBlendRange)) / heightBlendData._HeightBlendContrast) * heightBlendData._HeightBlendPower;
    albedo_color = lerp(albedo_color, heightBlendData._HeightBlendColor.rgb, heightcolor_mask);
}


//Add New

void InitializePBRInputData(float3 positionWS, half3  normalWS, half3  viewDirectionWS, half3  lightDirWS, out PBRInputData inputData)
{
    inputData.positionWS = positionWS;
    inputData.normalWS = normalWS;
    inputData.viewDirectionWS = viewDirectionWS;
    inputData.lightDirWS = lightDirWS;
    inputData.halfdirWS = normalize(viewDirectionWS + lightDirWS);
    inputData.VdotH = max(dot(viewDirectionWS,  inputData.halfdirWS), 0.00001f);
    inputData.NdotH = max(dot(normalWS, inputData.halfdirWS), 0.00001f);
    inputData.NdotL = max(dot(normalWS, inputData.lightDirWS), 0.00001f);
    inputData.NdotV = max(dot(normalWS, inputData.viewDirectionWS), 0.00001f);
}

half GetShadowFactor(float3 positionWS, half3 normal_dir) 
{
    float4 SHADOW_COORDS = TransformWorldToShadowCoord(positionWS + normal_dir * 0.3);
    Light mainLight = GetMainLight(SHADOW_COORDS);
    half shadow = mainLight.shadowAttenuation;
    half shadowFadeOut = GetDistanceFade(positionWS);
    shadow = lerp(1, shadow, shadowFadeOut); 

    return shadow;
}

//只计算PBR直接光照部分
half3 PBR_Direct(PBRInputData inputData, half3 albedo_color, half metallic, half roughness, half occlusion)
{
    half3 direct_color = 0;

    half3 F0 = lerp(0.04, albedo_color.r, metallic);

    //Direct diffuse
    half4 diffuse = half4(albedo_color * _MainLightColor.rgb * inputData.NdotL, 1.0);

    //Direct specular
    half4 specular = PBRSpecular(inputData.NdotH, inputData.NdotL, inputData.NdotV, inputData.VdotH, roughness, half4(F0, 1)) * PI * _MainLightColor * inputData.NdotL;

    //shadow
    AddSelfShadowEffects(inputData.positionWS, inputData.normalWS, diffuse, specular);


    //Forward方式多光源循环处理 inout:diffuse, specular
    AddAdditionalLightEffects(inputData.normalWS, inputData.viewDirectionWS, inputData.NdotV, roughness, F0, albedo_color, inputData.positionWS, diffuse, specular);

    //AO Effect
    direct_color = ((diffuse + specular) * occlusion).rgb;

    return direct_color;
}

half3 PBR_Direct_NPC(PBRInputData inputData, half3 albedo_color, half metallic, half roughness, half occlusion, half4 sss, half4 sstCol)
{
    half3 direct_color = 0;

    half3 F0 = lerp(0.04, albedo_color.r, metallic);

    half4 specular = PBRSpecular(inputData.NdotH, inputData.NdotL, inputData.NdotV, inputData.VdotH, roughness, float4(F0, 1)) * PI * _MainLightColor * sss;

    half4 diffuse = float4((albedo_color.rgb * _MainLightColor.rgb) * sss.rgb, 1) + sstCol;

    half4 shadow_diffuse = diffuse;
    
    //自阴影
    AddSelfShadowEffects(inputData.positionWS, inputData.normalWS, inputData.NdotL, shadow_diffuse, specular);
    diffuse = lerp(shadow_diffuse, diffuse, 0.5);
    // specular = lerp(shadow_specular, specular, 1 * 0.7);

    //多光源
    AddAdditionalLightEffects(inputData.normalWS, inputData.viewDirectionWS, inputData.NdotV, roughness, F0, albedo_color, inputData.positionWS, diffuse, specular);
    
    direct_color = (diffuse.rgb + specular.rgb) * occlusion;

    return direct_color;
}

//只计算PBR间接光照部分
half3 PBR_InDirect(PBRInputData inputData, half3 albedo_color)
{
    half3 indirect_color = 0;

    indirect_color = CalculateAmbientLight(inputData.normalWS) * albedo_color;

    return indirect_color;
}

half3 PBR_InDirect_NPC(PBRInputData inputData, half3 albedo_color)
{
    //间接光
    half4 indirect_color = 0;

    //环境光
    half4 ambient_color = half4(CalculateAmbientLight(inputData.normalWS), 1);
    half4 ambient_albedo_color = ambient_color;
    ambient_albedo_color.rgb *= albedo_color;
    ambient_albedo_color.rgb += (ambient_albedo_color.rgb * 0.5) * step(_MainLightColor.r + _MainLightColor.g 
                                    + _MainLightColor.b, 3) + albedo_color * 0.1 + ambient_color * 0.01;

    indirect_color = ambient_albedo_color;

    return indirect_color.rgb;
}

half4 PBR(PBRInputData inputData, half3 albedo_color, half metallic, half roughness, half occlusion, half alpha)
{
    half4 final_color;

    half3 direct_color = PBR_Direct(inputData, albedo_color, metallic, roughness, occlusion);
    
    half3 ambient_color = PBR_InDirect(inputData, albedo_color);

    //Direct + Indirect
    final_color.rgb = saturate(direct_color + ambient_color);

    final_color.a = alpha;

    return final_color;
}

half3 PBR_NPC(PBRInputData inputData, half3 albedo_color, half metallic, half roughness, half occlusion, half4 sss, half4 sstCol)
{
    half3 final_color;

    half3 direct_color = PBR_Direct_NPC(inputData, albedo_color, metallic, roughness, occlusion, sss, sstCol);

    half3 indirect_color =PBR_InDirect_NPC(inputData, albedo_color);

    final_color.rgb = saturate(direct_color + indirect_color);
    
    return final_color;
}

half4 NPBR(PBRInputData inputData, half3 albedo_color, half metallic, half roughness, half half_lambert)
{
    half4 final_color = 0;
    half4 diffuse = half4(albedo_color * _MainLightColor.rgb * inputData.NdotL, 1);
    half4 specular = half4(_MainLightColor.rgb * pow(inputData.NdotH, 50 * (1 - roughness) + 20) * metallic, 1) ;

    //自阴影
    AddSelfShadowEffects(inputData.positionWS, inputData.normalWS, inputData.NdotL, diffuse, specular);

    //#region 多光源着色
    //Forward方式多光源循环处理
    AddAdditionalLightSimpleEffects(inputData.normalWS, inputData.viewDirectionWS, albedo_color, inputData.positionWS, diffuse, specular);

    half4 direct_color = (diffuse /*+ specular*/) ;

    //环境光
    // half4 ambient_color = half4(CalculateAmbientLight(normal_dir), 1);
    half4 ambient_color = half4(CalculateAmbientLight(inputData.normalWS) * albedo_color * half_lambert, 1);
    final_color = saturate(direct_color + ambient_color);
    final_color.rgb = lerp(albedo_color, final_color.rgb, 0.9);
    final_color.a = 1.0;
    return final_color;
}

//添加地形混合影响
void TerrainBlend(float3 positionWS, half3 normal_dir, half3 light_dir,  half3 half_dir, Texture2D _TerrainTexture, SamplerState sampler_TerrainTexture,
    Texture2D _TerrainDepthTexture, SamplerState sampler_TerrainDepthTexture, Texture2D _TerrainNormalTexture, SamplerState sampler_TerrainNormalTexture, 
    float _TB_OFFSET_X, float _TB_OFFSET_Y, float _TB_OFFSET_Z, float _TB_SCALE, float _TB_FARCLIP, float _BlendRange, float _FallOff, float _TerrainGloss, inout half4 final_color)
{

    // 相机角坐标与世界坐标差
    float2 pos_relative = (positionWS.xz - float2(_TB_OFFSET_X, _TB_OFFSET_Z)) / _TB_SCALE;

    // 噪声
    // half noise = clamp(perlinNoise(IN.positionWS.xy), 0, 0.1);

    // 材质
    half4 main_color = final_color;
    half4 terrain_color = SAMPLE_TEXTURE2D(_TerrainTexture, sampler_TerrainTexture, pos_relative);

    // 融合
    // float4 depth = SAMPLE_TEXTURE2D(_TerrainDepthTexture, sampler_TerrainDepthTexture, pos_relative);
    float4 sample = SAMPLE_TEXTURE2D(_TerrainDepthTexture, sampler_TerrainDepthTexture, pos_relative);
    float depth = 1 - DecodeFloatRGBA(sample);
    // float4 screenPosition = ComputeScreenPos(TransformWorldToHClip(IN.positionWS), _ProjectionParams.x);
    // float depth = SAMPLE_TEXTURE2D_LOD(_CameraDepthTexture, sampler_CameraDepthTexture, screenPosition.xy / screenPosition.w, 1.0).r;
    // float eyeDepth = LinearEyeDepth(depth, _ZBufferParams);
    
    // half depth = 1 - terrain_color.a;
    float4 blend = (positionWS.y - depth * _TB_FARCLIP - _TB_OFFSET_Y) / (_BlendRange /* * noise */);
    float blend_value = smoothstep(0, 1, blend.y);
    blend_value = clamp(0, 1, pow(blend_value, _FallOff));

    // 法线
    //float3 terrain_normal = UnpackNormal(SAMPLE_TEXTURE2D(_TerrainNormalTexture, sampler_TerrainNormalTexture, pos_relative));
    float3 terrain_normal = UnpackNormal(SAMPLE_TEXTURE2D(_TerrainNormalTexture, sampler_TerrainNormalTexture, pos_relative));
    //terrain_normal = normalize(mul(terrain_normal, TBN));
    float3 blend_normal = lerp(terrain_normal, normal_dir, blend_value);

    // 地形光照模拟
    half NdotL_terrain = dot(blend_normal, light_dir);
    half NdotL_factor_terrain = max(NdotL_terrain, 0);
    // half half_lambert_terrain = saturate(NdotL_terrain * 0.5 + 1);    

    half specular_factor = pow(saturate(dot(blend_normal, half_dir)), _TerrainGloss);

    half4 diffuse_terrain = terrain_color * NdotL_factor_terrain * _MainLightColor;
    
    half4 specular_terrain = (_MainLightColor) * min(specular_factor * 0.1, 0.01) * (1 - step(NdotL_terrain, 0));


    AddSelfShadowEffects(positionWS, blend_normal, diffuse_terrain, specular_terrain);

    //环境光
    // half3 ambient_color = CalculateAmbientLight(normal_dir) * diffuse * 0.5f;
    // half3 final_color = (diffuse + specular + ambient_color);
    half4 ambient_color_terrain = half4(CalculateAmbientLight(blend_normal) * terrain_color, 1);
    half4 terrain_color_final = half4(specular_terrain + diffuse_terrain + ambient_color_terrain.rgb, 1);

    final_color = lerp(terrain_color_final, main_color, blend_value);
}

#endif
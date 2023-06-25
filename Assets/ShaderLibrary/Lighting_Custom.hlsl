#ifndef UNIVERSAL_LIGHTING_INCLUDED_CUSTOM
#define UNIVERSAL_LIGHTING_INCLUDED_CUSTOM

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

half3 GlossyEnvironmentReflection_Custom(half3 reflectVector, half perceptualRoughness, half occlusion)
{
#if !defined(_ENVIRONMENTREFLECTIONS_OFF)
    half mip = PerceptualRoughnessToMipmapLevel(perceptualRoughness);
    half4 encodedIrradiance = SAMPLE_TEXTURECUBE_LOD(unity_SpecCube0, samplerunity_SpecCube0, reflectVector, mip);

#if defined(UNITY_USE_NATIVE_HDR)
    half3 irradiance = encodedIrradiance.rgb;
#else
    half3 irradiance = DecodeHDREnvironment(encodedIrradiance, unity_SpecCube0_HDR);
#endif

    return irradiance * occlusion;
#endif // GLOSSY_REFLECTIONS

#if defined(_CUSTOMENVIRONMENTREFLECTIONS_ON)


#endif

    return _GlossyEnvironmentColor.rgb * occlusion;
}

half3 GlobalIllumination_Custom(BRDFData brdfData,
    half3 bakedGI, half occlusion,
    half3 normalWS, half3 viewDirectionWS)
{
    half3 reflectVector = reflect(-viewDirectionWS, normalWS);
    half NoV = saturate(dot(normalWS, viewDirectionWS));
    half fresnelTerm = Pow4(1.0 - NoV);

    half3 indirectDiffuse = bakedGI * occlusion;

    //采样unity_SpecCube0或者_EnvMap。 Unity会默认生成反射球，若不需要在材质球面板Toggle Off
    half3 indirectSpecular = GlossyEnvironmentReflection_Custom(reflectVector, brdfData.perceptualRoughness, occlusion);

    half3 color = EnvironmentBRDF(brdfData, indirectDiffuse, indirectSpecular, fresnelTerm);

    return color;
}


half4 UniversalFragmentPBR_Custom(InputData inputData, SurfaceData surfaceData)
{
#ifdef _SPECULARHIGHLIGHTS_OFF
    bool specularHighlightsOff = true;
#else
    bool specularHighlightsOff = false;
#endif

    BRDFData brdfData;

    // 初始化PBR计算需要的相关数据
    InitializeBRDFData(surfaceData.albedo, surfaceData.metallic, surfaceData.specular, surfaceData.smoothness, surfaceData.alpha, brdfData);

    BRDFData brdfDataClearCoat = (BRDFData)0;

    // To ensure backward compatibility we have to avoid using shadowMask input, as it is not present in older shaders
#if defined(SHADOWS_SHADOWMASK) && defined(LIGHTMAP_ON)
    half4 shadowMask = inputData.shadowMask;
#elif !defined (LIGHTMAP_ON)
    half4 shadowMask = unity_ProbesOcclusion;
#else
    half4 shadowMask = half4(1, 1, 1, 1);
#endif

    Light mainLight = GetMainLight(inputData.shadowCoord, inputData.positionWS, shadowMask);

//    //屏幕空间AO 暂时不用
//#if defined(_SCREEN_SPACE_OCCLUSION)
//    AmbientOcclusionFactor aoFactor = GetScreenSpaceAmbientOcclusion(inputData.normalizedScreenSpaceUV);
//    mainLight.color *= aoFactor.directAmbientOcclusion;
//    surfaceData.occlusion = min(surfaceData.occlusion, aoFactor.indirectAmbientOcclusion);
//#endif

    // _MIXED_LIGHTING_SUBTRACTIVE
    MixRealtimeAndBakedGI(mainLight, inputData.normalWS, inputData.bakedGI);

    //间接光照
    half3 color = GlobalIllumination_Custom(brdfData,
        inputData.bakedGI, surfaceData.occlusion,
        inputData.normalWS, inputData.viewDirectionWS);

    //直接光照 Specular + Diffuse
    color += LightingPhysicallyBased(brdfData, brdfDataClearCoat,
        mainLight,
        inputData.normalWS, inputData.viewDirectionWS,
        surfaceData.clearCoatMask, specularHighlightsOff);

#ifdef _ADDITIONAL_LIGHTS
    uint pixelLightCount = GetAdditionalLightsCount();
    for (uint lightIndex = 0u; lightIndex < pixelLightCount; ++lightIndex)
    {
        Light light = GetAdditionalLight(lightIndex, inputData.positionWS, shadowMask);
#if defined(_SCREEN_SPACE_OCCLUSION)
        light.color *= aoFactor.directAmbientOcclusion;
#endif
        color += LightingPhysicallyBased(brdfData, brdfDataClearCoat,
            light,
            inputData.normalWS, inputData.viewDirectionWS,
            surfaceData.clearCoatMask, specularHighlightsOff);
    }
#endif

#ifdef _ADDITIONAL_LIGHTS_VERTEX
    color += inputData.vertexLighting * brdfData.diffuse;
#endif

    color += surfaceData.emission;

    return half4(color, surfaceData.alpha);
}

half4 UniversalFragmentPBR_Custom(InputData inputData, half3 albedo, half metallic, half3 specular,
    half smoothness, half occlusion, half3 emission, half alpha)
{
    SurfaceData s;
    s.albedo = albedo;
    s.metallic = metallic;
    s.specular = specular;
    s.smoothness = smoothness;
    s.occlusion = occlusion;
    s.emission = emission;
    s.alpha = alpha;
    return UniversalFragmentPBR_Custom(inputData, s);
}



#endif

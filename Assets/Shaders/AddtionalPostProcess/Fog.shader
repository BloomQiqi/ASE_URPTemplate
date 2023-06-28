Shader "Custom/RenderFeature/Fog"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" { }
        _FogColor ("_FogColor", Color) = (1, 1, 1, 1)
        [HDR]_SunFogColor ("_SunFogColor", Color) = (1, 1, 1, 1)
        _FogDistanceStart ("_FogDistanceStart", float) = 1
        _FogDistanceEnd ("_FogDistanceEnd", float) = 1
        _FogHeightDensity ("_FogHeightDensity", float) = 1
        _FogHeightEnd ("_FogHeightEnd", float) = 1
        _HeightFalloff ("_HeightFalloff", Range(0, 0.5)) = 0.02
        _SunFogRange ("_SunFogRange", float) = 1
        _SunFogIntensity ("_SunFogIntensity", Range(0, 1)) = 1
    }

    SubShader
    {
        Tags { "RenderPipeline" = "UniversalPipeline" "Queue" = "Geometry" "RenderType" = "Opaque" }
        HLSLINCLUDE
        //CG中核心代码库 #include "UnityCG.cginc"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

        ENDHLSL
        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Varings
            {
                float2 uv : TEXCOORD0;
                float4 positionCS : SV_POSITION;
            };

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);

            TEXTURE2D(_CameraDepthTexture);
            SAMPLER(sampler_CameraDepthTexture);
            
            CBUFFER_START(UnityPerMaterial)
                float4 _FogColor;
                float4 _SunFogColor;
                float _SunFogIntensity;
                float _SunFogRange;
                float _FogDistanceEnd;
                float _FogDistanceStart;
                float _FogHeightDensity;
                float _FogHeightEnd;
                float _HeightFalloff;
            CBUFFER_END

            float4 GetWorldSpacePosition(float depth, float2 uv)
            {
                // // 屏幕空间 --> 视锥空间
                // float4 view_vector = mul(_InverseProjectionMatrix, float4(2.0 * uv - 1.0, depth, 1.0));
                // view_vector.xyz /= view_vector.w;
                // //视锥空间 --> 世界空间
                // float4 world_vector = mul(_InverseViewMatrix, float4(view_vector.xyz, 1));
                // return world_vector;
                float4 positionCS = ComputeClipSpacePosition(uv, depth);
                float4 hpositionWS = mul(UNITY_MATRIX_I_VP, positionCS);
                hpositionWS.xyz /= hpositionWS.w;
                return hpositionWS;
            }

            float LinearFogFactor(float start, float end, float distance)
            {
                return 1 - saturate((end - distance) / (end - start));
            }
            float UE4ExponentialFogFactor(float density, float positionWSY, float distance)
            {
                float fogDensity = density * exp2(-_HeightFalloff * (_WorldSpaceCameraPos.y - _FogHeightEnd));
                float falloff = _HeightFalloff * (positionWSY - _WorldSpaceCameraPos.y);
                float fogFactor = (1 - exp2(-falloff)) / falloff * distance;
                float fog = fogDensity * fogFactor;
                // fog *= max(distance - _FogDistanceStart, 0);
                return saturate(fog);
            }
            float ExponentialFogFactor(float density, float distance)
            {
                return saturate(exp(-density) * abs(distance));
            }
            Varings vert(Attributes IN)
            {
                Varings OUT;
                VertexPositionInputs positionInputs = GetVertexPositionInputs(IN.positionOS.xyz);
                OUT.positionCS = positionInputs.positionCS;
                OUT.uv = IN.uv;
                return OUT;
            }

            half4 frag(Varings IN) : SV_Target
            {
                half4 final_color = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv);

                float depth = SAMPLE_TEXTURE2D_X_LOD(_CameraDepthTexture, sampler_CameraDepthTexture, IN.uv, 1.0).r;
                float LinearDepth1 = Linear01Depth(depth, _ZBufferParams);
                float4 positionWS = GetWorldSpacePosition(depth, IN.uv);

                float3 light_dir = normalize(_MainLightPosition).xyz;
                float3 view_dir = normalize(positionWS.xyz - _WorldSpaceCameraPos.xyz);

                float sunfog = saturate(pow(dot(view_dir, light_dir.xyz) * 0.5 + 0.5, _SunFogRange)) * _SunFogIntensity;

                float fog_distance_factor = LinearFogFactor(_FogDistanceStart, _FogDistanceEnd, distance(positionWS, _WorldSpaceCameraPos.xyz));

                float fog_Height_factor = 1 - ExponentialFogFactor(_FogHeightDensity, positionWS.y);
                float fog_Height_factor2 = UE4ExponentialFogFactor(_FogHeightDensity, positionWS.y, fog_distance_factor);

                float fog_factor = min(fog_distance_factor, fog_Height_factor);
                float4 fog_color = lerp(_FogColor, _SunFogColor, sunfog);
                final_color = lerp(final_color, fog_color, fog_factor);
                final_color = lerp(final_color, fog_color, fog_factor);

                // final_color = lerp(final_color, fog_color, fog_Height_factor2);

                // final_color.rgb += 0.1f;
                return float4(final_color.rgb, 1);
            }
            ENDHLSL
        }
    }
}
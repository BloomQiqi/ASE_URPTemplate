Shader /*ase_name*/ "Universal/UniversalPBR_Template_New" /*end*/
{
	Properties
	{
		/*ase_props*/


        [HideInInspector]_ScanLightIntensity ("", float) = 0
		//_EnvMap( "Environment Map", CUBE ) = "white"{}
		[HideInInspector][ToggleOff] _SpecularHighlights("Specular Highlights", Float) = 1.0
	}

	SubShader
	{
		/*ase_subshader_options:Name=Additional Options
			Option:Two Sided:On,Cull Back,Cull Front:Cull Back
				On:SetPropertyOnSubShader:CullMode,Off
				Cull Back:SetPropertyOnSubShader:CullMode,Back
				Cull Front:SetPropertyOnSubShader:CullMode,Front
			Option:Fragment Normal Space,InvertActionOnDeselection:Tangent,Object,World:Tangent
				Tangent:SetDefine:_NORMAL_DROPOFF_TS 1
				Tangent:SetPortName:Forward:1,Normal
				Object:SetDefine:_NORMAL_DROPOFF_OS 1
				Object:SetPortName:Forward:1,Object Normal
				World:SetDefine:_NORMAL_DROPOFF_WS 1
				World:SetPortName:Forward:1,World Normal
			Option:Cast Shadows:false,true:true
				true:IncludePass:ShadowCaster
				false,disable:ExcludePass:ShadowCaster
				true:ShowOption:  Use Shadow Threshold
				false:HideOption:  Use Shadow Threshold
			Option:  Use Shadow Threshold:false,true:false
				true:SetDefine:_ALPHATEST_SHADOW_ON 1
				true:ShowPort:Forward:Alpha Clip Threshold Shadow
				false,disable:RemoveDefine:_ALPHATEST_SHADOW_ON 1
				false,disable:HidePort:Forward:Alpha Clip Threshold Shadow
			Option:Receive Shadows:false,true:true
				true:RemoveDefine:_RECEIVE_SHADOWS_OFF 1
				false:SetDefine:_RECEIVE_SHADOWS_OFF 1
			Option:GPU Instancing:false,true:true
				true:SetDefine:pragma multi_compile_instancing
				true:SetDefine:pragma instancing_options procedural:setupGPUI
				false:RemoveDefine:pragma multi_compile_instancing
				false:RemoveDefine:pragma instancing_options procedural:setupGPUI
			Port:Forward:Emission
				On:SetDefine:_EMISSION
			Port:Forward:Baked GI
				On:SetDefine:ASE_BAKEDGI 1
			Port:Forward:Alpha Clip Threshold
				On:SetDefine:_ALPHATEST_ON 1
			Port:Forward:Alpha Clip Threshold Shadow
				On:SetDefine:_ALPHATEST_ON 1
			Port:Forward:Normal
				On:SetDefine:_NORMALMAP 1
		*/

		Tags
		{
			"RenderPipeline" = "UniversalPipeline"
			"RenderType"="Opaque"
			"Queue"="Geometry+0"
		}

		Cull Back
		ZWrite On
		ZTest LEqual
		Offset 0,0
		AlphaToMask Off

		/*ase_stencil*/

		HLSLINCLUDE
		#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
		//#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
		// #include "Assets/Script/AboutShader/CommonShader/ColorPostProcessing.hlsl"
		#include "Assets/Script/AboutShader/CommonShader/CommonUtils.hlsl" 
		#include "Assets/Script/AboutShader/CommonShader/PBRUtils.hlsl"
		#include "Assets/Script/AboutShader/CommonShader/PBRInput.hlsl"
		#include "Assets/Script/AboutShader/CommonShader/Pass.hlsl"

		//#include "Assets/GPUDriven/Shaders/Include/GPUInstancerInclude.cginc"
		//#pragma multi_compile_instancing
		//#pragma instancing_options procedural:setupGPUI

		#pragma shader_feature_local_fragment __ _EMISSIONCOLORON _EMISSIONMAPON
		#pragma shader_feature_local_fragment __ _EMISSIONMASKON
		#pragma shader_feature_local_fragment __ _LIGHTCONTROLON

		#pragma shader_feature_local_fragment __ _WALLON
		#pragma shader_feature_local_fragment __ _FLOORON

		#pragma shader_feature_local_fragment __ _ALPHATESTON
		#pragma shader_feature_local_fragment __ _ALBEDOON

		CBUFFER_START(UnityPerMaterial)
		half _ScanLightIntensity;


		CBUFFER_END

		ENDHLSL

		/*ase_pass*/
		Pass
		{
			/*ase_main_pass*/
			Name "Forward"
			Tags { "LightMode" = "UniversalForward" }

			Blend One Zero
			ZWrite On
			ZTest LEqual
			Offset 0,0
			ColorMask RGBA

			/*ase_stencil*/

			HLSLPROGRAM

			#pragma vertex vert
			#pragma fragment frag

			#define SHADERPASS SHADERPASS_FORWARD

            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADEf
            #pragma multi_compile _ _SHADOWS_SOFT

            #pragma shader_feature_local_fragment __ _NORMALON
            #pragma shader_feature_local_fragment __ _MRAMON
            #pragma shader_feature_local_fragment __ _MRARON
            #pragma shader_feature_local_fragment __ _MRAAON

            #pragma shader_feature_local_fragment __ _UPBLENDMAPON
            #pragma shader_feature_local_fragment __ _UPBLENDCOLORON
            #pragma shader_feature_local_fragment __ _PARALLAXON
            #pragma shader_feature_local_fragment __ _HEIGHTBLENDON
            #pragma shader_feature_local_fragment __ _TERRAINBLENDON


			/*ase_pragma*/

            struct Attributes//这就是a2v
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varings//这就是v2f
            {
                float4 positionCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 positionWS : TEXCOORD1;
                float3 normal_dir : TEXCOORD2;
                float3 tangent_dir : TEXCOORD3;
                float3 binormal_dir : TEXCOORD4;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

			CBUFFER_START(UnityPerMaterial)

			CBUFFER_END

			/*ase_globals*/

			/*ase_funcs*/

            Varings vert(Attributes IN /*ase_vert_input*/)
            {
                Varings OUT;
                UNITY_SETUP_INSTANCE_ID(IN);
                UNITY_TRANSFER_INSTANCE_ID(IN, OUT);

				/*ase_vert_code:IN=VertexInput;OUT=VertexOutput*/

                VertexPositionInputs positionInputs = GetVertexPositionInputs(IN.positionOS.xyz);
                OUT.positionCS = positionInputs.positionCS;
                OUT.positionWS = positionInputs.positionWS.xyz;

                VertexNormalInputs normalInputs = GetVertexNormalInputs(IN.normal, IN.tangent);

                OUT.uv = IN.uv;

                //构建TBN矩阵元素
                OUT.binormal_dir = normalInputs.bitangentWS;
                OUT.normal_dir = normalInputs.normalWS;
                OUT.tangent_dir = normalInputs.tangentWS;

                return OUT;
            }
			half4 frag ( Varings IN
						/*ase_frag_input*/ ) : SV_Target
			{
				UNITY_SETUP_INSTANCE_ID(IN);


				/*ase_local_var:wn*/half3 normal_dir = SafeNormalize( IN.normal_dir );
				/*ase_local_var:wt*/half3 tangent_dir = SafeNormalize( IN.tangent_dir );
				/*ase_local_var:wbt*/half3 binormal_dir = SafeNormalize( IN.binormal_dir );
			    float3x3 TBN = float3x3(tangent_dir, binormal_dir, normal_dir);
				/*ase_local_var:wp*/float3 WorldPosition = IN.positionWS;
				/*ase_local_var:wvd*/half3 view_dir = normalize(_WorldSpaceCameraPos.xyz  - IN.positionWS);
				half3 light_dir = normalize(_MainLightPosition).xyz;
				/*ase_local_var:sc*/float4 ShadowCoords = float4( 0, 0, 0, 0 );


				/*ase_frag_code:IN=VertexOutput*/

				float3 BaseColor = /*ase_frag_out:Base Color;Float3;0;-1;_BaseColor*/float3(0.5, 0.5, 0.5)/*end*/;
				float3 Normal = /*ase_frag_out:Normal;Float3;1;-1;_FragNormal*/float3(0, 0, 1)/*end*/;
				float3 Emission = /*ase_frag_out:Emission;Float3;2;-1;_Emission*/0/*end*/;
				// float3 Specular = /*ase_frag_out:Specular;Float3;9;-1;_Specular*/0.5/*end*/;
				float Metallic = /*ase_frag_out:Metallic;Float;3;-1;_Metallic*/0/*end*/;
				float Smoothness = /*ase_frag_out:Smoothness;Float;4;-1;_Smoothness*/0.5/*end*/;
				float Occlusion = /*ase_frag_out:Occlusion;Float;5;-1;_Occlusion*/1/*end*/;
				float Alpha = /*ase_frag_out:Alpha;Float;6;-1;_Alpha*/1/*end*/;
				float AlphaClipThreshold = /*ase_frag_out:Alpha Clip Threshold;Float;7;-1;_AlphaClip*/0.5/*end*/;
				float AlphaClipThresholdShadow = /*ase_frag_out:Alpha Clip Threshold Shadow;Float;16;-1;_AlphaClipShadow*/0.5/*end*/;

				#ifdef _ALPHATEST_ON
					clip(Alpha - AlphaClipThreshold);
				#endif

				// InputData inputData;
				// inputData.positionWS = WorldPosition;
				// inputData.viewDirectionWS = WorldViewDirection;
				// inputData.shadowCoord = ShadowCoords;

				#ifdef _NORMALMAP
						#if _NORMAL_DROPOFF_TS
							normal_dir = TransformTangentToWorld(Normal, TBN);
						#elif _NORMAL_DROPOFF_OS
							normal_dir = TransformObjectToWorldNormal(Normal);
						#elif _NORMAL_DROPOFF_WS
							normal_dir = Normal;
						#endif
					normal_dir = NormalizeNormalPerPixel(inputData.normalWS);
				#else
					normal_dir = normal_dir; 
				#endif
 
				half roughness = 1 - Smoothness;

				PBRInputData inputData;
                InitializePBRInputData(IN.positionWS, normal_dir, view_dir, light_dir, inputData);

				half4 final_color = PBR(inputData, BaseColor, Metallic, roughness, Occlusion, Alpha);

				//扫光
                AddScanLightEffect(IN.positionWS, _ScanLightIntensity, final_color.rgb);


				//雾效
                AddFogEffect(inputData, final_color.rgb);

				return saturate(half4(final_color.rgb, 1));
			}

			ENDHLSL
		}

		///*ase_pass*/
		//Pass
		//{
		//	Name "ShadowCaster"
		//	Tags { "LightMode" = "ShadowCaster" }
		//	Cull Back

		//	HLSLPROGRAM
		//	#pragma vertex vert
		//	#pragma fragment frag
		//	// #pragma multi_compile_instancing
		//	// #pragma instancing_options procedural:setup
		//	// void setup()
		//	// {
		//	//     #if defined(UNITY_PROCEDURAL_INSTANCING_ENABLED)
		//	//         unity_ObjectToWorld = positionBuffer[unity_InstanceID];
		//	//         unity_WorldToObject = Inverse(unity_ObjectToWorld);
		//	//     #endif
		//	// }
		//	#pragma target 4.5
		//	float3 _LightDirection;

		//	ShadowCasterV2F vert(ShadowCasterA2V v)
		//	{
		//		ShadowCasterV2F o = (ShadowCasterV2F)0;
		//		UNITY_SETUP_INSTANCE_ID(v);
		//		UNITY_TRANSFER_INSTANCE_ID(v, o);

		//		float3 worldPos = TransformObjectToWorld(v.vertex.xyz);
		//		half3 normalWS = TransformObjectToWorldNormal(v.normal);
		//		worldPos = ApplyShadowBias(worldPos, normalWS, _LightDirection);
		//		o.vertex = TransformWorldToHClip(worldPos);
		//		// jave.lin : 参考 cat like coding 博主的处理方式
		//		#if UNITY_REVERSED_Z
		//			o.vertex.z = min(o.vertex.z, o.vertex.w * UNITY_NEAR_CLIP_VALUE);
		//		#else
		//			o.vertex.z = max(o.vertex.z, o.vertex.w * UNITY_NEAR_CLIP_VALUE);
		//		#endif
		//		o.uv = v.uv;
		//		return o;
		//	}
		//	real4 frag(ShadowCasterV2F i) : SV_Target
		//	{
		//		UNITY_SETUP_INSTANCE_ID(i);
		//		#if _ALPHATESTON
		//			half albedo_alpha = SAMPLE_TEXTURE2D(_AlbedoMap, sampler_AlbedoMap, i.uv).a;
		//			clip(albedo_alpha - _AlphaClip);
		//		#endif
		//		return 0;
		//	}
		//	ENDHLSL
		//}

		///*ase_pass*/
		//Pass
		//{
		//	Name "DepthOnly"
		//	Tags { "LightMode" = "DepthOnly" }
		//	Cull Back
		//	ZWrite On
		//	ColorMask 0

		//	HLSLPROGRAM
		//	#pragma target 2.0

		//	#pragma vertex DepthOnlyVertex
		//	#pragma fragment DepthOnlyFragment

		//	#pragma target 4.5

		//	DepthOnlyV2F DepthOnlyVertex(DepthOnlyA2V input)
		//	{
		//		DepthOnlyV2F output = (DepthOnlyV2F)0;
		//		UNITY_SETUP_INSTANCE_ID(input);
		//		UNITY_TRANSFER_INSTANCE_ID(input, output);
		//		output.uv = input.texcoord;
		//		output.positionCS = TransformObjectToHClip(input.position.xyz);
		//		return output;
		//	}

		//	half4 DepthOnlyFragment(DepthOnlyV2F input) : SV_TARGET
		//	{
		//		UNITY_SETUP_INSTANCE_ID(input);
		//		#if _ALPHATESTON
		//			input.uv = input.uv * _AlbedoMap_ST.xy + _AlbedoMap_ST.zw;
		//			half albedo_alpha = SAMPLE_TEXTURE2D(_AlbedoMap, sampler_AlbedoMap, input.uv).a;
		//			clip(albedo_alpha - _AlphaClip);
		//		#endif
		//		return 0;
		//	}
		//	ENDHLSL
		//}


		/*ase_pass_end*/
	}
	/*ase_lod*/
	CustomEditor "UnityEditor.ShaderGraph.PBRMasterGUI"
	FallBack "Hidden/InternalErrorShader"
}

// Made with Amplify Shader Editor v1.9.1.5
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "ASERainRipple"
{
	Properties
	{
		[HideInInspector] _EmissionColor("Emission Color", Color) = (1,1,1,1)
		[HideInInspector] _AlphaCutoff("Alpha Cutoff ", Range(0, 1)) = 0.5
		[ASEBegin]_FogUV_YScale("FogUV_YScale", Float) = 0.5
		_Noise("Noise", 2D) = "white" {}
		_Rain("Rain", 2D) = "white" {}
		_Ripple("Ripple", 2D) = "white" {}
		_RainSpeed("RainSpeed", Range( 0 , 10)) = 1
		_RainSpeed2("RainSpeed2", Range( 0 , 10)) = 0.9
		_Float6("Float 6", Range( 0 , 1)) = 0.01
		_RainPower1("RainPower1", Float) = 0
		_RainPower2("RainPower2", Float) = 0
		_RainStrength("RainStrength", Range( 0 , 2)) = 0
		_RippleSpeed("RippleSpeed", Float) = 0
		_CameraForward("CameraForward", Vector) = (0,0,0,0)
		_CameraForward_Y_Bias2("CameraForward_Y_Bias2", Range( 0.5 , 2)) = 0.5
		_CameraForward_Y_Bias("CameraForward_Y_Bias", Range( 0.5 , 2)) = 0.5
		_RotataBy_V2("RotataBy_V2", Range( -3 , 3)) = 0.5
		_RotataBy_V("RotataBy_V", Range( -3 , 3)) = 0.5
		_Rain1_Tiling("Rain1_Tiling", Vector) = (0,0,0,0)
		_Float13("Float 13", Float) = 3.35
		_Float132("Float 132", Float) = 3.35
		_Rain2_Tiling("Rain2_Tiling", Vector) = (0,0,0,0)
		_RippleDepth("RippleDepth", Range( 0 , 0.85)) = 0
		_MoveSpeed("MoveSpeed", Range( 0.01 , 0.99)) = 0
		_RippleUVScale("RippleUVScale", Range( 0 , 1)) = 0
		_RippleYMin("RippleYMin", Range( 0 , 1)) = 0
		[ASEEnd]_RippleYMax("RippleYMax", Range( 0 , 1)) = 0
		[HideInInspector] _texcoord( "", 2D ) = "white" {}


		//_TessPhongStrength( "Tess Phong Strength", Range( 0, 1 ) ) = 0.5
		//_TessValue( "Tess Max Tessellation", Range( 1, 32 ) ) = 16
		//_TessMin( "Tess Min Distance", Float ) = 10
		//_TessMax( "Tess Max Distance", Float ) = 25
		//_TessEdgeLength ( "Tess Edge length", Range( 2, 50 ) ) = 16
		//_TessMaxDisp( "Tess Max Displacement", Float ) = 25
	}

	SubShader
	{
		LOD 0

		

		Tags { "RenderPipeline"="UniversalPipeline" "RenderType"="Transparent" "Queue"="Transparent" }

		Cull Back
		AlphaToMask Off

		

		HLSLINCLUDE
		#pragma target 3.5
		#pragma prefer_hlslcc gles
		// ensure rendering platforms toggle list is visible

		#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
		#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Filtering.hlsl"

		#ifndef ASE_TESS_FUNCS
		#define ASE_TESS_FUNCS
		float4 FixedTess( float tessValue )
		{
			return tessValue;
		}

		float CalcDistanceTessFactor (float4 vertex, float minDist, float maxDist, float tess, float4x4 o2w, float3 cameraPos )
		{
			float3 wpos = mul(o2w,vertex).xyz;
			float dist = distance (wpos, cameraPos);
			float f = clamp(1.0 - (dist - minDist) / (maxDist - minDist), 0.01, 1.0) * tess;
			return f;
		}

		float4 CalcTriEdgeTessFactors (float3 triVertexFactors)
		{
			float4 tess;
			tess.x = 0.5 * (triVertexFactors.y + triVertexFactors.z);
			tess.y = 0.5 * (triVertexFactors.x + triVertexFactors.z);
			tess.z = 0.5 * (triVertexFactors.x + triVertexFactors.y);
			tess.w = (triVertexFactors.x + triVertexFactors.y + triVertexFactors.z) / 3.0f;
			return tess;
		}

		float CalcEdgeTessFactor (float3 wpos0, float3 wpos1, float edgeLen, float3 cameraPos, float4 scParams )
		{
			float dist = distance (0.5 * (wpos0+wpos1), cameraPos);
			float len = distance(wpos0, wpos1);
			float f = max(len * scParams.y / (edgeLen * dist), 1.0);
			return f;
		}

		float DistanceFromPlane (float3 pos, float4 plane)
		{
			float d = dot (float4(pos,1.0f), plane);
			return d;
		}

		bool WorldViewFrustumCull (float3 wpos0, float3 wpos1, float3 wpos2, float cullEps, float4 planes[6] )
		{
			float4 planeTest;
			planeTest.x = (( DistanceFromPlane(wpos0, planes[0]) > -cullEps) ? 1.0f : 0.0f ) +
						  (( DistanceFromPlane(wpos1, planes[0]) > -cullEps) ? 1.0f : 0.0f ) +
						  (( DistanceFromPlane(wpos2, planes[0]) > -cullEps) ? 1.0f : 0.0f );
			planeTest.y = (( DistanceFromPlane(wpos0, planes[1]) > -cullEps) ? 1.0f : 0.0f ) +
						  (( DistanceFromPlane(wpos1, planes[1]) > -cullEps) ? 1.0f : 0.0f ) +
						  (( DistanceFromPlane(wpos2, planes[1]) > -cullEps) ? 1.0f : 0.0f );
			planeTest.z = (( DistanceFromPlane(wpos0, planes[2]) > -cullEps) ? 1.0f : 0.0f ) +
						  (( DistanceFromPlane(wpos1, planes[2]) > -cullEps) ? 1.0f : 0.0f ) +
						  (( DistanceFromPlane(wpos2, planes[2]) > -cullEps) ? 1.0f : 0.0f );
			planeTest.w = (( DistanceFromPlane(wpos0, planes[3]) > -cullEps) ? 1.0f : 0.0f ) +
						  (( DistanceFromPlane(wpos1, planes[3]) > -cullEps) ? 1.0f : 0.0f ) +
						  (( DistanceFromPlane(wpos2, planes[3]) > -cullEps) ? 1.0f : 0.0f );
			return !all (planeTest);
		}

		float4 DistanceBasedTess( float4 v0, float4 v1, float4 v2, float tess, float minDist, float maxDist, float4x4 o2w, float3 cameraPos )
		{
			float3 f;
			f.x = CalcDistanceTessFactor (v0,minDist,maxDist,tess,o2w,cameraPos);
			f.y = CalcDistanceTessFactor (v1,minDist,maxDist,tess,o2w,cameraPos);
			f.z = CalcDistanceTessFactor (v2,minDist,maxDist,tess,o2w,cameraPos);

			return CalcTriEdgeTessFactors (f);
		}

		float4 EdgeLengthBasedTess( float4 v0, float4 v1, float4 v2, float edgeLength, float4x4 o2w, float3 cameraPos, float4 scParams )
		{
			float3 pos0 = mul(o2w,v0).xyz;
			float3 pos1 = mul(o2w,v1).xyz;
			float3 pos2 = mul(o2w,v2).xyz;
			float4 tess;
			tess.x = CalcEdgeTessFactor (pos1, pos2, edgeLength, cameraPos, scParams);
			tess.y = CalcEdgeTessFactor (pos2, pos0, edgeLength, cameraPos, scParams);
			tess.z = CalcEdgeTessFactor (pos0, pos1, edgeLength, cameraPos, scParams);
			tess.w = (tess.x + tess.y + tess.z) / 3.0f;
			return tess;
		}

		float4 EdgeLengthBasedTessCull( float4 v0, float4 v1, float4 v2, float edgeLength, float maxDisplacement, float4x4 o2w, float3 cameraPos, float4 scParams, float4 planes[6] )
		{
			float3 pos0 = mul(o2w,v0).xyz;
			float3 pos1 = mul(o2w,v1).xyz;
			float3 pos2 = mul(o2w,v2).xyz;
			float4 tess;

			if (WorldViewFrustumCull(pos0, pos1, pos2, maxDisplacement, planes))
			{
				tess = 0.0f;
			}
			else
			{
				tess.x = CalcEdgeTessFactor (pos1, pos2, edgeLength, cameraPos, scParams);
				tess.y = CalcEdgeTessFactor (pos2, pos0, edgeLength, cameraPos, scParams);
				tess.z = CalcEdgeTessFactor (pos0, pos1, edgeLength, cameraPos, scParams);
				tess.w = (tess.x + tess.y + tess.z) / 3.0f;
			}
			return tess;
		}
		#endif //ASE_TESS_FUNCS
		ENDHLSL

		
		Pass
		{
			
			Name "Forward"
			Tags { "LightMode"="UniversalForward" }

			Blend One One, One OneMinusSrcAlpha
			ZWrite Off
			ZTest LEqual
			Offset 0 , 0
			ColorMask RGBA

			Stencil
			{
				Ref 2
				Comp NotEqual
				Pass Keep
				Fail Keep
				ZFail Keep
			}

			HLSLPROGRAM

			#pragma multi_compile_instancing
			#define _SURFACE_TYPE_TRANSPARENT 1
			#define ASE_SRP_VERSION 100900
			#define REQUIRE_DEPTH_TEXTURE 1


			#pragma vertex vert
			#pragma fragment frag

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/UnityInstancing.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareNormalsTexture.hlsl"


			struct VertexInput
			{
				float4 vertex : POSITION;
				float3 ase_normal : NORMAL;
				float4 ase_texcoord : TEXCOORD0;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct VertexOutput
			{
				float4 clipPos : SV_POSITION;
				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
					float3 worldPos : TEXCOORD0;
				#endif
				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					float4 shadowCoord : TEXCOORD1;
				#endif
				#ifdef ASE_FOG
					float fogFactor : TEXCOORD2;
				#endif
				float4 ase_texcoord3 : TEXCOORD3;
				float4 ase_texcoord4 : TEXCOORD4;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
			float4 _Rain_ST;
			float4 _CameraForward;
			float4 _Ripple_ST;
			float4 _MainTex_ST;
			float2 _Rain1_Tiling;
			float2 _Rain2_Tiling;
			float _RippleDepth;
			float _RippleUVScale;
			float _FogUV_YScale;
			float _RippleSpeed;
			float _RainStrength;
			float _RainPower2;
			float _Float132;
			float _RotataBy_V2;
			float _RippleYMin;
			float _RainSpeed2;
			float _Float6;
			float _RainPower1;
			float _Float13;
			float _CameraForward_Y_Bias;
			float _RotataBy_V;
			float _RainSpeed;
			float _MoveSpeed;
			float _CameraForward_Y_Bias2;
			float _RippleYMax;
			#ifdef ASE_TESSELLATION
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END

			sampler2D _Noise;
			sampler2D _Rain;
			sampler2D _MainTex;
			sampler2D _Ripple;
			uniform float4 _CameraDepthTexture_TexelSize;


			float2 UnStereo( float2 UV )
			{
				#if UNITY_SINGLE_PASS_STEREO
				float4 scaleOffset = unity_StereoScaleOffset[ unity_StereoEyeIndex ];
				UV.xy = (UV.xy - scaleOffset.zw) / scaleOffset.xy;
				#endif
				return UV;
			}
			
			float3 InvertDepthDirURP75_g1( float3 In )
			{
				float3 result = In;
				#if !defined(ASE_SRP_VERSION) || ASE_SRP_VERSION <= 70301 || ASE_SRP_VERSION == 70503 || ASE_SRP_VERSION == 70600 || ASE_SRP_VERSION == 70700 || ASE_SRP_VERSION == 70701 || ASE_SRP_VERSION >= 80301
				result *= float3(1,1,-1);
				#endif
				return result;
			}
			
			float3 GetScreenNormalTex227( float2 uv )
			{
				 return SampleSceneNormals(uv);
			}
			

			VertexOutput VertexFunction ( VertexInput v  )
			{
				VertexOutput o = (VertexOutput)0;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				float4 ase_clipPos = TransformObjectToHClip((v.vertex).xyz);
				float4 screenPos = ComputeScreenPos(ase_clipPos);
				o.ase_texcoord4 = screenPos;
				
				o.ase_texcoord3.xy = v.ase_texcoord.xy;
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord3.zw = 0;

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.vertex.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif

				float3 vertexValue = defaultVertexValue;

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					v.vertex.xyz = vertexValue;
				#else
					v.vertex.xyz += vertexValue;
				#endif

				v.ase_normal = v.ase_normal;

				float3 positionWS = TransformObjectToWorld( v.vertex.xyz );
				float4 positionCS = TransformWorldToHClip( positionWS );

				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
					o.worldPos = positionWS;
				#endif

				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					VertexPositionInputs vertexInput = (VertexPositionInputs)0;
					vertexInput.positionWS = positionWS;
					vertexInput.positionCS = positionCS;
					o.shadowCoord = GetShadowCoord( vertexInput );
				#endif

				#ifdef ASE_FOG
					o.fogFactor = ComputeFogFactor( positionCS.z );
				#endif

				o.clipPos = positionCS;

				return o;
			}

			#if defined(ASE_TESSELLATION)
			struct VertexControl
			{
				float4 vertex : INTERNALTESSPOS;
				float3 ase_normal : NORMAL;
				float4 ase_texcoord : TEXCOORD0;

				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct TessellationFactors
			{
				float edge[3] : SV_TessFactor;
				float inside : SV_InsideTessFactor;
			};

			VertexControl vert ( VertexInput v )
			{
				VertexControl o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				o.vertex = v.vertex;
				o.ase_normal = v.ase_normal;
				o.ase_texcoord = v.ase_texcoord;
				return o;
			}

			TessellationFactors TessellationFunction (InputPatch<VertexControl,3> v)
			{
				TessellationFactors o;
				float4 tf = 1;
				float tessValue = _TessValue; float tessMin = _TessMin; float tessMax = _TessMax;
				float edgeLength = _TessEdgeLength; float tessMaxDisp = _TessMaxDisp;
				#if defined(ASE_FIXED_TESSELLATION)
				tf = FixedTess( tessValue );
				#elif defined(ASE_DISTANCE_TESSELLATION)
				tf = DistanceBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, tessValue, tessMin, tessMax, GetObjectToWorldMatrix(), _WorldSpaceCameraPos );
				#elif defined(ASE_LENGTH_TESSELLATION)
				tf = EdgeLengthBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams );
				#elif defined(ASE_LENGTH_CULL_TESSELLATION)
				tf = EdgeLengthBasedTessCull(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, tessMaxDisp, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams, unity_CameraWorldClipPlanes );
				#endif
				o.edge[0] = tf.x; o.edge[1] = tf.y; o.edge[2] = tf.z; o.inside = tf.w;
				return o;
			}

			[domain("tri")]
			[partitioning("fractional_odd")]
			[outputtopology("triangle_cw")]
			[patchconstantfunc("TessellationFunction")]
			[outputcontrolpoints(3)]
			VertexControl HullFunction(InputPatch<VertexControl, 3> patch, uint id : SV_OutputControlPointID)
			{
			   return patch[id];
			}

			[domain("tri")]
			VertexOutput DomainFunction(TessellationFactors factors, OutputPatch<VertexControl, 3> patch, float3 bary : SV_DomainLocation)
			{
				VertexInput o = (VertexInput) 0;
				o.vertex = patch[0].vertex * bary.x + patch[1].vertex * bary.y + patch[2].vertex * bary.z;
				o.ase_normal = patch[0].ase_normal * bary.x + patch[1].ase_normal * bary.y + patch[2].ase_normal * bary.z;
				o.ase_texcoord = patch[0].ase_texcoord * bary.x + patch[1].ase_texcoord * bary.y + patch[2].ase_texcoord * bary.z;
				#if defined(ASE_PHONG_TESSELLATION)
				float3 pp[3];
				for (int i = 0; i < 3; ++i)
					pp[i] = o.vertex.xyz - patch[i].ase_normal * (dot(o.vertex.xyz, patch[i].ase_normal) - dot(patch[i].vertex.xyz, patch[i].ase_normal));
				float phongStrength = _TessPhongStrength;
				o.vertex.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * o.vertex.xyz;
				#endif
				UNITY_TRANSFER_INSTANCE_ID(patch[0], o);
				return VertexFunction(o);
			}
			#else
			VertexOutput vert ( VertexInput v )
			{
				return VertexFunction( v );
			}
			#endif

			half4 frag ( VertexOutput IN  ) : SV_Target
			{
				UNITY_SETUP_INSTANCE_ID( IN );
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX( IN );

				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
					float3 WorldPosition = IN.worldPos;
				#endif

				float4 ShadowCoords = float4( 0, 0, 0, 0 );

				#if defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
						ShadowCoords = IN.shadowCoord;
					#elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
						ShadowCoords = TransformWorldToShadowCoord( WorldPosition );
					#endif
				#endif

				float2 texCoord89 = IN.ase_texcoord3.xy * _Rain1_Tiling + float2( 0,0 );
				float temp_output_370_0 = ( ( ( _WorldSpaceCameraPos.x * 0.5 ) + ( _WorldSpaceCameraPos.z * 0.5 ) ) * _MoveSpeed );
				float mulTime90 = _TimeParameters.x * 0.1;
				float2 appendResult92 = (float2(( texCoord89.x + temp_output_370_0 ) , ( texCoord89.y + ( mulTime90 * _RainSpeed ) )));
				float2 RainUV1182 = appendResult92;
				float2 break196 = RainUV1182;
				float2 uv_Rain = IN.ase_texcoord3.xy * _Rain_ST.xy + _Rain_ST.zw;
				float2 break184 = uv_Rain;
				float temp_output_213_0 = min( max( _CameraForward.y , -0.4 ) , 0.5 );
				float camForward_Y214 = temp_output_213_0;
				float Rain1UV_X195 = ( ( ( break184.x - ( _RotataBy_V + 1.57 ) ) * pow( ( break184.y + camForward_Y214 + _CameraForward_Y_Bias ) , ( camForward_Y214 + _Float13 ) ) ) * camForward_Y214 );
				float2 appendResult198 = (float2(( break196.x + Rain1UV_X195 ) , ( break196.y * 0.05 )));
				float4 temp_cast_0 = (_RainPower1).xxxx;
				float2 texCoord101 = IN.ase_texcoord3.xy * _Rain2_Tiling + float2( 0,0 );
				float mulTime103 = _TimeParameters.x * 0.1;
				float2 appendResult106 = (float2(( _Float6 + temp_output_370_0 + texCoord101.x ) , ( texCoord101.y + ( mulTime103 * _RainSpeed2 ) )));
				float2 RainUV2187 = appendResult106;
				float2 break203 = RainUV2187;
				float2 break319 = uv_Rain;
				float Rain2UV_X327 = ( ( ( break319.x - ( _RotataBy_V2 + 1.57 ) ) * pow( ( break319.y + camForward_Y214 + _CameraForward_Y_Bias2 ) , ( camForward_Y214 + _Float132 ) ) ) * 0.0 * camForward_Y214 );
				float2 appendResult208 = (float2(( break203.x + Rain2UV_X327 ) , ( break203.y * 0.05 )));
				float4 temp_cast_1 = (_RainPower2).xxxx;
				float2 uv_MainTex = IN.ase_texcoord3.xy * _MainTex_ST.xy + _MainTex_ST.zw;
				float RippleTime298 = ( _TimeParameters.x * _RippleSpeed );
				float RippleEmissive1127 = ( 1.0 - ( frac( RippleTime298 ) * 0.9 ) );
				float2 uv_Ripple = IN.ase_texcoord3.xy * _Ripple_ST.xy + _Ripple_ST.zw;
				float2 break242 = uv_Ripple;
				float camForward_Y_2252 = max( temp_output_213_0 , -0.1 );
				float RippleUV_X251 = ( ( ( break242.x - 1.13 ) * pow( ( break242.y + camForward_Y_2252 + 1.7 ) , ( camForward_Y_2252 + 1.13 ) ) ) * camForward_Y_2252 );
				float4 screenPos = IN.ase_texcoord4;
				float4 ase_screenPosNorm = screenPos / screenPos.w;
				ase_screenPosNorm.z = ( UNITY_NEAR_CLIP_VALUE >= 0 ) ? ase_screenPosNorm.z : ase_screenPosNorm.z * 0.5 + 0.5;
				float2 UV22_g3 = ase_screenPosNorm.xy;
				float2 localUnStereo22_g3 = UnStereo( UV22_g3 );
				float2 break64_g1 = localUnStereo22_g3;
				float clampDepth69_g1 = SHADERGRAPH_SAMPLE_SCENE_DEPTH( ase_screenPosNorm.xy );
				#ifdef UNITY_REVERSED_Z
				float staticSwitch38_g1 = ( 1.0 - clampDepth69_g1 );
				#else
				float staticSwitch38_g1 = clampDepth69_g1;
				#endif
				float3 appendResult39_g1 = (float3(break64_g1.x , break64_g1.y , staticSwitch38_g1));
				float4 appendResult42_g1 = (float4((appendResult39_g1*2.0 + -1.0) , 1.0));
				float4 temp_output_43_0_g1 = mul( unity_CameraInvProjection, appendResult42_g1 );
				float3 temp_output_46_0_g1 = ( (temp_output_43_0_g1).xyz / (temp_output_43_0_g1).w );
				float3 In75_g1 = temp_output_46_0_g1;
				float3 localInvertDepthDirURP75_g1 = InvertDepthDirURP75_g1( In75_g1 );
				float4 appendResult49_g1 = (float4(localInvertDepthDirURP75_g1 , 1.0));
				float4 WorldPos25 = mul( unity_CameraToWorld, appendResult49_g1 );
				float4 break27 = WorldPos25;
				float2 appendResult30 = (float2(break27.x , break27.z));
				float2 fogUV35 = ( appendResult30 + ( break27.y * _FogUV_YScale ) );
				float2 break379 = (fogUV35*( 1.0 - _RippleUVScale ) + 0.0);
				float2 appendResult240 = (float2(( RippleUV_X251 + break379.x ) , ( break379.y * 1.0 )));
				float RippleEmissive2128 = ( 1.0 - ( 0.9 * frac( ( RippleTime298 + 0.5 ) ) ) );
				float lerpResult147 = lerp( saturate( ( 1.0 - ( distance( ( RippleEmissive1127 - tex2D( _Ripple, appendResult240 ).r ) , 0.05 ) / 0.05 ) ) ) , saturate( ( 1.0 - ( distance( ( RippleEmissive2128 - tex2D( _Ripple, ( appendResult240 + 0.1 ) ).r ) , 0.05 ) / 0.05 ) ) ) , saturate( abs( sin( ( ( RippleTime298 * PI ) + ( PI * 0.5 ) ) ) ) ));
				float Ripple152 = lerpResult147;
				float clampDepth159 = SHADERGRAPH_SAMPLE_SCENE_DEPTH( ase_screenPosNorm.xy );
				float Depth160 = clampDepth159;
				float2 texCoord290 = IN.ase_texcoord3.xy * float2( 1,1 ) + float2( 0,0 );
				float smoothstepResult285 = smoothstep( _RippleDepth , 1.0 , ( 1.0 - texCoord290.y ));
				float2 appendResult229 = (float2(ase_screenPosNorm.x , ase_screenPosNorm.y));
				float2 uv227 = appendResult229;
				float3 localGetScreenNormalTex227 = GetScreenNormalTex227( uv227 );
				float3 World_ScreenNormal230 = localGetScreenNormalTex227;
				float smoothstepResult392 = smoothstep( _RippleYMin , _RippleYMax , World_ScreenNormal230.y);
				float4 Rain117 = ( ( ( pow( tex2D( _Rain, appendResult198 ) , temp_cast_0 ) + pow( tex2D( _Rain, appendResult208 ) , temp_cast_1 ) ) * _RainStrength ) + tex2D( _MainTex, uv_MainTex ) + ( ( Ripple152 * saturate( ( Depth160 * ( 2.0 * smoothstepResult285 ) ) ) ) * saturate( smoothstepResult392 ) ) );
				
				float3 BakedAlbedo = 0;
				float3 BakedEmission = 0;
				float3 Color = Rain117.rgb;
				float Alpha = 1;
				float AlphaClipThreshold = 0.5;
				float AlphaClipThresholdShadow = 0.5;

				#ifdef _ALPHATEST_ON
					clip( Alpha - AlphaClipThreshold );
				#endif

				#ifdef LOD_FADE_CROSSFADE
					LODDitheringTransition( IN.clipPos.xyz, unity_LODFade.x );
				#endif

				#ifdef ASE_FOG
					Color = MixFog( Color, IN.fogFactor );
				#endif

				return half4( Color, Alpha );
			}
			ENDHLSL
		}

		
		Pass
		{
			
			Name "ShadowCaster"
			Tags { "LightMode"="ShadowCaster" }

			ZWrite On
			ZTest LEqual
			AlphaToMask Off
			ColorMask 0

			HLSLPROGRAM

			#pragma multi_compile_instancing
			#define _SURFACE_TYPE_TRANSPARENT 1
			#define ASE_SRP_VERSION 100900


			#pragma vertex vert
			#pragma fragment frag

			

			#define SHADERPASS SHADERPASS_SHADOWCASTER

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareNormalsTexture.hlsl"


			struct VertexInput
			{
				float4 vertex : POSITION;
				float3 ase_normal : NORMAL;
				
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct VertexOutput
			{
				float4 clipPos : SV_POSITION;
				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
					float3 worldPos : TEXCOORD0;
				#endif
				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					float4 shadowCoord : TEXCOORD1;
				#endif
				
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
			float4 _Rain_ST;
			float4 _CameraForward;
			float4 _Ripple_ST;
			float4 _MainTex_ST;
			float2 _Rain1_Tiling;
			float2 _Rain2_Tiling;
			float _RippleDepth;
			float _RippleUVScale;
			float _FogUV_YScale;
			float _RippleSpeed;
			float _RainStrength;
			float _RainPower2;
			float _Float132;
			float _RotataBy_V2;
			float _RippleYMin;
			float _RainSpeed2;
			float _Float6;
			float _RainPower1;
			float _Float13;
			float _CameraForward_Y_Bias;
			float _RotataBy_V;
			float _RainSpeed;
			float _MoveSpeed;
			float _CameraForward_Y_Bias2;
			float _RippleYMax;
			#ifdef ASE_TESSELLATION
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END

			sampler2D _Noise;


			
			float3 _LightDirection;
			#if ASE_SRP_VERSION >= 110000
				float3 _LightPosition;
			#endif

			VertexOutput VertexFunction( VertexInput v )
			{
				VertexOutput o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO( o );

				

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.vertex.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif

				float3 vertexValue = defaultVertexValue;

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					v.vertex.xyz = vertexValue;
				#else
					v.vertex.xyz += vertexValue;
				#endif

				v.ase_normal = v.ase_normal;

				float3 positionWS = TransformObjectToWorld( v.vertex.xyz );

				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
					o.worldPos = positionWS;
				#endif

				float3 normalWS = TransformObjectToWorldDir( v.ase_normal );

				#if ASE_SRP_VERSION >= 110000
					#if _CASTING_PUNCTUAL_LIGHT_SHADOW
						float3 lightDirectionWS = normalize(_LightPosition - positionWS);
					#else
						float3 lightDirectionWS = _LightDirection;
					#endif

					float4 clipPos = TransformWorldToHClip(ApplyShadowBias(positionWS, normalWS, lightDirectionWS));

					#if UNITY_REVERSED_Z
						clipPos.z = min(clipPos.z, UNITY_NEAR_CLIP_VALUE);
					#else
						clipPos.z = max(clipPos.z, UNITY_NEAR_CLIP_VALUE);
					#endif
				#else
					float4 clipPos = TransformWorldToHClip( ApplyShadowBias( positionWS, normalWS, _LightDirection ) );

					#if UNITY_REVERSED_Z
						clipPos.z = min(clipPos.z, clipPos.w * UNITY_NEAR_CLIP_VALUE);
					#else
						clipPos.z = max(clipPos.z, clipPos.w * UNITY_NEAR_CLIP_VALUE);
					#endif
				#endif

				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					VertexPositionInputs vertexInput = (VertexPositionInputs)0;
					vertexInput.positionWS = positionWS;
					vertexInput.positionCS = clipPos;
					o.shadowCoord = GetShadowCoord( vertexInput );
				#endif

				o.clipPos = clipPos;

				return o;
			}

			#if defined(ASE_TESSELLATION)
			struct VertexControl
			{
				float4 vertex : INTERNALTESSPOS;
				float3 ase_normal : NORMAL;
				
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct TessellationFactors
			{
				float edge[3] : SV_TessFactor;
				float inside : SV_InsideTessFactor;
			};

			VertexControl vert ( VertexInput v )
			{
				VertexControl o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				o.vertex = v.vertex;
				o.ase_normal = v.ase_normal;
				
				return o;
			}

			TessellationFactors TessellationFunction (InputPatch<VertexControl,3> v)
			{
				TessellationFactors o;
				float4 tf = 1;
				float tessValue = _TessValue; float tessMin = _TessMin; float tessMax = _TessMax;
				float edgeLength = _TessEdgeLength; float tessMaxDisp = _TessMaxDisp;
				#if defined(ASE_FIXED_TESSELLATION)
				tf = FixedTess( tessValue );
				#elif defined(ASE_DISTANCE_TESSELLATION)
				tf = DistanceBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, tessValue, tessMin, tessMax, GetObjectToWorldMatrix(), _WorldSpaceCameraPos );
				#elif defined(ASE_LENGTH_TESSELLATION)
				tf = EdgeLengthBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams );
				#elif defined(ASE_LENGTH_CULL_TESSELLATION)
				tf = EdgeLengthBasedTessCull(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, tessMaxDisp, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams, unity_CameraWorldClipPlanes );
				#endif
				o.edge[0] = tf.x; o.edge[1] = tf.y; o.edge[2] = tf.z; o.inside = tf.w;
				return o;
			}

			[domain("tri")]
			[partitioning("fractional_odd")]
			[outputtopology("triangle_cw")]
			[patchconstantfunc("TessellationFunction")]
			[outputcontrolpoints(3)]
			VertexControl HullFunction(InputPatch<VertexControl, 3> patch, uint id : SV_OutputControlPointID)
			{
			   return patch[id];
			}

			[domain("tri")]
			VertexOutput DomainFunction(TessellationFactors factors, OutputPatch<VertexControl, 3> patch, float3 bary : SV_DomainLocation)
			{
				VertexInput o = (VertexInput) 0;
				o.vertex = patch[0].vertex * bary.x + patch[1].vertex * bary.y + patch[2].vertex * bary.z;
				o.ase_normal = patch[0].ase_normal * bary.x + patch[1].ase_normal * bary.y + patch[2].ase_normal * bary.z;
				
				#if defined(ASE_PHONG_TESSELLATION)
				float3 pp[3];
				for (int i = 0; i < 3; ++i)
					pp[i] = o.vertex.xyz - patch[i].ase_normal * (dot(o.vertex.xyz, patch[i].ase_normal) - dot(patch[i].vertex.xyz, patch[i].ase_normal));
				float phongStrength = _TessPhongStrength;
				o.vertex.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * o.vertex.xyz;
				#endif
				UNITY_TRANSFER_INSTANCE_ID(patch[0], o);
				return VertexFunction(o);
			}
			#else
			VertexOutput vert ( VertexInput v )
			{
				return VertexFunction( v );
			}
			#endif

			half4 frag(VertexOutput IN  ) : SV_TARGET
			{
				UNITY_SETUP_INSTANCE_ID( IN );
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX( IN );

				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
					float3 WorldPosition = IN.worldPos;
				#endif

				float4 ShadowCoords = float4( 0, 0, 0, 0 );

				#if defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
						ShadowCoords = IN.shadowCoord;
					#elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
						ShadowCoords = TransformWorldToShadowCoord( WorldPosition );
					#endif
				#endif

				

				float Alpha = 1;
				float AlphaClipThreshold = 0.5;
				float AlphaClipThresholdShadow = 0.5;

				#ifdef _ALPHATEST_ON
					#ifdef _ALPHATEST_SHADOW_ON
						clip(Alpha - AlphaClipThresholdShadow);
					#else
						clip(Alpha - AlphaClipThreshold);
					#endif
				#endif

				#ifdef LOD_FADE_CROSSFADE
					LODDitheringTransition( IN.clipPos.xyz, unity_LODFade.x );
				#endif
				return 0;
			}
			ENDHLSL
		}

	
	}
	
	CustomEditor "UnityEditor.ShaderGraph.PBRMasterGUI"
	Fallback "Hidden/InternalErrorShader"
	
}
/*ASEBEGIN
Version=19105
Node;AmplifyShaderEditor.CommentaryNode;215;88.95308,791.1439;Inherit;False;3133.504;2270.667;Comment;52;253;249;247;241;251;252;246;250;248;245;244;243;242;190;189;214;315;195;191;186;256;193;192;255;185;184;201;188;194;181;270;269;212;213;209;210;316;317;318;319;320;321;322;323;324;325;326;327;328;329;330;331;让UV受随相机X轴翻转影响;1,1,1,1;0;0
Node;AmplifyShaderEditor.ScreenDepthNode;4;-1611.194,-313.1652;Inherit;False;0;True;1;0;FLOAT4;0,0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ScreenPosInputsNode;5;-1906.194,-284.1652;Float;False;1;False;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.DynamicAppendNode;11;-1537.583,-49.06113;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;12;-1357.583,-44.06113;Inherit;False;Screen_UV;-1;True;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.LinearDepthNode;6;-1390.322,-306.1562;Inherit;False;0;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;7;-1155.093,-307.5175;Inherit;False;LineraEyeDepth;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.BreakToComponentsNode;27;-507.6425,86.87894;Inherit;False;FLOAT4;1;0;FLOAT4;0,0,0,0;False;16;FLOAT;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT;5;FLOAT;6;FLOAT;7;FLOAT;8;FLOAT;9;FLOAT;10;FLOAT;11;FLOAT;12;FLOAT;13;FLOAT;14;FLOAT;15
Node;AmplifyShaderEditor.DynamicAppendNode;30;-319.6425,45.87894;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleAddOpNode;28;-35.64246,65.87894;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.GetLocalVarNode;42;-471.9286,-2551.801;Inherit;False;35;fogUV;1;0;OBJECT;;False;1;FLOAT2;0
Node;AmplifyShaderEditor.BreakToComponentsNode;44;-237.259,-2543.751;Inherit;False;FLOAT2;1;0;FLOAT2;0,0;False;16;FLOAT;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT;5;FLOAT;6;FLOAT;7;FLOAT;8;FLOAT;9;FLOAT;10;FLOAT;11;FLOAT;12;FLOAT;13;FLOAT;14;FLOAT;15
Node;AmplifyShaderEditor.SimpleTimeNode;45;-517.4445,-2431.371;Inherit;False;1;0;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;47;-241.4446,-2405.371;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;48;-456.4445,-2320.371;Inherit;False;Property;_Float2;Float 2;7;0;Create;True;0;0;0;False;0;False;0.05;0.02;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;49;6.860283,-2586.908;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;50;323.2992,-2547.688;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.BreakToComponentsNode;54;-232.7802,-2198.988;Inherit;False;FLOAT2;1;0;FLOAT2;0,0;False;16;FLOAT;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT;5;FLOAT;6;FLOAT;7;FLOAT;8;FLOAT;9;FLOAT;10;FLOAT;11;FLOAT;12;FLOAT;13;FLOAT;14;FLOAT;15
Node;AmplifyShaderEditor.RangedFloatNode;57;-469.0482,-2001.179;Inherit;False;Property;_Float3;Float 3;5;0;Create;True;0;0;0;False;0;False;0.1;0.1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;56;-254.0484,-2086.179;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleTimeNode;55;-500.1481,-2100.48;Inherit;False;1;0;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;58;-19.48766,-2130.61;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;59;324.428,-2187.793;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.GetLocalVarNode;61;-429.3443,-1862.393;Inherit;False;35;fogUV;1;0;OBJECT;;False;1;FLOAT2;0
Node;AmplifyShaderEditor.BreakToComponentsNode;62;-194.6748,-1854.344;Inherit;False;FLOAT2;1;0;FLOAT2;0,0;False;16;FLOAT;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT;5;FLOAT;6;FLOAT;7;FLOAT;8;FLOAT;9;FLOAT;10;FLOAT;11;FLOAT;12;FLOAT;13;FLOAT;14;FLOAT;15
Node;AmplifyShaderEditor.DynamicAppendNode;67;362.5335,-1843.149;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;63;-425.9427,-1527.535;Inherit;False;Property;_Float4;Float 4;4;0;Create;True;0;0;0;False;0;False;0.3;0.3;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleTimeNode;65;-488.0427,-1699.836;Inherit;False;1;0;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;64;-193.9429,-1521.535;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;68;27.97174,-1884.421;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;71;32.41241,-1656.505;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;70;-385.0283,-1777.421;Inherit;False;Property;_Float5;Float 5;6;0;Create;True;0;0;0;False;0;False;0.05;0.05;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;69;-190.0283,-1739.421;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;60;577.4109,-1948.117;Inherit;True;Property;_TextureSample1;Texture Sample 0;1;0;Create;True;0;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Instance;36;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;79;1901.563,-2241.682;Float;False;False;-1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;13;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;ExtraPrePass;0;0;ExtraPrePass;5;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;3;True;12;all;0;False;True;1;1;False;;0;False;;0;1;False;;0;False;;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;True;True;True;True;0;False;;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;True;1;False;;True;3;False;;True;True;0;False;;0;False;;True;0;False;False;0;Hidden/InternalErrorShader;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;81;1901.563,-2241.682;Float;False;False;-1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;13;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;ShadowCaster;0;2;ShadowCaster;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;3;True;12;all;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;False;False;True;False;False;False;False;0;False;;False;False;False;False;False;False;False;False;False;True;1;False;;True;3;False;;False;True;1;LightMode=ShadowCaster;False;False;0;Hidden/InternalErrorShader;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;82;1901.563,-2241.682;Float;False;False;-1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;13;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;DepthOnly;0;3;DepthOnly;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;3;True;12;all;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;False;False;True;False;False;False;False;0;False;;False;False;False;False;False;False;False;False;False;True;1;False;;False;False;True;1;LightMode=DepthOnly;False;False;0;Hidden/InternalErrorShader;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;83;1901.563,-2241.682;Float;False;False;-1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;13;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;Meta;0;4;Meta;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;3;True;12;all;0;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;2;False;;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;LightMode=Meta;False;False;0;Hidden/InternalErrorShader;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.SamplerNode;36;549.8153,-2614.692;Inherit;True;Property;_Noise;Noise;2;0;Create;True;0;0;0;True;0;False;-1;None;51bc3100e58497e46bfe469fa7f19e7b;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SamplerNode;52;550.6357,-2301.73;Inherit;True;Property;_TextureSample0;Texture Sample 0;1;0;Create;True;0;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Instance;36;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;113;1710.079,-4240.841;Inherit;False;Property;_RainPower2;RainPower2;13;0;Create;True;0;0;0;False;0;False;0;3;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.FunctionNode;24;-1109.265,74.41838;Inherit;False;Reconstruct World Position From Depth;-1;;1;e7094bcbcc80eb140b2a3dbe6a861de8;0;0;1;FLOAT4;0
Node;AmplifyShaderEditor.OneMinusNode;157;1922.075,-241.5491;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ScreenPosInputsNode;156;1394.075,-401.5491;Float;False;0;False;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ScreenDepthNode;159;1655.075,-332.5491;Inherit;False;1;False;1;0;FLOAT4;0,0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;160;2132.49,-461.8956;Inherit;False;Depth;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.StaticSwitch;158;2113.075,-341.5491;Float;False;Property;_Keyword0;Keyword 0;3;0;Fetch;True;0;0;0;False;0;False;0;0;0;False;UNITY_REVERSED_Z;Toggle;2;Key0;Key1;Fetch;False;True;All;9;1;FLOAT;0;False;0;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;4;FLOAT;0;False;5;FLOAT;0;False;6;FLOAT;0;False;7;FLOAT;0;False;8;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;146;4935.897,-1846.758;Inherit;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.DistanceOpNode;141;4361.754,-1885.941;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;143;4166.754,-1817.941;Inherit;False;Constant;_Float9;Float 8;17;0;Create;True;0;0;0;False;0;False;0.05;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;142;4166.655,-1927.141;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.OneMinusNode;122;4116.935,-2877.073;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;175;3913.373,-2891.443;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.OneMinusNode;126;4139.173,-2685.429;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;172;3934.373,-2715.443;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;153;2248.354,-4070.348;Inherit;False;152;Ripple;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;155;2480.841,-4036.764;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;129;3611.309,-1916.611;Inherit;True;Property;_TextureSample3;Texture Sample 3;8;0;Create;True;0;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Instance;85;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.DynamicAppendNode;86;952.4672,-2433.145;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;115;2006.699,-4278.261;Inherit;False;Property;_RainStrength;RainStrength;14;0;Create;True;0;0;0;False;0;False;0;2;0;2;0;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;182;672.4982,-5114.99;Inherit;True;RainUV1;-1;True;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleAddOpNode;116;2639.348,-4277.469;Inherit;False;3;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleAddOpNode;102;199.155,-4504.646;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleTimeNode;103;-178.2474,-4480.438;Inherit;False;1;0;FLOAT;0.1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;104;40.55288,-4447.982;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;105;-273.8482,-4374.782;Inherit;False;Property;_RainSpeed2;RainSpeed2;10;0;Create;True;0;0;0;False;0;False;0.9;6.05;0;10;0;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;106;409.3131,-4584.579;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SamplerNode;99;1415.009,-4383.051;Inherit;True;Property;_TextureSample2;Texture Sample 2;3;0;Create;True;0;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Instance;84;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.BreakToComponentsNode;196;889.438,-5079.525;Inherit;False;FLOAT2;1;0;FLOAT2;0,0;False;16;FLOAT;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT;5;FLOAT;6;FLOAT;7;FLOAT;8;FLOAT;9;FLOAT;10;FLOAT;11;FLOAT;12;FLOAT;13;FLOAT;14;FLOAT;15
Node;AmplifyShaderEditor.DynamicAppendNode;198;1371.229,-4994.914;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.BreakToComponentsNode;203;866.6293,-4612.003;Inherit;False;FLOAT2;1;0;FLOAT2;0,0;False;16;FLOAT;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT;5;FLOAT;6;FLOAT;7;FLOAT;8;FLOAT;9;FLOAT;10;FLOAT;11;FLOAT;12;FLOAT;13;FLOAT;14;FLOAT;15
Node;AmplifyShaderEditor.PowerNode;110;1879.859,-4809.622;Inherit;True;False;2;0;COLOR;0,0,0,0;False;1;FLOAT;1;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;111;1667.038,-4498.871;Inherit;False;Property;_RainPower1;RainPower1;12;0;Create;True;0;0;0;False;0;False;0;2.93;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;25;-743.6425,71.87894;Inherit;False;WorldPos;-1;True;1;0;FLOAT4;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.DynamicAppendNode;208;1268.744,-4520.901;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleAddOpNode;202;1279.247,-5155.712;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;236;1598.282,-5060.669;Inherit;False;RippleUV;-1;True;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;210;430.666,1323.719;Inherit;False;Constant;_camForwardMax;camForwardMax;21;0;Create;True;0;0;0;False;0;False;0.5;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;209;316.713,1205.622;Inherit;False;Constant;_camForwardMin;camForwardMin;21;0;Create;True;0;0;0;False;0;False;-0.4;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMinOpNode;213;652.4455,1150.245;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMaxOpNode;212;518.1015,1102.603;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.OneMinusNode;145;4758.754,-1847.341;Inherit;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleDivideOpNode;144;4521.254,-1818.541;Inherit;True;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;128;4409.643,-2628.266;Inherit;True;RippleEmissive2;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;171;3720.373,-2754.443;Inherit;False;Constant;_Float11;Float 11;17;0;Create;True;0;0;0;False;0;False;0.9;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;265;3103.078,-2047.802;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;266;3147.395,-1906.679;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;267;2965.395,-1822.679;Inherit;False;Constant;_Float12;Float 12;25;0;Create;True;0;0;0;False;0;False;1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;161;1940.445,-3990.157;Inherit;True;160;Depth;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;281;2438.259,-3905.281;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;280;2218.259,-3876.281;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SmoothstepOpNode;285;2069.596,-3663.527;Inherit;True;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;288;2346.596,-3697.527;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;289;2160.596,-3748.527;Inherit;False;Constant;_Float20;Float 20;29;0;Create;True;0;0;0;False;0;False;2;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;290;1678.596,-3792.527;Inherit;False;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.OneMinusNode;291;1911.596,-3715.527;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;286;1745.596,-3622.527;Inherit;False;Property;_RippleDepth;RippleDepth;25;0;Create;True;0;0;0;False;0;False;0;0;0;0.85;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;287;1747.596,-3498.527;Inherit;False;Constant;_Max;Max;28;0;Create;True;0;0;0;False;0;False;1;1;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.Vector4Node;181;199.953,982.1866;Inherit;False;Property;_CameraForward;CameraForward;16;0;Create;True;0;0;0;True;0;False;0,0,0,0;0.9280459,-0.2079258,0.309027,0;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RegisterLocalVarNode;87;1118.324,-2403.236;Inherit;False;Noise;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;124;3286.115,-2527.772;Inherit;False;Constant;_Float7;Float 7;17;0;Create;True;0;0;0;False;0;False;0.5;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;240;3303.279,-2012.641;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleAddOpNode;293;3484.733,-1925.123;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;294;3351.733,-1837.123;Inherit;False;Constant;_Float19;Float 19;22;0;Create;True;0;0;0;False;0;False;0.1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.FractNode;125;3678.972,-2545.128;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.FractNode;297;3535.129,-2771.364;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;85;3567.805,-2231.426;Inherit;True;Property;_Ripple;Ripple;8;0;Create;True;0;0;0;True;0;False;-1;None;7289f7c0774867d468ee902cd6506820;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.OneMinusNode;138;4708,-2093;Inherit;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;120;2909.991,-2670.285;Inherit;False;Property;_RippleSpeed;RippleSpeed;15;0;Create;True;0;0;0;False;0;False;0;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleTimeNode;119;2859.991,-2812.285;Inherit;False;1;0;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;121;3082.735,-2745.872;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;298;3227.505,-2726.299;Inherit;False;RippleTime;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;139;4935.162,-2085.827;Inherit;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;135;4176,-2061;Inherit;False;Constant;_Float8;Float 8;17;0;Create;True;0;0;0;False;0;False;0.05;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.DistanceOpNode;134;4356.558,-2259.612;Inherit;True;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleDivideOpNode;137;4572,-2049;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;123;3499.153,-2572.128;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;127;4381.73,-2884.008;Inherit;True;RippleEmissive1;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;133;4143.303,-2295.189;Inherit;True;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;147;5264.608,-1986.899;Inherit;True;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.AbsOpNode;163;4795.634,-1534.127;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;150;4977.722,-1535.186;Inherit;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SinOpNode;168;4604.076,-1530.814;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;299;4352.924,-1560.384;Inherit;False;298;RippleTime;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;310;4551.048,-1433.386;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;312;4741.048,-1403.386;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;313;4562.048,-1316.386;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;314;4422.048,-1262.386;Inherit;False;Constant;_Float10;Float 10;22;0;Create;True;0;0;0;False;0;False;0.5;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;200;915.6276,-4850.205;Inherit;False;Constant;_Float15;Float 15;16;0;Create;True;0;0;0;False;0;False;0.05;0.05;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.PowerNode;112;1888.078,-4500.841;Inherit;True;False;2;0;COLOR;0,0,0,0;False;1;FLOAT;1;False;1;COLOR;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;152;5570.535,-1917.138;Inherit;False;Ripple;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;114;2378.911,-4478.66;Inherit;True;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.SamplerNode;1;1376.918,-4085.089;Inherit;True;Global;_MainTex;_MainTex;0;0;Create;False;0;0;0;True;0;False;-1;None;;True;0;False;black;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;80;3993.847,-4438.477;Float;False;True;-1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;13;ASERainRipple;2992e84f91cbeb14eab234972e07ea9d;True;Forward;0;1;Forward;8;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;True;True;False;2;False;;255;False;;255;False;;7;False;;1;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Transparent=RenderType;Queue=Transparent=Queue=0;True;3;True;12;all;0;False;True;1;1;False;;1;False;;1;1;False;;10;False;;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;True;True;True;True;0;False;;False;False;False;False;False;False;True;True;True;2;False;;255;False;;255;False;;6;False;;1;False;;1;False;;1;False;;0;False;;0;False;;0;False;;0;False;;False;True;2;False;;True;3;False;;True;True;0;False;;0;False;;True;1;LightMode=UniversalForward;False;False;2;Include;;False;;Native;False;0;0;;Include;Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareNormalsTexture.hlsl;False;;Custom;False;0;0;;Hidden/InternalErrorShader;0;0;Standard;22;Surface;1;638280261171752670;  Blend;2;638282045499630176;Two Sided;1;0;Cast Shadows;1;0;  Use Shadow Threshold;0;0;Receive Shadows;1;0;GPU Instancing;1;0;LOD CrossFade;0;0;Built-in Fog;0;0;DOTS Instancing;0;0;Meta Pass;0;0;Extra Pre Pass;0;0;Tessellation;0;0;  Phong;0;0;  Strength;0.5,False,;0;  Type;0;0;  Tess;16,False,;0;  Min;10,False,;0;  Max;25,False,;0;  Edge Length;16,False,;0;  Max Displacement;25,False,;0;Vertex Position,InvertActionOnDeselection;1;0;0;5;False;True;True;False;False;False;;False;0
Node;AmplifyShaderEditor.BreakToComponentsNode;242;1421.205,2326.183;Inherit;False;FLOAT2;1;0;FLOAT2;0,0;False;16;FLOAT;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT;5;FLOAT;6;FLOAT;7;FLOAT;8;FLOAT;9;FLOAT;10;FLOAT;11;FLOAT;12;FLOAT;13;FLOAT;14;FLOAT;15
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;243;2243.868,2522.253;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;244;2077.357,2425.653;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.PowerNode;245;1902.104,2454.123;Inherit;False;False;2;0;FLOAT;0;False;1;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;248;1565.323,2645.569;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;250;1590.278,2417.99;Inherit;False;3;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;246;1920.298,2230.124;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;252;1061.388,2516.325;Inherit;False;camForward_Y_2;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;251;2450.939,2452.161;Inherit;False;RippleUV_X;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;241;1368.491,2685.887;Inherit;False;Constant;_Float16;Float 16;16;1;[HideInInspector];Create;True;0;0;0;False;0;False;1.13;1.13;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;247;1729.397,2388.525;Inherit;False;Constant;_Float17;Float 17;20;1;[HideInInspector];Create;True;0;0;0;False;0;False;1.13;1.13;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;249;1388.184,2475.888;Inherit;False;Constant;_Float18;Float 18;18;1;[HideInInspector];Create;True;0;0;0;False;0;False;1.7;1.76;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;253;1172.278,2240.399;Inherit;False;0;85;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;194;2157.493,1188.789;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.PowerNode;188;1815.729,1120.659;Inherit;False;False;2;0;FLOAT;0;False;1;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;201;988.1802,885.8307;Inherit;False;0;84;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.BreakToComponentsNode;184;1268.831,929.7207;Inherit;False;FLOAT2;1;0;FLOAT2;0,0;False;16;FLOAT;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT;5;FLOAT;6;FLOAT;7;FLOAT;8;FLOAT;9;FLOAT;10;FLOAT;11;FLOAT;12;FLOAT;13;FLOAT;14;FLOAT;15
Node;AmplifyShaderEditor.SimpleAddOpNode;185;1460.905,987.5272;Inherit;False;3;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;255;1862.718,945.9286;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;1.57;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;192;1998.023,865.0623;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;193;1584.024,929.0627;Inherit;False;Property;_RotataBy_V;RotataBy_V;20;0;Create;True;0;0;0;False;0;False;0.5;0.17;-3;3;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;256;1660.718,1019.929;Inherit;False;Constant;_RotataBy_V_Bias;RotataBy_V_Bias;26;0;Create;True;0;0;0;False;0;False;1.57;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;186;1111.81,1101.424;Inherit;False;Property;_CameraForward_Y_Bias;CameraForward_Y_Bias;18;0;Create;True;0;0;0;False;0;False;0.5;0.5;0.5;2;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;191;2074.982,1070.19;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;195;2412.609,1098.333;Inherit;False;Rain1UV_X;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.WireNode;315;1486.029,868.1938;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;189;1439.948,1231.104;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;190;1202.117,1270.422;Inherit;False;Property;_Float13;Float 13;22;0;Create;True;0;0;0;False;0;False;3.35;1.13;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;316;2180.006,1697.502;Inherit;False;3;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.PowerNode;317;1838.242,1629.372;Inherit;False;False;2;0;FLOAT;0;False;1;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;318;1010.693,1394.544;Inherit;False;0;84;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.BreakToComponentsNode;319;1291.344,1438.434;Inherit;False;FLOAT2;1;0;FLOAT2;0,0;False;16;FLOAT;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT;5;FLOAT;6;FLOAT;7;FLOAT;8;FLOAT;9;FLOAT;10;FLOAT;11;FLOAT;12;FLOAT;13;FLOAT;14;FLOAT;15
Node;AmplifyShaderEditor.SimpleAddOpNode;320;1483.418,1496.24;Inherit;False;3;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;321;1885.231,1454.642;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;1.57;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;322;2020.537,1373.776;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;326;2097.495,1578.903;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.WireNode;328;1508.542,1376.907;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;329;1462.461,1739.817;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;214;789.9317,1150.227;Inherit;False;camForward_Y;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;331;876.142,1554.749;Inherit;False;214;camForward_Y;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;327;2435.122,1607.046;Inherit;False;Rain2UV_X;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;323;1606.537,1437.776;Inherit;False;Property;_RotataBy_V2;RotataBy_V2;19;0;Create;True;0;0;0;False;0;False;0.5;0;-3;3;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;324;1683.231,1528.642;Inherit;False;Constant;_RotataBy_V_Bias2;RotataBy_V_Bias2;26;0;Create;True;0;0;0;False;0;False;1.57;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;330;1224.63,1779.135;Inherit;False;Property;_Float132;Float 132;23;0;Create;True;0;0;0;False;0;False;3.35;1.13;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;187;578.9376,-4561.148;Inherit;False;RainUV2;-1;True;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;206;1106.936,-4455.4;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;207;998.593,-4609.875;Inherit;False;327;Rain2UV_X;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;325;1186,1568.125;Inherit;False;Property;_CameraForward_Y_Bias2;CameraForward_Y_Bias2;17;0;Create;True;0;0;0;False;0;False;0.5;1.312;0.5;2;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;109;2189.577,-4585.685;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.Vector2Node;218;-638.9396,-4639.491;Inherit;False;Property;_Rain2_Tiling;Rain2_Tiling;24;0;Create;True;0;0;0;False;0;False;0,0;3,0.48;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.TextureCoordinatesNode;101;-427.5474,-4660.399;Inherit;False;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ScreenPosInputsNode;339;-1765.338,4083.147;Float;False;0;False;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ComponentMaskNode;341;-85.33813,3907.147;Inherit;False;True;True;True;False;1;0;FLOAT4;0,0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.DynamicAppendNode;343;-805.3381,4003.147;Inherit;False;FLOAT3;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;1;False;1;FLOAT3;0
Node;AmplifyShaderEditor.ComponentMaskNode;344;-85.33813,4019.147;Inherit;False;False;False;False;True;1;0;FLOAT4;0,0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.BreakToComponentsNode;347;-1141.338,4003.147;Inherit;False;FLOAT2;1;0;FLOAT2;0,0;False;16;FLOAT;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT;5;FLOAT;6;FLOAT;7;FLOAT;8;FLOAT;9;FLOAT;10;FLOAT;11;FLOAT;12;FLOAT;13;FLOAT;14;FLOAT;15
Node;AmplifyShaderEditor.SimpleDivideOpNode;348;154.6619,3955.147;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.FunctionNode;350;-1445.338,4003.147;Inherit;False;Non Stereo Screen Pos;-1;;4;1731ee083b93c104880efc701e11b49b;0;1;23;FLOAT4;0,0,0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.ScaleAndOffsetNode;351;-645.3381,4003.147;Inherit;False;3;0;FLOAT3;0,0,0;False;1;FLOAT;2;False;2;FLOAT;-1;False;1;FLOAT3;0
Node;AmplifyShaderEditor.CameraProjectionNode;352;-533.3381,3907.147;Inherit;False;unity_CameraInvProjection;0;1;FLOAT4x4;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;353;-245.3381,3971.147;Inherit;False;2;2;0;FLOAT4x4;0,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1;False;1;FLOAT4;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.DynamicAppendNode;354;-421.3381,4003.147;Inherit;False;FLOAT4;4;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;1;False;1;FLOAT4;0
Node;AmplifyShaderEditor.CustomExpressionNode;357;355.0309,4024.278;Inherit;False;float3 result = In@$#if !defined(ASE_SRP_VERSION) || ASE_SRP_VERSION <= 70301 || ASE_SRP_VERSION == 70503 || ASE_SRP_VERSION == 70600 || ASE_SRP_VERSION == 70700 || ASE_SRP_VERSION == 70701 || ASE_SRP_VERSION >= 80301$result *= float3(1,1,-1)@$#endif$return result@;3;Create;1;True;In;FLOAT3;0,0,0;In;;Inherit;False;InvertDepthDirURP;True;False;0;;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.DynamicAppendNode;349;535.6111,4024.351;Inherit;False;FLOAT4;4;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;1;False;1;FLOAT4;0
Node;AmplifyShaderEditor.CameraToWorldMatrix;346;529.6111,3911.351;Inherit;False;0;1;FLOAT4x4;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;340;760.611,3976.351;Inherit;False;2;2;0;FLOAT4x4;0,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1;False;1;FLOAT4;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;359;983.8037,4005.702;Inherit;False;Screen_WorldPos;-1;True;1;0;FLOAT4;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.RangedFloatNode;360;-1487.675,4146.296;Inherit;False;Property;_Depth;Depth;26;0;Create;True;0;0;0;False;0;False;0;0;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.StaticSwitch;342;-1080.338,4180.147;Float;False;Property;_Keyword0;Keyword 0;3;0;Fetch;True;0;0;0;False;0;False;0;0;0;False;UNITY_REVERSED_Z;Toggle;2;Key0;Key1;Fetch;False;True;All;9;1;FLOAT;0;False;0;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;4;FLOAT;0;False;5;FLOAT;0;False;6;FLOAT;0;False;7;FLOAT;0;False;8;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ScreenDepthNode;358;-1551.338,4281.848;Inherit;False;1;False;1;0;FLOAT4;0,0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.OneMinusNode;345;-1217.838,4281.648;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;117;3022.31,-4266.226;Inherit;True;Rain;-1;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;361;3675.967,-4446.26;Inherit;False;362;FinalColor;1;0;OBJECT;;False;1;FLOAT4;0
Node;AmplifyShaderEditor.SimpleMaxOpNode;269;756.2468,1802.509;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;270;586.6412,1836.713;Inherit;False;Constant;_Float14;Float 14;21;0;Create;True;0;0;0;False;0;False;-0.1;-0.1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.Vector2Node;217;-795.6446,-5587.597;Inherit;False;Property;_Rain1_Tiling;Rain1_Tiling;21;0;Create;True;0;0;0;False;0;False;0,0;4.01,0.6;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.TextureCoordinatesNode;89;-543.7312,-5566.268;Inherit;False;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.WorldSpaceCameraPos;366;-487.1037,-5079.368;Inherit;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;367;-161.1048,-5057.78;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0.5;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;368;-159.1048,-4954.781;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0.5;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;369;49.89521,-5001.781;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;370;248.8954,-4987.782;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;91;134.6449,-5358.387;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleTimeNode;90;-242.7564,-5334.179;Inherit;False;1;0;FLOAT;0.1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;94;-23.95599,-5301.723;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;93;-338.3576,-5228.523;Inherit;False;Property;_RainSpeed;RainSpeed;9;0;Create;True;0;0;0;False;0;False;1;5.13;0;10;0;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;92;539.6956,-5238.997;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleAddOpNode;374;334.1742,-5139.483;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;108;-183.8252,-4696.656;Inherit;False;Property;_Float6;Float 6;11;0;Create;True;0;0;0;False;0;False;0.01;0.421;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;107;333.8452,-4680.759;Inherit;False;3;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;197;1079.11,-5026.736;Inherit;False;195;Rain1UV_X;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;204;1188.572,-4710.865;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;199;1139.518,-4920.323;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;84;1537.906,-4860.475;Inherit;True;Property;_Rain;Rain;3;0;Create;True;0;0;0;False;0;False;-1;47b6a1af8ee1e76468e69ede6a436482;d7a66bf6b3f787a438f6c4bccc8fe4a5;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.GetLocalVarNode;53;-467.4497,-2207.038;Inherit;False;35;fogUV;1;0;OBJECT;;False;1;FLOAT2;0
Node;AmplifyShaderEditor.GetLocalVarNode;239;2704.398,-2164.358;Inherit;False;251;RippleUV_X;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.BreakToComponentsNode;379;2768.601,-1997.305;Inherit;False;FLOAT2;1;0;FLOAT2;0,0;False;16;FLOAT;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT;5;FLOAT;6;FLOAT;7;FLOAT;8;FLOAT;9;FLOAT;10;FLOAT;11;FLOAT;12;FLOAT;13;FLOAT;14;FLOAT;15
Node;AmplifyShaderEditor.GetLocalVarNode;375;2148.601,-1914.305;Inherit;False;35;fogUV;1;0;OBJECT;;False;1;FLOAT2;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;131;2916.994,-2244.298;Inherit;False;0;85;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RegisterLocalVarNode;362;1342.534,3902.169;Inherit;False;FinalColor;-1;True;1;0;FLOAT4;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.PiNode;311;4334.048,-1420.386;Inherit;False;1;0;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.ScaleAndOffsetNode;377;2474.601,-1854.305;Inherit;False;3;0;FLOAT2;0,0;False;1;FLOAT;10;False;2;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.GetLocalVarNode;140;3937.754,-1942.941;Inherit;False;128;RippleEmissive2;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;132;3872.088,-2442.354;Inherit;True;127;RippleEmissive1;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.ScreenPosInputsNode;228;2601.023,-4947.182;Float;False;0;False;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.DynamicAppendNode;229;2821.023,-4897.182;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;230;3259.567,-4911.569;Inherit;False;World_ScreenNormal;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.CustomExpressionNode;227;2998.782,-4929.941;Inherit;False; return SampleSceneNormals(uv)@;3;Create;1;True;uv;FLOAT2;0,0;In;;Inherit;False;GetScreenNormalTex;True;False;0;;False;1;0;FLOAT2;0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.BreakToComponentsNode;234;2746.259,-3555.603;Inherit;False;FLOAT3;1;0;FLOAT3;0,0,0;False;16;FLOAT;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT;5;FLOAT;6;FLOAT;7;FLOAT;8;FLOAT;9;FLOAT;10;FLOAT;11;FLOAT;12;FLOAT;13;FLOAT;14;FLOAT;15
Node;AmplifyShaderEditor.GetLocalVarNode;231;2495.92,-3541.487;Inherit;False;230;World_ScreenNormal;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SaturateNode;384;3299.04,-3555.696;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;386;2614.04,-3405.696;Inherit;False;Property;_RippleYMin;RippleYMin;29;0;Create;True;0;0;0;False;0;False;0;0.4650793;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;388;2620.191,-3285.731;Inherit;False;Property;_RippleYMax;RippleYMax;30;0;Create;True;0;0;0;False;0;False;0;1;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;232;2822.259,-3916.603;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;371;-115.7278,-4839.854;Inherit;False;Property;_MoveSpeed;MoveSpeed;27;0;Create;True;0;0;0;False;0;False;0;0.034;0.01;0.99;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;381;2026.482,-1787.169;Inherit;False;Property;_RippleUVScale;RippleUVScale;28;0;Create;True;0;0;0;False;0;False;0;0.498;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.OneMinusNode;391;2290.736,-1774.315;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;35;259.5962,63.04657;Inherit;False;fogUV;-1;True;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;31;-172.6425,162.8789;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;32;-343.6425,263.8789;Inherit;False;Property;_FogUV_YScale;FogUV_YScale;1;0;Create;True;0;0;0;False;0;False;0.5;0.03;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SmoothstepOpNode;392;3190.032,-3460.234;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
WireConnection;4;0;5;0
WireConnection;11;0;5;1
WireConnection;11;1;5;2
WireConnection;12;0;11;0
WireConnection;6;0;4;0
WireConnection;7;0;6;0
WireConnection;27;0;25;0
WireConnection;30;0;27;0
WireConnection;30;1;27;2
WireConnection;28;0;30;0
WireConnection;28;1;31;0
WireConnection;44;0;42;0
WireConnection;47;0;45;0
WireConnection;47;1;48;0
WireConnection;49;0;44;0
WireConnection;49;1;47;0
WireConnection;50;0;49;0
WireConnection;50;1;44;1
WireConnection;54;0;53;0
WireConnection;56;0;55;0
WireConnection;56;1;57;0
WireConnection;58;0;54;1
WireConnection;58;1;56;0
WireConnection;59;0;54;0
WireConnection;59;1;58;0
WireConnection;62;0;61;0
WireConnection;67;0;68;0
WireConnection;67;1;71;0
WireConnection;64;0;65;0
WireConnection;64;1;63;0
WireConnection;68;0;62;0
WireConnection;68;1;69;0
WireConnection;71;0;62;1
WireConnection;71;1;64;0
WireConnection;69;0;65;0
WireConnection;69;1;70;0
WireConnection;60;1;67;0
WireConnection;36;1;50;0
WireConnection;52;1;59;0
WireConnection;157;0;159;0
WireConnection;159;0;156;0
WireConnection;160;0;159;0
WireConnection;158;1;159;0
WireConnection;158;0;157;0
WireConnection;146;0;145;0
WireConnection;141;0;142;0
WireConnection;141;1;143;0
WireConnection;142;0;140;0
WireConnection;142;1;129;1
WireConnection;122;0;175;0
WireConnection;175;0;297;0
WireConnection;175;1;171;0
WireConnection;126;0;172;0
WireConnection;172;0;171;0
WireConnection;172;1;125;0
WireConnection;155;0;153;0
WireConnection;155;1;281;0
WireConnection;129;1;293;0
WireConnection;86;0;36;1
WireConnection;182;0;92;0
WireConnection;116;0;114;0
WireConnection;116;1;1;0
WireConnection;116;2;232;0
WireConnection;102;0;101;2
WireConnection;102;1;104;0
WireConnection;104;0;103;0
WireConnection;104;1;105;0
WireConnection;106;0;107;0
WireConnection;106;1;102;0
WireConnection;99;1;208;0
WireConnection;196;0;182;0
WireConnection;198;0;202;0
WireConnection;198;1;199;0
WireConnection;203;0;187;0
WireConnection;110;0;84;0
WireConnection;110;1;111;0
WireConnection;25;0;24;0
WireConnection;208;0;204;0
WireConnection;208;1;206;0
WireConnection;202;0;196;0
WireConnection;202;1;197;0
WireConnection;236;0;198;0
WireConnection;213;0;212;0
WireConnection;213;1;210;0
WireConnection;212;0;181;2
WireConnection;212;1;209;0
WireConnection;145;0;144;0
WireConnection;144;0;141;0
WireConnection;144;1;143;0
WireConnection;128;0;126;0
WireConnection;265;0;239;0
WireConnection;265;1;379;0
WireConnection;266;0;379;1
WireConnection;266;1;267;0
WireConnection;281;0;280;0
WireConnection;280;0;161;0
WireConnection;280;1;288;0
WireConnection;285;0;291;0
WireConnection;285;1;286;0
WireConnection;285;2;287;0
WireConnection;288;0;289;0
WireConnection;288;1;285;0
WireConnection;291;0;290;2
WireConnection;87;0;36;1
WireConnection;240;0;265;0
WireConnection;240;1;266;0
WireConnection;293;0;240;0
WireConnection;293;1;294;0
WireConnection;125;0;123;0
WireConnection;297;0;298;0
WireConnection;85;1;240;0
WireConnection;138;0;137;0
WireConnection;121;0;119;0
WireConnection;121;1;120;0
WireConnection;298;0;121;0
WireConnection;139;0;138;0
WireConnection;134;0;133;0
WireConnection;134;1;135;0
WireConnection;137;0;134;0
WireConnection;137;1;135;0
WireConnection;123;0;298;0
WireConnection;123;1;124;0
WireConnection;127;0;122;0
WireConnection;133;0;132;0
WireConnection;133;1;85;1
WireConnection;147;0;139;0
WireConnection;147;1;146;0
WireConnection;147;2;150;0
WireConnection;163;0;168;0
WireConnection;150;0;163;0
WireConnection;168;0;312;0
WireConnection;310;0;299;0
WireConnection;310;1;311;0
WireConnection;312;0;310;0
WireConnection;312;1;313;0
WireConnection;313;0;311;0
WireConnection;313;1;314;0
WireConnection;112;0;99;0
WireConnection;112;1;113;0
WireConnection;152;0;147;0
WireConnection;114;0;109;0
WireConnection;114;1;115;0
WireConnection;80;2;117;0
WireConnection;242;0;253;0
WireConnection;243;0;244;0
WireConnection;243;1;252;0
WireConnection;244;0;246;0
WireConnection;244;1;245;0
WireConnection;245;0;250;0
WireConnection;245;1;248;0
WireConnection;248;0;252;0
WireConnection;248;1;241;0
WireConnection;250;0;242;1
WireConnection;250;1;252;0
WireConnection;250;2;249;0
WireConnection;246;0;242;0
WireConnection;246;1;247;0
WireConnection;252;0;269;0
WireConnection;251;0;243;0
WireConnection;194;0;191;0
WireConnection;194;1;214;0
WireConnection;188;0;185;0
WireConnection;188;1;189;0
WireConnection;184;0;201;0
WireConnection;185;0;184;1
WireConnection;185;1;214;0
WireConnection;185;2;186;0
WireConnection;255;0;193;0
WireConnection;255;1;256;0
WireConnection;192;0;315;0
WireConnection;192;1;255;0
WireConnection;191;0;192;0
WireConnection;191;1;188;0
WireConnection;195;0;194;0
WireConnection;315;0;184;0
WireConnection;189;0;214;0
WireConnection;189;1;190;0
WireConnection;316;0;326;0
WireConnection;316;2;331;0
WireConnection;317;0;320;0
WireConnection;317;1;329;0
WireConnection;319;0;318;0
WireConnection;320;0;319;1
WireConnection;320;1;331;0
WireConnection;320;2;325;0
WireConnection;321;0;323;0
WireConnection;321;1;324;0
WireConnection;322;0;328;0
WireConnection;322;1;321;0
WireConnection;326;0;322;0
WireConnection;326;1;317;0
WireConnection;328;0;319;0
WireConnection;329;0;331;0
WireConnection;329;1;330;0
WireConnection;214;0;213;0
WireConnection;327;0;316;0
WireConnection;187;0;106;0
WireConnection;206;0;203;1
WireConnection;206;1;200;0
WireConnection;109;0;110;0
WireConnection;109;1;112;0
WireConnection;101;0;218;0
WireConnection;341;0;353;0
WireConnection;343;0;347;0
WireConnection;343;1;347;1
WireConnection;343;2;342;0
WireConnection;344;0;353;0
WireConnection;347;0;350;0
WireConnection;348;0;341;0
WireConnection;348;1;344;0
WireConnection;350;23;339;0
WireConnection;351;0;343;0
WireConnection;353;0;352;0
WireConnection;353;1;354;0
WireConnection;354;0;351;0
WireConnection;357;0;348;0
WireConnection;349;0;357;0
WireConnection;340;0;346;0
WireConnection;340;1;349;0
WireConnection;359;0;340;0
WireConnection;342;1;360;0
WireConnection;342;0;345;0
WireConnection;358;0;339;0
WireConnection;345;0;360;0
WireConnection;117;0;116;0
WireConnection;269;0;213;0
WireConnection;269;1;270;0
WireConnection;89;0;217;0
WireConnection;367;0;366;1
WireConnection;368;0;366;3
WireConnection;369;0;367;0
WireConnection;369;1;368;0
WireConnection;370;0;369;0
WireConnection;370;1;371;0
WireConnection;91;0;89;2
WireConnection;91;1;94;0
WireConnection;94;0;90;0
WireConnection;94;1;93;0
WireConnection;92;0;374;0
WireConnection;92;1;91;0
WireConnection;374;0;89;1
WireConnection;374;1;370;0
WireConnection;107;0;108;0
WireConnection;107;1;370;0
WireConnection;107;2;101;1
WireConnection;204;0;203;0
WireConnection;204;1;207;0
WireConnection;199;0;196;1
WireConnection;199;1;200;0
WireConnection;84;1;198;0
WireConnection;379;0;377;0
WireConnection;362;0;359;0
WireConnection;377;0;375;0
WireConnection;377;1;391;0
WireConnection;229;0;228;1
WireConnection;229;1;228;2
WireConnection;230;0;227;0
WireConnection;227;0;229;0
WireConnection;234;0;231;0
WireConnection;384;0;392;0
WireConnection;232;0;155;0
WireConnection;232;1;384;0
WireConnection;391;0;381;0
WireConnection;35;0;28;0
WireConnection;31;0;27;1
WireConnection;31;1;32;0
WireConnection;392;0;234;1
WireConnection;392;1;386;0
WireConnection;392;2;388;0
ASEEND*/
//CHKSM=FFB27E6275FAA4F4F8CEBCC3C171D4D339113195
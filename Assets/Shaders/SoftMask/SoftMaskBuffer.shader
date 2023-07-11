Shader "UI/SoftMaskBuffer" {

	Properties
	{
		_SoftMaskTex("_SoftMaskTex", 2D) = "white" {}
	}

	SubShader {
		Tags {"Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent"}
		LOD 100
		
		Cull Off
		ZWrite Off
		Blend SrcAlpha One
		ColorMask [_ColorMask]

		Pass {  
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma target 2.0
			
			#include "UnityCG.cginc"

			struct appdata_t
			{
				float4 vertex   : POSITION;
				float2 texcoord : TEXCOORD0;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct v2f
			{
				float4 vertex   : SV_POSITION;
				float2 texcoord : TEXTCOORD0;
				UNITY_VERTEX_OUTPUT_STEREO
				float4 ase_texcoord3 : TEXCOORD1;
			};

			sampler2D _MainTex;
			sampler2D _SoftMaskTex;
			float _Softness;
			float _Alpha;

			v2f vert(appdata_t v)
			{
				v2f OUT;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(OUT);

				float4 ase_clipPos = UnityObjectToClipPos(v.vertex);
				float4 screenPos = ComputeScreenPos(ase_clipPos);
				OUT.ase_texcoord3 = screenPos;

				float4 vPosition = UnityObjectToClipPos(v.vertex);
				OUT.vertex = vPosition;
				OUT.texcoord = v.texcoord;

				return OUT;
			}

			fixed4 frag (v2f IN) : SV_Target
			{
				float4 screenPos = IN.ase_texcoord3;
				float4 ase_screenPosNorm = screenPos / screenPos.w;
				ase_screenPosNorm.z = (UNITY_NEAR_CLIP_VALUE >= 0) ? ase_screenPosNorm.z : ase_screenPosNorm.z * 0.5 + 0.5;
				float2 appendResult93 = (float2(ase_screenPosNorm.x , ase_screenPosNorm.y));

				half alpha_mask = tex2D(_SoftMaskTex, appendResult93).r;

				alpha_mask = saturate(alpha_mask);

			    half softness = max(_Softness, 0.0001f);
				
				return saturate(tex2D(_MainTex, IN.texcoord).a/softness) * _Alpha * alpha_mask;
			}
			ENDCG
		}
	}

}

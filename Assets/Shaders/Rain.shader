Shader "Hidden/RainRippleFX"
{
	Properties
	{
		_MainTex("Texture", 2D) = "white" {}
		_Rain("Rain", 2D) = "black" {}
		_Ripple("Ripple", 2D) = "black" {}
		_NoiseTex("Noise Tex", 2D) = "black"{}
		_RainForce("RainForce",Range(0,0.5)) = 0

	}
		SubShader
		{
			Cull Off ZWrite Off ZTest Always
			Fog { Mode Off } Blend Off

			Pass
			{
				CGPROGRAM
				#pragma vertex vert
				#pragma fragment frag
				#pragma target 3.0
				#pragma fragmentoption ARB_precision_hint_fastest

				#include "UnityCG.cginc"

				struct appdata
				{
					float4 vertex : POSITION;
					float2 uv : TEXCOORD0;

				};

				struct v2f
				{
					float4 frustumDir : TEXCOORD0;
					float2 uv : TEXCOORD1;
					float4 vertex : SV_POSITION;
				};

				sampler2D _MainTex, _NoiseTex;
				sampler2D _CameraDepthTexture, _Rain, _Ripple;
				float4x4 _FrustumDir;
				float3 _CameraForward;
				fixed _RainForce;

				v2f vert(appdata v)
				{
					v2f o;
					o.vertex = UnityObjectToClipPos(v.vertex);
					float2 uv = v.uv;

					int ix = (int)uv.x;
					int iy = (int)uv.y;
					o.frustumDir = _FrustumDir[ix + 2 * iy];

					o.uv = uv;

					return o;
				}

				fixed lum(fixed3 c)
				{
					return c.r * 0.2 + c.g * 0.7 + c.b * 0.1;
				}

				fixed4 frag(v2f i) : SV_Target
				{
					fixed4 col = tex2D(_MainTex, i.uv);

					float depth = UNITY_SAMPLE_DEPTH(tex2D(_CameraDepthTexture, i.uv));

					float linear01Depth = Linear01Depth(depth);
					float linearEyeDepth = LinearEyeDepth(depth);

					float3 worldPos = _WorldSpaceCameraPos + linearEyeDepth * i.frustumDir.xyz;
					float2 fogUV = (worldPos.xz + worldPos.y * 0.5) * 0.0025;
					fixed fogNoiseR = tex2D(_NoiseTex, float2(fogUV.x + _Time.x * 0.15, fogUV.y)).r;
					fixed fogNoiseG = tex2D(_NoiseTex, float2(fogUV.x , fogUV.y + _Time.x * 0.1)).g;
					fixed fogNoiseB = tex2D(_NoiseTex, float2(fogUV.x - _Time.x * 0.05, fogUV.y - _Time.x * 0.3)).b;

					fixed3 rippleNoise = tex2D(_Rain, worldPos.xz * 0.005 - _Time.y);
					fixed3 ripple = (1 - tex2D(_Ripple, worldPos.xz * ((fogNoiseR + fogNoiseG + fogNoiseB + rippleNoise * 0.3) * 0.1 + 0.7))) * step(linear01Depth, 0.99);
					ripple *= step(ripple.r, col.r * 0.6 + 0.5);
					ripple *= step(col.r * 0.6 + 0.3, ripple.r);

					ripple *= (rippleNoise.r * rippleNoise.g * rippleNoise.b);
					ripple *= (fogNoiseR + fogNoiseG) * fogNoiseB + 0.5;

					fixed2 rainUV = fixed2(i.uv.x , i.uv.y * 0.01 + _Time.x * 1.1);

					rainUV.y += i.uv.y * 0.001;
					rainUV.x += pow(i.uv.y + (_CameraForward.y + 0.5), _CameraForward.y + 1.15) * (rainUV.x - 0.5) * _CameraForward.y;
					fixed3 rain = tex2D(_Rain, rainUV);

					col.rgb += ripple * (1 - i.uv.y) * 0.8 * _RainForce * 2;
					col.rgb += saturate(rain.r - rain.g * (1 - _RainForce * 0.5) - rain.b * (1 - _RainForce * 0.5)) * 0.15 * (i.uv.y) * _RainForce * 2;

					return col;

				}
				ENDCG
			}
		}
}
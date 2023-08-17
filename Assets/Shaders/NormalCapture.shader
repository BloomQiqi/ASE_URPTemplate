Shader "Custom/NormalCapture" {
    SubShader{
        Pass {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            struct appdata_t {
                float4 vertex : POSITION;
            };

            struct v2f {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            v2f vert(appdata_t v) {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.vertex.xy * 0.5 + 0.5; // Transform vertex position to UV space
                return o;
            }

            sampler2D _CameraNormalsTexture;

            fixed4 frag(v2f i) : SV_Target {
                // Sample the normals texture using the UV coordinates
                fixed4 normals = tex2D(_CameraNormalsTexture, i.uv);
                return normals;
            }
            ENDCG
        }
    }
}

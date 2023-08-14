Shader "Unlit/SDFTutorial"
{
    Properties
    {
        _CenterColor("Center Color", Color) = (0.7,0.5,0.3,1)
        _EdgeColor("Edge Color", Color) = (0.3,0.4,0.4, 1)

        _Radius("Radius", Range(0, 0.5)) = 0.2
        _SmoothStepVec("SmoothStep Vec", Vector) = (0, 0.01, 0, 0)
    }
        SubShader
    {
        Tags { "RenderType" = "Opaque" }
        LOD 100

        Pass
        {
            HLSLINCLUDE

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attribute
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Varings
            {
                float4 positionCS : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            half4 _CenterColor;
            half4 _EdgeColor;
            half _Radius;
            float4 _SmoothStepVec;

            float circleSDF(float2 uv, float radius)
            {
                //由于使用uv作为pos，想对齐Plane mesh的中心，所以偏移0.5的坐标
                //减去半径（radius），大于0则在圆外，小于0则在圆内
                float result = length(uv - float2(0.5,0.5)) - radius;
                return result;
            }

            Varings vert(Attribute input)
            {
                Varings output;
                output.positionCS = TransformObjectToHClip(input.positionOS);
                output.uv = input.uv;
                return output;
            }

            half4 frag(Varings input) : SV_Target
            {
                float2 uv = input.uv;
                float sdf = circleSDF(uv, _Radius);
                sdf = smoothstep(_SmoothStepVec.x, _SmoothStepVec.y, sdf);
                sdf = 1 - sdf;
                return half4(sdf,sdf,sdf,1);
            }

            ENDHLSL

            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            ENDHLSL
        }
    }
}
// Made with Amplify Shader Editor v1.9.1.5
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "UI"
{
    Properties
    {
        [PerRendererData] _MainTex ("Sprite Texture", 2D) = "white" {}
        _Color ("Tint", Color) = (1,1,1,1)

        _StencilComp ("Stencil Comparison", Float) = 8
        _Stencil ("Stencil ID", Float) = 0
        _StencilOp ("Stencil Operation", Float) = 0
        _StencilWriteMask ("Stencil Write Mask", Float) = 255
        _StencilReadMask ("Stencil Read Mask", Float) = 255

        _ColorMask ("Color Mask", Float) = 15

        [Toggle(UNITY_UI_ALPHACLIP)] _UseUIAlphaClip ("Use Alpha Clip", Float) = 0

        
    }

    SubShader
    {
		LOD 0

        Tags { "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" "PreviewType"="Plane" "CanUseSpriteAtlas"="True" }

        Stencil
        {
        	Ref [_Stencil]
        	ReadMask [_StencilReadMask]
        	WriteMask [_StencilWriteMask]
        	Comp [_StencilComp]
        	Pass [_StencilOp]
        }


        Cull Off
        Lighting Off
        ZWrite Off
        ZTest [unity_GUIZTestMode]
        Blend One OneMinusSrcAlpha
        ColorMask [_ColorMask]

        
        Pass
        {
            Name "Default"
        CGPROGRAM
            
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 3.0

            #include "UnityCG.cginc"
            #include "UnityUI.cginc"

            #pragma multi_compile_local _ UNITY_UI_CLIP_RECT
            #pragma multi_compile_local _ UNITY_UI_ALPHACLIP

            struct appdata_t
            {
                float4 vertex   : POSITION;
                float4 color    : COLOR;
                float2 texcoord : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
                
            };

            struct v2f
            {
                float4 vertex   : SV_POSITION;
                fixed4 color    : COLOR;
                float2 texcoord  : TEXCOORD0;
                float4 worldPosition : TEXCOORD1;
                float4  mask : TEXCOORD2;
                UNITY_VERTEX_OUTPUT_STEREO
                
            };

            sampler2D _MainTex;
            fixed4 _Color;
            fixed4 _TextureSampleAdd;
            float4 _ClipRect;
            float4 _MainTex_ST;
            float _UIMaskSoftnessX;
            float _UIMaskSoftnessY;

            uniform float4 PivotPos;

            
            v2f vert(appdata_t v )
            {
                v2f OUT;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(OUT);

                

                v.vertex.xyz +=  float3( 0, 0, 0 ) ;

                float4 vPosition = UnityObjectToClipPos(v.vertex);
                OUT.worldPosition = v.vertex;
                OUT.vertex = vPosition;

                float2 pixelSize = vPosition.w;
                pixelSize /= float2(1, 1) * abs(mul((float2x2)UNITY_MATRIX_P, _ScreenParams.xy));

                float4 clampedRect = clamp(_ClipRect, -2e10, 2e10);
                float2 maskUV = (v.vertex.xy - clampedRect.xy) / (clampedRect.zw - clampedRect.xy);
                OUT.texcoord = v.texcoord;
                OUT.mask = float4(v.vertex.xy * 2 - clampedRect.xy - clampedRect.zw, 0.25 / (0.25 * half2(_UIMaskSoftnessX, _UIMaskSoftnessY) + abs(pixelSize.xy)));

                OUT.color = v.color * _Color;
                return OUT;
            }

            fixed4 frag(v2f IN ) : SV_Target
            {
                //Round up the alpha color coming from the interpolator (to 1.0/256.0 steps)
                //The incoming alpha could have numerical instability, which makes it very sensible to
                //HDR color transparency blend, when it blends with the world's texture.
                const half alphaPrecision = half(0xff);
                const half invAlphaPrecision = half(1.0/alphaPrecision);
                IN.color.a = round(IN.color.a * alphaPrecision)*invAlphaPrecision;

                float3 worldToObj83 = mul( unity_WorldToObject, float4( PivotPos.xyz, 1 ) ).xyz;
                float4 unityObjectToClipPos68 = UnityObjectToClipPos( worldToObj83 );
                float4 computeScreenPos71 = ComputeScreenPos( unityObjectToClipPos68 );
                computeScreenPos71 = computeScreenPos71 / computeScreenPos71.w;
                computeScreenPos71.z = ( UNITY_NEAR_CLIP_VALUE >= 0 ) ? computeScreenPos71.z : computeScreenPos71.z* 0.5 + 0.5;
                float4 break74 = computeScreenPos71;
                float2 appendResult88 = (float2(break74.x , break74.y));
                float2 CenPos_ScreenPos87 = appendResult88;
                

                half4 color = float4( CenPos_ScreenPos87, 0.0 , 0.0 );

                half alpha = 1;

                #ifdef UNITY_UI_CLIP_RECT
                half2 m = saturate((_ClipRect.zw - _ClipRect.xy - abs(IN.mask.xy)) * IN.mask.zw);
                color.a *= m.x * m.y;
                #endif

                #ifdef UNITY_UI_ALPHACLIP
                clip (color.a - 0.001);
                #endif

                color.rgb *= color.a;

                return color;
            }
        ENDCG
        }
    }
    CustomEditor "ASEMaterialInspector"
	
	Fallback Off
}
/*ASEBEGIN
Version=19105
Node;AmplifyShaderEditor.DynamicAppendNode;46;2043.354,-677.3005;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.GetLocalVarNode;44;1699.353,-555.3005;Inherit;False;63;WDH_RATIO;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.DistanceOpNode;47;2162.495,-575.713;Inherit;True;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleDivideOpNode;55;1877.86,-630.5978;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;56;2585.906,-711.3896;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.OneMinusNode;49;2390.528,-578.3748;Inherit;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SmoothstepOpNode;52;2970.549,-654.7409;Inherit;True;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;54;2616.497,-351.8766;Inherit;False;Property;_SMS_MAX;SMS_MAX;3;0;Create;True;0;0;0;False;0;False;1.18;0.948;0;2;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;53;2605.804,-458.2951;Inherit;False;Property;_SMS_MIN;SMS_MIN;2;0;Create;True;0;0;0;False;0;False;0.56;0.924;0;2;0;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;57;3232.124,-448.113;Inherit;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;65;3399.997,-710.0471;Inherit;False;Constant;_Color0;Color 0;4;0;Create;True;0;0;0;False;0;False;1,0,0,1;0,0,0,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;66;3573.078,-499.3732;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ScreenParams;61;690.37,-781.832;Inherit;False;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleDivideOpNode;62;913.37,-748.832;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;63;1076.37,-716.832;Inherit;False;WDH_RATIO;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;41;1571.353,-383.3005;Inherit;False;Property;_CirPos_Y;CirPos_Y;1;0;Create;True;0;0;0;False;0;False;0.6694314;0.494;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;48;1992.096,-452.113;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;40;1571.353,-473.3005;Inherit;False;Property;_CirPos_X;CirPos_X;0;0;Create;True;0;0;0;False;0;False;0.5616114;0.072;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;67;3764.078,-614.3732;Inherit;False;FLOAT4;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.WorldToCameraMatrix;79;892.3608,-1024.601;Inherit;False;0;1;FLOAT4x4;0
Node;AmplifyShaderEditor.UnityProjectorClipMatrixNode;80;902.3608,-922.6011;Inherit;False;0;1;FLOAT4x4;0
Node;AmplifyShaderEditor.ScreenParams;75;735.344,-1425.524;Inherit;False;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleDivideOpNode;77;1023.344,-1491.524;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleDivideOpNode;78;1021.344,-1345.524;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;76;1216.344,-1341.524;Inherit;False;FLOAT4;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.ScreenPosInputsNode;23;1399.762,-824.2038;Float;False;0;False;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RegisterLocalVarNode;85;767.5076,-1124.308;Inherit;False;CirCenPos;-1;True;1;0;FLOAT4;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.BreakToComponentsNode;74;1738.064,-843.7119;Inherit;False;FLOAT4;1;0;FLOAT4;0,0,0,0;False;16;FLOAT;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT;5;FLOAT;6;FLOAT;7;FLOAT;8;FLOAT;9;FLOAT;10;FLOAT;11;FLOAT;12;FLOAT;13;FLOAT;14;FLOAT;15
Node;AmplifyShaderEditor.DynamicAppendNode;88;1899.363,-885.2628;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.Vector4Node;72;409.438,-1242.423;Inherit;False;Global;PivotPos;PivotPos;4;0;Create;True;0;0;0;True;0;False;0,0,0,0;174.5281,895.4719,0,0;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RegisterLocalVarNode;87;2113.363,-935.2628;Inherit;True;CenPos_ScreenPos;-1;True;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.ComputeScreenPosHlpNode;71;1506.762,-959.2528;Inherit;False;True;1;0;FLOAT4;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.TransformPositionNode;83;972.3341,-1206.25;Inherit;False;World;Object;False;Fast;True;1;0;FLOAT3;0,0,0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.UnityObjToClipPosHlpNode;68;1207.538,-1085;Inherit;True;1;0;FLOAT3;0,0,0;False;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.GetLocalVarNode;89;3906.487,-731.0673;Inherit;False;87;CenPos_ScreenPos;1;0;OBJECT;;False;1;FLOAT2;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;0;4452.384,-690.5963;Float;False;True;-1;2;ASEMaterialInspector;0;3;UI;5056123faa0c79b47ab6ad7e8bf059a4;True;Default;0;0;Default;3;False;True;3;1;False;;10;False;;0;1;False;;0;False;;False;False;False;False;False;False;False;False;False;False;False;False;True;2;False;;False;True;True;True;True;True;0;True;_ColorMask;False;False;False;False;False;False;False;True;True;0;True;_Stencil;255;True;_StencilReadMask;255;True;_StencilWriteMask;0;True;_StencilComp;0;True;_StencilOp;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;True;2;False;;True;0;True;unity_GUIZTestMode;False;True;5;Queue=Transparent=Queue=0;IgnoreProjector=True;RenderType=Transparent=RenderType;PreviewType=Plane;CanUseSpriteAtlas=True;False;False;0;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;2;False;0;;0;0;Standard;0;0;1;True;False;;False;0
WireConnection;46;0;74;0
WireConnection;46;1;55;0
WireConnection;47;0;46;0
WireConnection;47;1;48;0
WireConnection;55;0;74;1
WireConnection;55;1;44;0
WireConnection;56;0;49;0
WireConnection;49;0;47;0
WireConnection;52;0;56;0
WireConnection;52;1;53;0
WireConnection;52;2;54;0
WireConnection;57;0;52;0
WireConnection;66;0;65;4
WireConnection;66;1;57;0
WireConnection;62;0;61;1
WireConnection;62;1;61;2
WireConnection;63;0;62;0
WireConnection;48;0;40;0
WireConnection;48;1;41;0
WireConnection;67;0;65;1
WireConnection;67;1;65;2
WireConnection;67;2;65;3
WireConnection;67;3;66;0
WireConnection;77;0;72;1
WireConnection;77;1;75;1
WireConnection;78;0;72;2
WireConnection;78;1;75;2
WireConnection;76;0;77;0
WireConnection;76;1;78;0
WireConnection;85;0;72;0
WireConnection;74;0;71;0
WireConnection;88;0;74;0
WireConnection;88;1;74;1
WireConnection;87;0;88;0
WireConnection;71;0;68;0
WireConnection;83;0;72;0
WireConnection;68;0;83;0
WireConnection;0;0;89;0
ASEEND*/
//CHKSM=57C0D4593B7E52E33FD8233C4ED66A60BE8645F5
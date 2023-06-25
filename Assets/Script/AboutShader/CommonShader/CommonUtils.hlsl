#include "HashLib.hlsl"

#ifndef COMMON_UTILS
#define COMMON_UTILS
#include "Assets/Script/AboutShader/CommonShader/PBRInput.hlsl"

half3 TriplanarNormalWS(half3 inputnormalWS)
{
    half3 absnormalWS = abs(inputnormalWS);
    absnormalWS = pow(absnormalWS, 2);
    absnormalWS = absnormalWS / (absnormalWS.x + absnormalWS.y + absnormalWS.z);
    return absnormalWS;
}

half3 CalculateAmbientLight(half3 normalWorld)
{
    //Flat ambient is just the sky color
    // half3 ambient = unity_AmbientSky.rgb * 0.75;

    //Magic constants used to tweak ambient to approximate pixel shader spherical harmonics
    half3 worldUp = half3(0, 1, 0);
    float skyGroundDotMul = 2.5;
    float minEquatorMix = 0.5;
    float equatorColorBlur = 0.33;
    
    float upDot = dot(normalWorld, worldUp);
    
    //Fade between a flat lerp from sky to ground and a 3 way lerp based on how bright the equator light is.
    //This simulates how directional lights get blurred using spherical harmonics
    
    //Work out color from ground and sky, ignoring equator
    float adjustedDot = upDot * skyGroundDotMul;
    half3 skyGroundColor = lerp(unity_AmbientGround, unity_AmbientSky, saturate((adjustedDot + 1.0) * 0.5)).rgb;
    
    //Work out equator lights brightness
    float equatorBright = saturate(dot(unity_AmbientEquator.rgb, unity_AmbientEquator.rgb));
    
    //Blur equator color with sky and ground colors based on how bright it is.
    half3 equatorBlurredColor = lerp(unity_AmbientEquator, saturate(unity_AmbientEquator + unity_AmbientGround + unity_AmbientSky), equatorBright * equatorColorBlur).rgb;
    
    //Work out 3 way lerp inc equator light
    float smoothDot = pow(abs(upDot), 1);
    half3 equatorColor = lerp(equatorBlurredColor, unity_AmbientGround.rgb, smoothDot) * step(upDot, 0) + lerp(equatorBlurredColor, unity_AmbientSky.rgb, smoothDot) * step(0, upDot);
    
    return lerp(skyGroundColor, equatorColor, saturate(equatorBright + minEquatorMix)) * 0.75;
}


half4 TriplanarDiffuse(Texture2D tex_name, sampler tex_sampler, float2 origin_uv, float2 uv_xy, float2 uv_zy, half3 absnormalWS)
{
    half4 color_xz, color_xy, color_zy;

    color_xz = SAMPLE_TEXTURE2D(tex_name, tex_sampler, origin_uv);
    color_xy = SAMPLE_TEXTURE2D(tex_name, tex_sampler, uv_xy);
    color_zy = SAMPLE_TEXTURE2D(tex_name, tex_sampler, uv_zy);
    half4 mixColor = color_xz * absnormalWS.y + color_xy * absnormalWS.z + color_zy * absnormalWS.x;
    return mixColor;
}
float2 Unity_GradientNoise_Dir_float(float2 p)
{
    // Permutation and hashing used in webgl-nosie goo.gl/pX7HtC
    p = p % 289;
    // need full precision, otherwise half overflows when p > 1
    float x = float(34 * p.x + 1) * p.x % 289 + p.y;
    x = (34 * x + 1) * x % 289;
    x = frac(x / 41) * 2 - 1;
    return normalize(float2(x - floor(x + 0.5), abs(x) - 0.5));
}
void Unity_GradientNoise_float(float2 UV, float Scale, out float Out)
{
    float2 p = UV * Scale;
    float2 ip = floor(p);
    float2 fp = frac(p);
    float d00 = dot(Unity_GradientNoise_Dir_float(ip), fp);
    float d01 = dot(Unity_GradientNoise_Dir_float(ip + float2(0, 1)), fp - float2(0, 1));
    float d10 = dot(Unity_GradientNoise_Dir_float(ip + float2(1, 0)), fp - float2(1, 0));
    float d11 = dot(Unity_GradientNoise_Dir_float(ip + float2(1, 1)), fp - float2(1, 1));
    fp = fp * fp * fp * (fp * (fp * 6 - 15) + 10);
    Out = lerp(lerp(d00, d01, fp.y), lerp(d10, d11, fp.y), fp.x) + 0.5;
}
float valueNoise(float2 uv)
{
    float2 intPos = floor(uv); //uv晶格化, 取 uv 整数值
    float2 fracPos = frac(uv); //取 uv 小数值

    //二维插值权重，一个类似smoothstep的函数，叫Hermit插值函数，也叫S曲线：S(x) = -2 x^3 + 3 x^2
    //利用Hermit插值特性：可以在保证函数输出的基础上保证插值函数的导数在插值点上为0，这样就提供了平滑性
    float2 u = fracPos * fracPos * (3.0 - 2.0 * fracPos);

    //四方取点，由于intPos是固定的，所以栅格化了（同一晶格内四点值相同，只是小数部分不同拿来插值）
    float va = hash2to1(intPos + float2(0.0, 0.0));
    float vb = hash2to1(intPos + float2(1.0, 0.0));
    float vc = hash2to1(intPos + float2(0.0, 1.0));
    float vd = hash2to1(intPos + float2(1.0, 1.0));

    //lerp的展开形式，完全可以用lerp(a,b,c)嵌套实现
    float k0 = va;
    float k1 = vb - va;
    float k2 = vc - va;
    float k4 = va - vb - vc + vd;
    float value = k0 + k1 * u.x + k2 * u.y + k4 * u.x * u.y;

    return value;
}

float2 hash2d2(float2 uv)
{
    const float2 k = float2(0.3183099, 0.3678794);
    uv = uv * k + k.yx;
    return -1.0 + 2.0 * frac(16.0 * k * frac(uv.x * uv.y * (uv.x + uv.y)));
}

real randomFloat(real2 pos)
{
    half a = 100863.14159;
    half2 b = half2(0.3, 0.7);
    //avaoid artifacts
    real2 smallValue = sin(pos.xy);
    //get scalar value from 2d vector
    real random = dot(smallValue, b);
    random = frac(sin(random) * a);
    return random;
}

float perlinNoise(float2 uv)
{
    float2 intPos = floor(uv);
    float2 fracPos = frac(uv);

    float2 u = fracPos * fracPos * (3.0 - 2.0 * fracPos);

    float2 ga = hash2d2(intPos + float2(0.0, 0.0));
    float2 gb = hash2d2(intPos + float2(1.0, 0.0));
    float2 gc = hash2d2(intPos + float2(0.0, 1.0));
    float2 gd = hash2d2(intPos + float2(1.0, 1.0));

    float va = dot(ga, fracPos - float2(0.0, 0.0));
    float vb = dot(gb, fracPos - float2(1.0, 0.0));
    float vc = dot(gc, fracPos - float2(0.0, 1.0));
    float vd = dot(gd, fracPos - float2(1.0, 1.0));

    float value = va + u.x * (vb - va) + u.y * (vc - va) + u.x * u.y * (va - vb - vc + vd);

    return value;
}
float simpleNoise(float2 uv)
{
    //transform from triangle to quad
    const float K1 = 0.366025404; // (sqrt(3)-1)/2; //quad 转 2个正三角形 的公式参数
    //transform from quad to triangle
    const float K2 = 0.211324865; // (3 - sqrt(3))/6;

    float2 quadIntPos = floor(uv + (uv.x + uv.y) * K1);
    float2 vecFromA = uv - quadIntPos + (quadIntPos.x + quadIntPos.y) * K2;

    float IsLeftHalf = step(vecFromA.y, vecFromA.x);  //判断左右
    float2 quadVertexOffset = float2(IsLeftHalf, 1.0 - IsLeftHalf);

    float2 vecFromB = vecFromA - quadVertexOffset +K2;
    float2 vecFromC = vecFromA - 1.0 + 2.0 * K2;

    //衰减计算
    float3 falloff = max(0.5 - float3(dot(vecFromA, vecFromA), dot(vecFromB, vecFromB), dot(vecFromC, vecFromC)), 0.0);

    float2 ga = hash22(quadIntPos + 0.0);
    float2 gb = hash22(quadIntPos + quadVertexOffset);
    float2 gc = hash22(quadIntPos + 1.0);

    float3 simplexGradient = float3(dot(vecFromA, ga), dot(vecFromB, gb), dot(vecFromC, gc));
    float3 n = falloff * falloff * falloff * falloff * simplexGradient;
    return dot(n, float3(70, 70, 70));
}
float voronoiNoise(float2 uv)
{
    float dist = 16;
    float2 intPos = floor(uv);
    float2 fracPos = frac(uv);

    for (int x = -1; x <= 1; x++) //3x3九宫格采样

    {
        for (int y = -1; y <= 1; y++)
        {
            //hash22(intPos + float2(x,y)) 相当于offset，定义为在周围9个格子中的某一个特征点
            //float2(x,y) 相当于周围九格子root
            //如没有 offset，那么格子是规整的距离场
            //如果没有 root，相当于在自己的晶格范围内生成特征点，一个格子就有九个“球球”
            float d = distance(hash22(intPos + float2(x, y)) + float2(x, y), fracPos); //fracPos作为采样点，hash22(intPos)作为生成点，来计算dist
            dist = min(dist, d);
        }
    }
    return dist;
}
float FBMvalueNoise(float2 uv)
{
    float value = 0;
    float amplitude = 0.5;
    float frequency = 0;

    for (int i = 0; i < 8; i++)
    {
        value += amplitude * valueNoise(uv); //使用最简单的value噪声做分形，其余同理。
        uv *= 2.0;
        amplitude *= .5;
    }
    return value;
}

half BuildCameraDitherFade(float3 positionWS)
{
    float dist = distance(positionWS, _WorldSpaceCameraPos);
    return dist - 25;
}
 static const  float4x4 thresholdMatrix = {
        1.0 / 17.0, 9.0 / 17.0, 3.0 / 17.0, 11.0 / 17.0,
        13.0 / 17.0, 5.0 / 17.0, 15.0 / 17.0, 7.0 / 17.0,
        4.0 / 17.0, 12.0 / 17.0, 2.0 / 17.0, 10.0 / 17.0,
        16.0 / 17.0, 8.0 / 17.0, 14.0 / 17.0, 6.0 / 17.0
    };

half CameraDitherFade(float4 screenPosition, float3 positionWS, half _MinFadeDist, half _MaxFadeDist)
{
    float2 pos = screenPosition.xy / screenPosition.w;
    pos *= _ScreenParams.xy; // pixel position

    float dist = distance(positionWS, _WorldSpaceCameraPos);
    half fade = smoothstep(_MinFadeDist, _MaxFadeDist, dist);
    // fade = (dist - _MinFadeDist) / (_MaxFadeDist - _MinFadeDist);
    return fade - thresholdMatrix[fmod(pos.x, 4)] [fmod(pos.y, 4)];
}
half CameraDitherFadeTime(float4 screenPosition, float3 positionWS, half alpha)
{
    float2 pos = screenPosition.xy / screenPosition.w;
    pos *= _ScreenParams.xy; // pixel position
    half fade = smoothstep(0, 1, alpha);
    // fade = (dist - _MinFadeDist) / (_MaxFadeDist - _MinFadeDist);
    return fade - thresholdMatrix[fmod(pos.x, 4)] [fmod(pos.y, 4)];
}


//Add New

float DecodeFloatRGBA(float4 rgba)
{
    return dot(rgba, float4(1, 1 / 255.0f, 1 / 65025.0f, 1 / 16581375.0f));
}

//扫光
void AddScanLightEffect(float3 positionWS, half _ScanLightIntensity, inout half3 color)
{
    //扫光
    half yfactor = sin((positionWS.y - 20 * _Time.y) / 7) - 0.8;
    // float distance_camera = 1 - 0.02 * clamp(distance(_WorldSpaceCameraPos.xyz, TransformObjectToWorld(float3(0, 0, 0))), 0, 50);
    yfactor = clamp(yfactor, 0, 1) * 20 * _ScanLightIntensity;
    color += yfactor * color;
}

//自发光贴图
void AddEmissionEffect(half _TurnOnPossibility, half _TurnOnLights, Texture2D _EmissionMap, SamplerState sampler_EmissionMap, half _Emission_Intensity,
                        half2 uv, half4 albedo_map, inout half3 final_color)
{
    half turnOn = 1;
    #if _LIGHTCONTROLON
        turnOn = step(randomFloat(TransformObjectToWorld(half3(0, 0, 0)).xz), _TurnOnPossibility) * _TurnOnLights;
    #endif

    //自发光贴图
    half4 emission_map = SAMPLE_TEXTURE2D(_EmissionMap, sampler_EmissionMap, uv) * _Emission_Intensity;
    #if _EMISSIONMASKON
        final_color = lerp(final_color, lerp(final_color, emission_map * albedo_map.a, step(0.001, albedo_map.a)), turnOn);
    #else
        final_color *= max(1, emission_map * turnOn);
    #endif
}

//自发光颜色
void AddEmissionEffect(half _TurnOnPossibility, half _TurnOnLights,
                        half4 _EmissionColor, half4 albedo_map, inout half3 final_color)
{
    half turnOn = 1;
    #if _LIGHTCONTROLON
        turnOn = step(randomFloat(TransformObjectToWorld(half3(0, 0, 0)).xz), _TurnOnPossibility) * _TurnOnLights;
    #endif

    //自发光颜色
    #if _EMISSIONMASKON
        final_color = lerp(final_color, lerp(final_color, _EmissionColor * albedo_map.a, step(0.001, albedo_map.a)), turnOn);
    #else
        final_color *= max(1, _EmissionColor * turnOn);
    #endif
}


//菲涅尔效果
float Fresnel(half3 normalWS, half3 viewDirWS, float bias, float scale, float power)
{
    return bias + scale * pow(1.0 - saturate(dot(normalize(normalWS), normalize(viewDirWS))), power);
}


#endif
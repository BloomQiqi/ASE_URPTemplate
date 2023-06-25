#ifndef COLOR_POSTPROCESSING
#define COLOR_POSTPROCESSING

CBUFFER_START(ColorPostProcessing)
    half _cyan_red_shadow;
    half _cyan_red_midtones;
    half _cyan_red_highlights;
    half _magenta_green_shadow;
    half _magenta_green_midtones;
    half _magenta_green_highlights;
    half _yellow_blue_shadow;
    half _yellow_blue_midtones;
    half _yellow_blue_highlights;
    half _Contrast = 1;
    half _Saturation = 1;
    half _Brightness = 1;
CBUFFER_END

real3 transfer(real value)
{
    real a = 64.0;
    real b = 85.0;
    real scale = 1.785;
    real3 result;
    real i = value * 255.0;
    real shadows = clamp((i - b) / - a + 0.5, 0.0, 1.0) * scale;
    real midtones = clamp((i - b) / a + 0.5, 0.0, 1.0) * clamp((i + b - 255.0) / - a + .5, 0.0, 1.0) * scale;
    real highlights = clamp(((255.0 - i) - b) / - a + 0.5, 0.0, 1.0) * scale;
    result.r = shadows;
    result.g = midtones;
    result.b = highlights;
    return result;
}

real3 rgb2hsl(real3 color)
{
    real4 K = real4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    real4 p = lerp(real4(color.bg, K.wz), real4(color.gb, K.xy), step(color.b, color.g));
    real4 q = lerp(real4(p.xyw, color.r), real4(color.r, p.yzx), step(p.x, color.r));

    real d = q.x - min(q.w, q.y);
    real e = 1.0 * FLT_EPS - 10;
    return real3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

real3 hsl2rgb(real3 color)
{
    real4 K = real4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    real3 p = abs(frac(color.xxx + K.xyz) * 6.0 - K.www);
    return color.z * lerp(K.xxx, clamp(p - K.xxx, 0.0, 1.0), color.y);
}

real ColorBlendSoftLight(real base, real blend)
{
    return (blend < 0.5) ? (2.0 * base * blend + base * base * (1.0 - 2.0 * blend)) : (sqrt(base) * (2.0 * blend - 1.0) + 2.0 * base * (1.0 - blend));
}

real3 ColorBlendSoftLight(real3 base, real3 blend)
{
    return real3(ColorBlendSoftLight(base.r, blend.r), ColorBlendSoftLight(base.g, blend.g), ColorBlendSoftLight(base.b, blend.b));
}

real ColorBlendOverlay(real base, real blend)
{
    return base < 0.5 ? (2.0 * base * blend) : (1.0 - 2.0 * (1.0 - base) * (1.0 - blend));
}

real3 ColorBlendOverlay(real3 base, real3 blend)
{
    return real3(ColorBlendOverlay(base.r, blend.r), ColorBlendOverlay(base.g, blend.g), ColorBlendOverlay(base.b, blend.b));
}
real3 ColorBalance(real3 color)
{
    real3 hsl = rgb2hsl(color.rgb);
    real3 weight_r = transfer(color.r);
    real3 weight_g = transfer(color.g);
    real3 weight_b = transfer(color.b);
    real3 result_color = real3(color.rgb * 255.0);

    result_color.r += _cyan_red_shadow * weight_r.r;
    result_color.r += _cyan_red_midtones * weight_r.g;
    result_color.r += _cyan_red_highlights * weight_r.b;

    result_color.g += _magenta_green_shadow * weight_g.r;
    result_color.g += _magenta_green_midtones * weight_g.g;
    result_color.g += _magenta_green_highlights * weight_g.b;

    result_color.b += _yellow_blue_shadow * weight_b.r;
    result_color.b += _yellow_blue_midtones * weight_b.g;
    result_color.b += _yellow_blue_highlights * weight_b.b;

    result_color.r = clamp(result_color.r, 0.0, 255.0);
    result_color.g = clamp(result_color.g, 0.0, 255.0);
    result_color.b = clamp(result_color.b, 0.0, 255.0);
    
    // float3 hsl2 = rgb2hsl(result_color / 255.0);
    // hsl2.z = hsl.z;

    // float3 result = hsl2rgb(hsl2);
    return result_color / 255.0;
}

real3 ColorAdjustment(real3 color)
{
    //颜色校正
    real3 result_color;
    //亮度调整
    result_color = color.rgb * _Brightness;
    //饱和度调整
    half luminance = 0.2125 * result_color.r + 0.7154 * result_color.g + 0.0721 * result_color.b;
    result_color = lerp(luminance.xxx, result_color, _Saturation);
    //对比度调整
    result_color = lerp(half3(0.5, 0.5, 0.5), result_color, _Contrast);
    return result_color;
}

half3 HueShift(half3 color, half hue)
{
    half3 k = half3(0.57735, 0.57735, 0.57735);
    half cosAngle = cos(hue);
    return half3(color * cosAngle + cross(k, color) * sin(hue) + k * dot(k, color) * (1.0 - cosAngle));
}
#endif
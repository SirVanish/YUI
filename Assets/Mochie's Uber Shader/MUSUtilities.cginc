#include "MUSDefines.cginc"

//----------------------------
// Misc
//----------------------------
float linearstep(float j, float k, float x) {
	x = clamp((x - j) / (k - j), 0.0, 1.0); 
	return x;
}

float smootherstep(float edge0, float edge1, float x) {
    x = clamp((x - edge0) / (edge1 - edge0), 0.0, 1.0);
    return x * x * x * (x * (x * 6 - 15) + 10);    
}

float AverageRGB(float3 rgb){
    return (rgb.r + rgb.g + rgb.b)/3;
}

float3 GetNoiseRGB(float2 p, float strength) {
    float3 p3 = frac(float3(p.xyx) * (float3(443.8975, 397.2973, 491.1871)+_Time.y));
    p3 += dot(p3, p3.yxz + 19.19);
    float3 rgb = frac(float3((p3.x + p3.y)*p3.z, (p3.x + p3.z)*p3.y, (p3.y + p3.z)*p3.x));
	rgb = (rgb-0.5)*2*strength;
	return rgb;
}

//----------------------------
// Lighting
//----------------------------
float3 GetLightDir(float3 wPos, float atten){
    float3 lightDir = float3(0,0.75,1);
    #if defined(UNITY_PASS_FORWARDADD)
        lightDir = _WorldSpaceLightPos0.xyz - wPos;
        return normalize(lightDir);
    #else
        UNITY_BRANCH
        if (_StaticLightDirToggle == 1){
            return _StaticLightDir.xyz;
        }
        else {
            lightDir = _WorldSpaceLightPos0.xyz;
            lightDir *= atten * dot(float3(0.2126, 0.7152, 0.0722), _LightColor0);
            float3 probeDir = unity_SHAr.xyz + unity_SHAg.xyz + unity_SHAb.xyz;
            lightDir = lightDir + probeDir;
            return normalize(lightDir);
        }
    #endif
    return lightDir;
}

float3 GetLightColor(float3 pc){
    float3 lightCol = _LightColor0;
    UNITY_BRANCH
    if (_RenderMode == 2)
        lightCol = saturate(lightCol + pc);
    else {
        if (!any(_WorldSpaceLightPos0))
            lightCol = pc * 0.2;
    }
    return lightCol;
}

float GetWorldBrightness(float3 ilc){
    float3 col = _LightColor0;
    if (!any(_WorldSpaceLightPos0))
        col = ilc;
    float b = saturate(AverageRGB(col));
    return b;
}

float3 BoxProjection(float3 dir, float3 pos, float4 cubePos, float3 boxMin, float3 boxMax){
    #if UNITY_SPECCUBE_BOX_PROJECTION
        UNITY_BRANCH
        if (cubePos.w > 0){
            float3 factors = ((dir > 0 ? boxMax : boxMin) - pos) / dir;
            float scalar = min(min(factors.x, factors.y), factors.z);
            dir = dir * scalar + (pos - cubePos);
        }
    #endif
    return dir;
}

//----------------------------
// Color Filtering
//----------------------------
float oetf_sRGB_scalar(float L) {
	float V = 1.055 * (pow(L, 1.0 / 2.4)) - 0.055;
	if (L <= 0.0031308)
		V = L * 12.92;
	return V;
}

float3 oetf_sRGB(float3 L) {
	return float3(oetf_sRGB_scalar(L.r), oetf_sRGB_scalar(L.g), oetf_sRGB_scalar(L.b));
}

float eotf_sRGB_scalar(float V) {
	float L = pow((V + 0.055) / 1.055, 2.4);
	if (V <= oetf_sRGB_scalar(0.0031308))
		L = V / 12.92;
	return L;
}

float3 GetHDR(float3 rgb) {
	return float3(eotf_sRGB_scalar(rgb.r), eotf_sRGB_scalar(rgb.g), eotf_sRGB_scalar(rgb.b));
}

float3 GetContrast(float3 col){
    return clamp((lerp(float3(0.5,0.5,0.5), col, _Contrast)), 0, 10);
}

float3 GetSaturation(float3 col, float interpolator){
    return lerp(dot(col, float3(0.3,0.59,0.11)), col, interpolator);
}

const static float EPS = 1e-10;
float3 RGBtoHCV(in float3 rgb) {
    float4 P = lerp(float4(rgb.bg, -1.0, 2.0/3.0), float4(rgb.gb, 0.0, -1.0/3.0), step(rgb.b, rgb.g));
    float4 Q = lerp(float4(P.xyw, rgb.r), float4(rgb.r, P.yzx), step(P.x, rgb.r));
    float C = Q.x - min(Q.w, Q.y);
    float H = abs((Q.w - Q.y) / (6 * C + EPS) + Q.z);
    return float3(H, C, Q.x);
}

float3 RGBtoHSL(in float3 rgb) {
    float3 HCV = RGBtoHCV(rgb);
    float L = HCV.z - HCV.y * 0.5;
    float S = HCV.y / (1 - abs(L * 2 - 1) + EPS);
    return float3(HCV.x, S, L);
}

float3 HSLtoRGB(float3 c) {
    c = float3(frac(c.x), clamp(c.yz, 0.0, 1.0));
    float3 rgb = clamp(abs(fmod(c.x * 6.0 + float3(0.0, 4.0, 2.0), 6.0) - 3.0) - 1.0, 0.0, 1.0);
    return c.z + c.y * (rgb - 0.5) * (1.0 - abs(2.0 * c.z - 1.0));
}

float3 PreserveColor(float3 diff, float3 albedo, float3 ts, float3 refl, float SSS){
    #if defined(UNITY_PASS_FORWARDBASE)
        UNITY_BRANCH
        if (_PreserveCol == 1){
            float3 preserved = albedo + ts + refl + SSS;
            diff = clamp(diff, 0, preserved);
        }
    #endif
    return diff;
}
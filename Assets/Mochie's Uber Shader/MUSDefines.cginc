#include "UnityPBSLighting.cginc"
#include "Autolight.cginc"
#include "UnityCG.cginc"

// Global
int _RenderMode, _Outline, _ZWrite, _ATM, _PreserveCol, _BlendMode;
float4 _OutlineCol;
float _Opacity, _Cutoff, _OutlineThicc;

// Post Filters
int _FilterModel, _AutoShift;
float _SaturationRGB, _Brightness, _RAmt, _GAmt, _BAmt;
float _SaturationHSL, _AutoShiftSpeed, _Hue, _Luminance, _HSLMin, _HSLMax;
float _Contrast, _HDR;

// Base
UNITY_DECLARE_TEX2D(_MainTex); float4 _MainTex_ST;
UNITY_DECLARE_TEX2D(_EmissionMap); float4 _EmissionMap_ST;
UNITY_DECLARE_TEX2D_NOSAMPLER(_EmissMask); float4 _EmissMask_ST;
float4 _Color, _EmissionColor;

// Advanced Emission
int _UsingMask, _ReactToggle, _CrossMode;
float _XScroll, _YScroll, _PulseSpeed, _Crossfade, _ReactThresh;

// Global Shading
sampler2D _BumpMap;
sampler2D _DetailNormalMap; float4 _DetailNormalMap_ST;
sampler2D _RimMask; float4 _RimMask_ST;
sampler2D _RimTex; float4 _RimTex_ST;
UNITY_DECLARE_TEX2D_NOSAMPLER(_DetailAlbedoMap); float4 _DetailAlbedoMap_ST;
UNITY_DECLARE_TEX2D_NOSAMPLER(_DetailMask); float4 _DetailMask_ST;
int _StaticLightDirToggle, _UnlitRim, _RimBlending;
float4 _RimCol, _StaticLightDir;
float _RimMaskStr, _RimStrength, _RimWidth, _RimEdge, _RimNoise;
float _BumpScale, _DetailNormalMapScale, _DetailMaskStr;

// Toon Shading
sampler2D _ShadowRamp;
UNITY_DECLARE_TEX2D_NOSAMPLER(_ShadowMask);
UNITY_DECLARE_TEX2D_NOSAMPLER(_TranslucencyMap);
UNITY_DECLARE_TEX2D_NOSAMPLER(_LightMask);
int _EnableShadowRamp, _Reflections, _FakeSpec, _Subsurface;
float4 _SpecCol, _SColor;
float _ShadowStr, _RampWidth;
float _ShadowMaskStr, _LightMaskStr;
float _ReflSmooth;
float _IOR, _FresnelStr, _FresnelFade, _FresnelSmooth, _FresnelMetallic;
float _SpecStr, _SpecSize, _SpecBias;
float _SStrength, _SPen, _SSharp;
float _ToonMetallic;

// PBR Shading
sampler2D _MetallicGlossMap;
sampler2D _SpecGlossMap;
sampler2D _OcclusionMap;
sampler2D _ParallaxMap;
samplerCUBE _ReflCube;
int _PBRWorkflow, _SourceAlpha, _InvertRough, _March, _UseReflCube, _ReflCubeFallback;
float4 _PBRSpecCol;
float _Metallic, _Glossiness, _GlossMapScale, _OcclusionStrength, _Parallax, _HeightContrast;

// Outputs
float omr;
float3 specularTint;

struct appdata {
    float4 vertex : POSITION;
    float2 uv : TEXCOORD0;
    float4 tangent : TANGENT;
    float3 normal : NORMAL;
};

#if defined(UNITY_PASS_FORWARDBASE) || defined(UNITY_PASS_FORWARDADD)
    struct v2f {
        float4 pos : SV_POSITION;
        float4 uv : TEXCOORD0;
        float3 worldPos : TEXCOORD1;
        float3 binormal : TEXCOORD2; 
        float2 uvd : TEXCOORD3;
        float3 tangentViewDir : TEXCOORD4;
        float4 tangent : TANGENT;
        float3 normal : NORMAL;
        SHADOW_COORDS(13)
        UNITY_FOG_COORDS(14)
    };
#elif defined(UNITY_PASS_SHADOWCASTER)
    struct v2f {
        V2F_SHADOW_CASTER;
        float2 uv : TEXCOORD1;
    };
#else
    struct v2f {
        float4 pos : SV_POSITION;
        float2 uv : TEXCOORD0;
        float4 color : COLOR;
        UNITY_FOG_COORDS(14)
    };
#endif

struct lighting {
    float NdotL;
    float ao;
    float lightmask;
    float worldBrightness;
    float fresnel;
    float3 lightCol;
    float3 indirectCol;
    float3 lightDir; 
    float3 viewDir; 
    float3 halfVector; 
    float3 bumpMap;
    float3 detailNormal; 
    float3 tangentNormals; 
    float3 binormal;
    float3 normalDir;
    float3 reflectionDir;
};
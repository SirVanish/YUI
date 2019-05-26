// By Mochie
// Free for public usage and editing (just don't change the name, it'll break things)
// Version 2.3

Shader "Mochie/Mochie's Uber Shader (Cutout)" {
    Properties {
        
            // Global
            [HideInInspector]_BlendMode("__mode", Float) = 0.0
            [HideInInspector]_SrcBlend("__src", Float) = 1.0
            [Enum(BASIC,0, TOON,1, PBR,2)]_RenderMode("", Int) = 0
            [Enum(OFF,0, ON,2)]_CullingMode("", Int) = 2
            [Enum(OFF,0, COLOR,1, TINTED,2)]_Outline("", Int) = 0
            [Enum(OFF,0, ON,1)]_ZWrite("ZWrite", Int) = 0
            [Enum(OFF,0, ON,1)]_ATM("", Int) = 0
            _Opacity("", Range(0,1)) = 1
            _Cutoff("", Range(0,1)) = 0.5
            _OutlineCol("", Color) = (0.75,0.75,0.75,1)
            _OutlineThicc("", Range(0,1)) = 0.1
            [Toggle(_)]_PreserveCol("", Int) = 0

            // Post Filters
            [Enum(OFF,0, RGB,1, HSL,2)]_FilterModel("", Int) = 0
            _HDR("", Range(0,1)) = 0
            _Contrast("", Range(0,2)) = 1
            _SaturationRGB("", Range(0,2)) = 1
            _Brightness("", Range(-1,1)) = 0
            _RAmt("", Range(0,2)) = 1
            _GAmt("", Range(0,2)) = 1
            _BAmt("", Range(0,2)) = 1
            
            [Toggle(_)]_AutoShift("Auto Shift", Int) = 0
            _AutoShiftSpeed("Speed", Range(0,1)) = 0.25
			_Hue("", Range(0,1)) = 0
			_SaturationHSL("", Range(-1,1)) = 0
			_Luminance ("", Range(0,0.5)) = 0
			_HSLMin("", Range(0,1)) = 0
			_HSLMax("", Range(0,1)) = 1

            // Base
            _Color("", Color) = (1,1,1,1)
            _MainTex("", 2D) = "white" {}
            [HDR]_EmissionColor("", Color) = (0,0,0,1)
            _EmissionMap("", 2D) = "white" {}

            // Advanced Emission
            [HideInInspector]_UsingMask("", Int) = 0
            _EmissMask("", 2D) = "white" {}
            _XScroll("", Range(-2,2)) = 0
            _YScroll("", Range(-2,2)) = 0
            _PulseSpeed("", Range(0,8)) = 0
            [Toggle(_)]_ReactToggle("", Int) = 0
            [Toggle(_)]_CrossMode("", Int) = 0
            _Crossfade("", Range(0,0.2)) = 0.1
            _ReactThresh("", Range(0,1)) = 0.5

            // Global Shading
            [Enum(OPAQUE,0, ADD,1, SUBTRACT,2, MULTIPLY,3)]_RimBlending("", Int) = 0
            [Toggle(_)]_UnlitRim("", Int) = 1
            _RimTex("", 2D) = "white" {}
            _RimMask("", 2D) = "white" {}
            _RimMaskStr("", Range(0,1)) = 1
            [HDR]_RimCol("", Color) = (1,1,1,1)
            _RimNoise("", Range(0,1)) = 0
            _RimStrength("", Range(0,1)) = 0
            _RimWidth("", Range (0,1)) = 0.5
            _RimEdge("", Range(0,0.5)) = 0
            _BumpScale("", Range(-2,2)) = 1
            _BumpMap("", 2D) = "bump" {}
            _DetailNormalMapScale("", Range(-2,2)) = 1
            _DetailNormalMap("", 2D) = "bump" {}
            _DetailAlbedoMap("", 2D) = "gray" {}
            _DetailMask("", 2D) = "white" {}
            _DetailMaskStr("", Range(0,1)) = 1
            [Toggle(_)]_StaticLightDirToggle("", Int) = 0
            _StaticLightDir("", Vector) = (0,0.75,1,0)

            // Toon Shading
            [Toggle(_)]_EnableShadowRamp("", Int) = 0
            _ShadowMask("", 2D) = "white" {}
            _ShadowMaskStr("", Range(0,1)) = 1
            _LightMaskStr("", Range(0,1)) = 1
            _ShadowRamp("", 2D) = "white" {}
            _ShadowStr("", Range(0,1)) = 1
            _RampWidth("", Range(0,1)) = 0.01
            _LightMask("", 2D) = "white" {}
            [Toggle(_)]_Reflections("", Int) = 0
            _IOR("", Range(0,1)) = 1
            _FresnelStr("", Range(0,1)) = 1
            _FresnelFade("", Range(0,1)) = 1
            _FresnelSmooth("", Range(0,1)) = 1
            _FresnelMetallic("", Range(0,1)) = 1
            _ReflSmooth("", Range(0,1)) = 0.5
            _ToonMetallic("", Range(0,1)) = 0
            [Toggle(_)]_FakeSpec("", Int) = 0
            _SpecStr("", Range(0,1)) = 0.8
            _SpecSize("", Range(0,1)) = 0.5
            _SpecBias("", Range(0,1)) = 1
            _SpecCol("", Color) = (1,1,1,1)
            [Toggle(_)]_Subsurface("", Int) = 0
            _TranslucencyMap("", 2D) = "white" {}
            _SColor ("", Color) = (1,1,1,1)
            _SStrength("", Range(0,4)) = 1
            _SPen("", Range(0,1)) = 1
            _SSharp("", Range (1,0.0001)) = 1

            // PBR
            [Enum(Metallic,0, Specular,1)]_PBRWorkflow("", Int) = 0
            [Enum(Specular,0, Albedo,1)]_SourceAlpha("", Int) = 0
            _PBRSpecCol("", Color) = (0.2,0.2,0.2,1)
            _Metallic("", Range(0,1)) = 0
            _MetallicGlossMap("", 2D) = "white" {}
            _Glossiness("", Range(0,1)) = 0.5
            _GlossMapScale("", Range(0,1)) = 0.5
            _SpecGlossMap("", 2D) = "white" {}
            [Toggle(_)]_InvertRough("", Int) = 0
            _OcclusionStrength("", Range(0,1)) = 1
            _OcclusionMap("", 2D) = "white" {}
            _ParallaxMap("", 2D) = "white" {}
            _Parallax("", Range(0,0.1)) = 0.01
            _HeightContrast("", Range(1,1.5)) = 1
            [Toggle(_)]_March("", Int) = 0
            [Toggle(_)]_UseReflCube("", Int) = 0
            _ReflCube("", CUBE) = "white" {}
            [Toggle(_)]_ReflCubeFallback("", Int) = 0
    }

    SubShader {
        Tags {"RenderType"="TransparentCutout" "Queue"="AlphaTest+1"}
        AlphaToMask [_ATM]
        Cull [_CullingMode]
        Pass {
            Name "ForwardBase"
            Tags {"LightMode"="ForwardBase"}
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma fragmentoption ARB_precision_hint_fastest
            #pragma shader_feature _DETAIL_MULX2
            #pragma shader_feature _PARALLAXMAP
            #pragma shader_feature _SPECGLOSSMAP
            #pragma multi_compile_fwdbase
            #pragma multi_compile_fog
            #pragma target 5.0
            #define UNITY_PASS_FORWARDBASE
            #define CUTOUT
            #include "MUSPass.cginc"
            ENDCG
        }

        Pass {
            Name "ForwardAdd"
            Tags {"RenderType"="Transparent" "LightMode"="ForwardAdd"}
            Blend One One
            ZWrite Off
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma fragmentoption ARB_precision_hint_fastest
            #pragma shader_feature _DETAIL_MULX2
            #pragma shader_feature _PARALLAXMAP
            #pragma shader_feature _SPECGLOSSMAP
            #pragma multi_compile_fwdadd_fullshadows
            #pragma multi_compile_fog
            #pragma target 5.0
            #define UNITY_PASS_FORWARDADD
            #define CUTOUT
            #include "MUSPass.cginc"
            ENDCG
        }

        Pass {
            Name "ShadowCaster"
            Tags {"RenderType"="Transparent" "Queue"="Transparent" "LightMode"="ShadowCaster"}
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma fragmentoption ARB_precision_hint_fastest
            #pragma multi_compile_shadowcaster
            #pragma target 5.0
            #define UNITY_PASS_SHADOWCASTER
            #define CUTOUT
            #include "MUSPass.cginc"
            ENDCG
        }

        Pass {
            Name "Outline"
            Tags {"RenderType"="Opaque" "Queue"="Geometry"}
            Cull Front
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma fragmentoption ARB_precision_hint_fastest
            #pragma multi_compile_fog
            #pragma target 5.0
            #define CUTOUT
            #define OUTLINE
            #include "MUSPass.cginc"
            ENDCG
        }
    }
    Fallback "Transparent/Cutout/Diffuse"
    CustomEditor "MUSEditor"
}
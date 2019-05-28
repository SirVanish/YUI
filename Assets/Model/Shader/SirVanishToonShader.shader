// Built based off of GearXStage shaders 
// from https://forum.unity.com/threads/guilty-gear-xrd-shader-test.448557/

Shader "Custom/SirVanishToonShader" 
{
	Properties
	{
		_MainTex("Albedo (RGB)", 2D) = "white" {}
		_SSSTex("SSS (RGB)", 2D) = "white" {}
		_ILMTex("ILM (RGB)", 2D) = "white" {}

		_OutlineColor("Outline Color", Color) = (0,0,0,1)
		_Outline("Outline width", Range(.0, 2)) = .001
		// _DarkenInnerLineColor("Darken Inner Line Color", Range(0, 1)) = 0.2

		_Cutoff("Alpha Cutoff", Range(0,1)) = 0.7
	}

	CGINCLUDE
	#include "UnityCG.cginc"
	sampler2D _MainTex;
	sampler2D _SSSTex;
	struct appdata 
	{
		float4 vertex : POSITION;
		float3 normal : NORMAL;
		float4 texCoord : TEXCOORD0;
	};

	struct v2f 
	{
		float4 pos : POSITION;
		float4 color : COLOR;
		float4 tex : TEXCOORD0;
	};

	uniform float _Outline;
	uniform float4 _OutlineColor;
	// uniform float _DarkenInnerLineColor;

	v2f vert(appdata v) 
	{
		// just make a copy of incoming vertex data but scaled according to normal direction
		v2f o;
		o.pos = UnityObjectToClipPos(v.vertex);
		float3 norm = mul((float3x3)UNITY_MATRIX_IT_MV, v.normal);
		float2 offset = TransformViewToProjection(norm.xy);
		o.pos.xy += offset * _Outline;
		o.tex = v.texCoord;
		
		o.color = _OutlineColor;
		return o;
	}
	ENDCG

	SubShader 
	{
		// Tags{ "RenderType"="Opaque" }
		Tags {"Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent"}

		CGPROGRAM
		#pragma surface surfA Lambert alphatest:_Cutoff

		fixed4 _Color;

		struct Input
		{
			float2 uv_MainTex;
		};

		void surfA(Input IN, inout SurfaceOutput o) 
		{
			half4 c2 = half4(1, 0, 1, 1);

			o.Albedo = c2.rgb;
			// o.Alpha = c2.a;
		}
		ENDCG

		// note that a vertex shader is specified here but its using the one above
		Pass
		{
			Name "OUTLINE"
			Tags{ "LightMode" = "Always" }
			Cull Front
			ZWrite On
			ColorMask RGB
			Blend SrcAlpha OneMinusSrcAlpha

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			half4 frag(v2f i) :COLOR 
			{ 
				fixed4 cLight = tex2D(_MainTex, i.tex.xy);
				fixed4 cSSS = tex2D(_SSSTex, i.tex.xy);
				fixed4 cDark = cLight * cSSS;

				cDark = cDark * 0.5f;
				// cDark.a = 1; // weapon had alpha?

				return cDark;
			}

			ENDCG
		} // end of Pass


		// ###############################
		CGPROGRAM
  
		// noforwardadd: important to remove multiple light passes
		#pragma surface surf  CelShadingForward  vertex:vertB alphatest:_Cutoff
		// Use shader model 3.0 target, to get nicer looking lighting
		#pragma target 3.0

		sampler2D _ILMTex;

		struct Input 
		{
			float2 uv_MainTex;
			float3 vertexColor; // Vertex color stored here by vert() method
		};

		struct v2fB 
		{
			float4 pos : SV_POSITION;
			fixed4 color : COLOR;
		};

		void vertB(inout appdata_full v, out Input o)
		{
			UNITY_INITIALIZE_OUTPUT(Input, o);
			o.vertexColor = v.color; // Save the Vertex Color in the Input for the surf() method
		}

		struct SurfaceOutputCustom
		{
			fixed3 Albedo;
			fixed3 Normal;
			fixed3 Emission;
			fixed Alpha;

			half3 BrightColor;
			half3 ShadowColor;
			half3 InnerLineColor;
			half ShadowThreshold;

			half SpecularIntensity;
			half SpecularSize;
		};

		half4 LightingCelShadingForward(SurfaceOutputCustom s, half3 lightDir, half atten) 
		{
			half NdotL = dot(lightDir, s.Normal);

			half4 c = half4(0, 0, 0, 1);
	
			half4 specColor = half4(s.SpecularIntensity, s.SpecularIntensity, s.SpecularIntensity, 1);
			half blendArea = 0.04;

			NdotL -= s.ShadowThreshold;

			half specStrength = s.SpecularIntensity;		
			if (NdotL < 0)
			{
				if ( NdotL < - s.SpecularSize -0.5f && specStrength <= 0.5f)
					c.rgb = s.ShadowColor *(0.5f + specStrength);
				else
					c.rgb = s.ShadowColor;
			}
			else
			{
				if (s.SpecularSize < 1 && NdotL * 1.8f > s.SpecularSize && specStrength >= 0.5f)
					c.rgb = s.BrightColor * (0.5f + specStrength);
				else
					c.rgb = s.BrightColor;
			}
		
			// add inner lines
			c.rgb = c.rgb * s.InnerLineColor;

			return c;
		}

		void surf(Input IN, inout SurfaceOutputCustom o) 
		{
			// Albedo comes from a texture tinted by color
			fixed4 c = tex2D(_MainTex, IN.uv_MainTex);
				
			fixed4 cSSS = tex2D(_SSSTex, IN.uv_MainTex);
			fixed4 cILM = tex2D(_ILMTex, IN.uv_MainTex);

			o.Alpha = c.a;
			o.BrightColor = c.rgb;
			o.ShadowColor = c.rgb * cSSS.rgb;

			float clampedLineColor = cILM.a;
			// if (clampedLineColor < _DarkenInnerLineColor)
			//  	clampedLineColor = _DarkenInnerLineColor; 

			o.InnerLineColor = half3(clampedLineColor, clampedLineColor, clampedLineColor);
	
			float vertColor = IN.vertexColor.r;

			// easier to combine black dark areas 
			o.ShadowThreshold = cILM.g;
			o.ShadowThreshold *= vertColor;
			o.ShadowThreshold = 1 - o.ShadowThreshold;

			o.SpecularIntensity = cILM.r;
			o.SpecularSize =  1-cILM.b;
		}
		ENDCG
	}

	FallBack "Diffuse"
}

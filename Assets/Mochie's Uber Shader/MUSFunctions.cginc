#include "MUSUtilities.cginc"

//----------------------------
// Color Filtering
//----------------------------
float3 GetHSLFilter(float3 albedo){
    UNITY_BRANCH
    if (_AutoShift == 1)
        _Hue += frac(_Time.y*_AutoShiftSpeed);
    float3 shift = float3(_Hue, _SaturationHSL, _Luminance);
    float3 hsl = RGBtoHSL(albedo);
    float hslRange = step(_HSLMin, hsl) * step(hsl, _HSLMax);
    albedo = HSLtoRGB(hsl + shift * hslRange);
    albedo = lerp(albedo, GetHDR(albedo), _HDR);
    albedo = GetContrast(albedo);
    return albedo;
}

float3 GetRGBFilter(float3 albedo){
    albedo.r *= _RAmt;
    albedo.g *= _GAmt;
    albedo.b *= _BAmt;
    albedo = GetSaturation(albedo, _SaturationRGB);
    albedo = lerp(albedo, GetHDR(albedo), _HDR);
    albedo = GetContrast(albedo);
    albedo += albedo*_Brightness;
    return albedo;
}

//----------------------------
// Albedo, Diffuse, Emission
//----------------------------
float GetDetailMask(float2 uv){
    float detailMask = UNITY_SAMPLE_TEX2D_SAMPLER(_DetailMask, _MainTex, uv).a;
    detailMask = saturate(detailMask);
    detailMask = lerp(1, detailMask, _DetailMaskStr);
    return detailMask;
}

float3 GetDetailAlbedo(float3 col, float2 uv0, float2 uv1){
    float detailMask = GetDetailMask(uv0);
    float3 detailAlbedo = UNITY_SAMPLE_TEX2D_SAMPLER(_DetailAlbedoMap, _MainTex, uv1).rgb * unity_ColorSpaceDouble;
    float3 albedo = lerp(col, col*detailAlbedo, detailMask);
    UNITY_BRANCH
    if (_FilterModel == 2){
        albedo = saturate(albedo);
        albedo = GetSaturation(albedo, 1.2);
    }
    return albedo;
}

float4 GetAlbedo(float2 uv0, float2 uv1){
    float4 albedo = UNITY_SAMPLE_TEX2D(_MainTex, uv0);
    albedo.rgb *= _Color.rgb;
    albedo.rgb = GetDetailAlbedo(albedo, uv0, uv1);
    UNITY_BRANCH
    switch (_FilterModel){
        case 1: albedo.rgb = GetRGBFilter(albedo.rgb); break;
        case 2: albedo.rgb = GetHSLFilter(albedo.rgb); break;
        default: break;
    }
    #if defined(TRANSPARENT)
        UNITY_BRANCH
        switch (_BlendMode){
            case 0: albedo.a *= _Color.a; break;
            case 1: albedo.a = _Color.a; break;
            default: break;
        } 
    #endif
    return albedo;
}

float4 GetDiffuse(lighting l, float4 albedo, float3 atten){
    float4 diffuse;
    float3 lc = atten * l.lightCol + l.indirectCol;
    //albedo.rgb = lerp(albedo.rgb, reflCol, _ToonMetallic);
    //lc = lerp(lc, albedo, _ToonMetallic);
    diffuse.rgb = lc;
    diffuse.rgb *= albedo.rgb;
    diffuse.a = albedo.a;
    return diffuse;
}

float3 GetEmission(float4 uv){
    float3 emiss = UNITY_SAMPLE_TEX2D(_EmissionMap, uv.zw);
    emiss *= _EmissionColor.rgb;
    UNITY_BRANCH
    if (_UsingMask == 1)
        emiss.rgb *= UNITY_SAMPLE_TEX2D_SAMPLER(_EmissMask, _EmissionMap, TRANSFORM_TEX(uv.xy, _EmissMask));
    emiss *= smootherstep(-1, 1, sin(_Time.y * _PulseSpeed));
    return emiss;
}

float3 GetLREmission(float brightness, float3 emiss){
    float interpolator = 0;
    UNITY_BRANCH
    if (_CrossMode == 1 && _ReactToggle == 1){
        float2 threshold = saturate(float2(_ReactThresh-_Crossfade, _ReactThresh+_Crossfade));
        interpolator = smootherstep(threshold.x, threshold.y, brightness); 
    }
    UNITY_BRANCH
    if (_CrossMode != 1 && _ReactToggle == 1)
        interpolator = brightness*_ReactToggle;

    return lerp(emiss, 0, interpolator);
}

//----------------------------
// Shading
//----------------------------

float3 GetWorldAttenuation(float ndl, float atten, float2 uv){
    #if defined(UNITY_PASS_FORWARDBASE)
        float nAtten = pow(1-atten, 5);
        atten = saturate(atten + (1-nAtten));
        ndl *= atten;
    #endif
    UNITY_BRANCH
    if (_RenderMode == 1){
        float mask = lerp(1, UNITY_SAMPLE_TEX2D_SAMPLER(_ShadowMask, _MainTex, uv), _ShadowMaskStr);
        UNITY_BRANCH
        if (_EnableShadowRamp == 1){
            float rampUV = ndl * 0.5 + 0.5;
            float3 wAtten = tex2D(_ShadowRamp, float2(rampUV, rampUV)).rgb;
            return lerp(1, wAtten, _ShadowStr*mask);
        }
        else {
            float ramp = lerp(50, 150, _RampWidth);
            float3 wAtten = saturate((ndl * ramp) / (ramp-49.999));
            return lerp(0.999, wAtten, _ShadowStr*mask); 
        }
    }
    else if (_RenderMode == 2) {
        return saturate(ndl*1000);
    }
    else
        return 1;
}


float3 GetToonSpec(lighting l, float3 albedo, float3 atten){
    float3 ts = 0;
    UNITY_BRANCH
    if (_FakeSpec == 1 && l.NdotL > 0){
        #if defined(UNITY_PASS_FORWARDBASE)
            _SpecStr *= l.worldBrightness;
        #endif
        float3 sc = lerp(albedo, _SpecCol.rgb, _SpecBias*l.fresnel);
        float fresRough = lerp(1, l.fresnel, (1-_FresnelSmooth)*_FresnelStr);
        float exponent = exp2(fresRough*l.lightmask*_SpecSize*13);
        float pied = exponent / (20*UNITY_PI);
        ts = pow(max(0, dot(l.halfVector, l.normalDir)), exponent) * pied * sc;
        ts = ts * l.lightmask * l.ao * atten * _SpecStr;
    }
    return ts;
}

float3 GetSSS(lighting l, float3 albedo, float atten, float2 uv){
    float3 sss = 0;
    UNITY_BRANCH
    if (_Subsurface == 1){
        _SPen = 1-_SPen;
        l.NdotL = smootherstep(_SPen-_SSharp, _SPen+_SSharp, l.NdotL);
        atten = saturate(l.NdotL * atten);
        float3 vLTLight = l.lightCol * l.normalDir;
        float fLTDot = saturate(dot(l.viewDir, -l.halfVector));
        float3 fLT = (fLTDot + l.indirectCol) * UNITY_SAMPLE_TEX2D_SAMPLER(_TranslucencyMap, _MainTex, uv) * _SStrength * atten * _SColor;
        sss = l.lightCol * fLT * albedo * l.lightmask;
    }
    return sss;
}

//----------------------------
// Reflections
//----------------------------
#if defined(UNITY_PASS_FORWARDBASE)
float3 GetWorldReflections(float3 reflDir, float3 wPos, float roughness){
    reflDir = BoxProjection(reflDir, wPos, unity_SpecCube0_ProbePosition, unity_SpecCube0_BoxMin, unity_SpecCube0_BoxMax);
    float4 envSample0 = UNITY_SAMPLE_TEXCUBE_LOD(unity_SpecCube0, reflDir, roughness * UNITY_SPECCUBE_LOD_STEPS);
    float3 p0 = DecodeHDR(envSample0, unity_SpecCube0_HDR);
    float interpolator = unity_SpecCube0_BoxMin.w;
    UNITY_BRANCH
    if (interpolator < 0.99999){
        float3 refDirBlend = BoxProjection(reflDir, wPos, unity_SpecCube1_ProbePosition, unity_SpecCube1_BoxMin, unity_SpecCube1_BoxMax);
        float4 envSample1 = UNITY_SAMPLE_TEXCUBE_SAMPLER_LOD(unity_SpecCube1, unity_SpecCube0, refDirBlend, roughness * UNITY_SPECCUBE_LOD_STEPS);
        float3 p1 = DecodeHDR(envSample1, unity_SpecCube1_HDR);
        p0 = lerp(p1, p0, interpolator);
    }
    return p0;
}

float3 GetStaticReflCol(float3 reflDir, float roughness){
    return texCUBElod(_ReflCube, float4(reflDir, roughness * UNITY_SPECCUBE_LOD_STEPS));
}

float3 GetStaticReflections(float3 reflDir, float3 wPos, float roughness){
    float3 p0 = 0;
    roughness *= 1.7-0.7*roughness;
    float3 wr = GetWorldReflections(reflDir, wPos, roughness);
    UNITY_BRANCH
    if (_ReflCubeFallback == 1){
        if (!any(wr)) 
            p0 = GetStaticReflCol(reflDir, roughness);
        else p0 = wr;
    }
    else p0 = GetStaticReflCol(reflDir, roughness);
    return p0;
}

float3 GetReflections(lighting l, v2f i, float3 albedo, float roughness){
    float3 reflections = 0;
    UNITY_BRANCH
    switch (_UseReflCube){
        case 0: reflections = GetWorldReflections(l.reflectionDir, i.worldPos.xyz, roughness); break;
        case 1: reflections = GetStaticReflections(l.reflectionDir, i.worldPos.xyz, roughness); break;
        default: break;
    }
    reflections *= l.ao;
    return reflections;
}

float3 GetToonReflections(lighting l, float3 diffuse, float3 albedo, float3 reflCol){
    UNITY_BRANCH
    if (_Reflections == 1){
        reflCol *= l.lightmask;
        reflCol *= lerp(albedo, 1, l.fresnel);
        float3 fresRefl = reflCol*l.fresnel;
        float3 baseRefl = reflCol*0.1;
        float3 fresSmooth = lerp(baseRefl, baseRefl+fresRefl, _FresnelStr);
        float fresMetallic = lerp(1, l.fresnel, 1-_FresnelMetallic);
        float metallic = _ToonMetallic*l.lightmask*fresMetallic;
        diffuse += fresSmooth;
        diffuse = lerp(diffuse, reflCol, metallic);
    }
    return diffuse;
}
#endif

//----------------------------
// Rim Lighting
//----------------------------
float3 GetRim(lighting l, float3 diffuse, float3 atten, float2 uv){
    UNITY_BRANCH
    if (_RenderMode == 1 || _RenderMode == 2){
        float rimDot = abs(dot(l.viewDir, l.normalDir));
        float rim = pow((1-rimDot), (1-_RimWidth) * 10);
        rim = smootherstep(_RimEdge, (1-_RimEdge), rim);
        float3 rimMask = tex2D(_RimMask, TRANSFORM_TEX(uv, _RimMask)).rgb;
        float mask = AverageRGB(rimMask);
        rim = lerp(rim, rim*mask, _RimMaskStr);
        float3 rimCol = tex2D(_RimTex, TRANSFORM_TEX(uv, _RimTex)).rgb * _RimCol.rgb;
        UNITY_BRANCH
        if (_UnlitRim != 1){
            rim *= l.worldBrightness;
            rim *= atten;
        }
        float noise = AverageRGB(GetNoiseRGB(uv, 1));
        noise = lerp(1, noise, _RimNoise);
        float interpolator = rim*_RimStrength*noise;
        UNITY_BRANCH
        switch(_RimBlending){
            case 0: diffuse = lerp(diffuse, rimCol, interpolator); break;
            case 1: diffuse += rimCol*interpolator; break;
            case 2: diffuse -= rimCol*interpolator; break;
            case 3: diffuse *= lerp(1, rimCol, interpolator); break;
            default: break;
        }
    }
    return diffuse;
}

//----------------------------
// PBR Workflows
//----------------------------
float4 GetSpecularWorkflow(float2 uv, float albedoAlpha){
    float4 spec = 0;
    #if defined(_SPECGLOSSMAP)
        UNITY_BRANCH
        if (_SourceAlpha == 1){
            spec.rgb = tex2D(_SpecGlossMap, uv).rgb;
            spec.a = albedoAlpha;
        }
        else 
            spec = tex2D(_SpecGlossMap, uv);
        spec.a *= _GlossMapScale;
    #else
        spec.rgb = _PBRSpecCol.rgb;
        UNITY_BRANCH
        if (_SourceAlpha == 1)
            spec.a = albedoAlpha * _GlossMapScale;
        else
            spec.a = _Glossiness;
    #endif
    return spec;
}

float3 GetMetallicWorkflow(float2 uv){
    float metallic = tex2D(_MetallicGlossMap, uv) * _Metallic;
    float roughness = tex2D(_SpecGlossMap, uv);
    if (_InvertRough == 1)
        roughness = 1-roughness;
    roughness *= _Glossiness;
    float smoothness = 1-roughness;
    roughness *= 1.7-0.7*roughness;
    return float3(metallic, roughness, smoothness);
}

//----------------------------
// Lighting Calculations
//----------------------------
#if defined(UNITY_PASS_FORWARDBASE) || defined(UNITY_PASS_FORWARDADD)
lighting GetLighting(v2f i, float3 atten){
    lighting o;
    #if defined(UNITY_PASS_FORWARDBASE)
        o.indirectCol = ShadeSH9(float4(0,0,0,1));
        o.lightCol = GetLightColor(o.indirectCol);
        o.worldBrightness = GetWorldBrightness(o.indirectCol);
    #else
        o.indirectCol = 0;
        o.lightCol = _LightColor0 * atten;
        o.worldBrightness = 0;
    #endif
    UNITY_BRANCH
    if (_RenderMode == 1 || _RenderMode == 2){
        o.ao = lerp(1, tex2D(_OcclusionMap, i.uv.xy).g, _OcclusionStrength);
        o.lightmask = 1;
        UNITY_BRANCH
        if(_RenderMode == 1)
            o.lightmask = lerp(1, UNITY_SAMPLE_TEX2D_SAMPLER(_LightMask, _MainTex, i.uv.xy), _LightMaskStr);
        o.lightDir = GetLightDir(i.worldPos, atten);
        o.viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos);
        o.halfVector = normalize(o.lightDir + o.viewDir);
        o.bumpMap = UnpackScaleNormal(tex2D(_BumpMap, i.uv.xy), _BumpScale);
        #if defined(_DETAIL_MULX2)
            o.detailNormal = UnpackScaleNormal(tex2D(_DetailNormalMap, i.uvd), _DetailNormalMapScale * GetDetailMask(i.uv.xy));
            o.tangentNormals = BlendNormals(o.bumpMap, o.detailNormal);
        #else
            o.tangentNormals = normalize(o.bumpMap);
        #endif
        o.binormal = i.binormal;
        o.normalDir = normalize(o.tangentNormals.x * i.tangent + o.tangentNormals.y * o.binormal + o.tangentNormals.z * i.normal);
        o.reflectionDir = 0;
        #if defined(UNITY_PASS_FORWARDBASE)
            o.reflectionDir = reflect(-o.viewDir, o.normalDir);
        #endif
        o.NdotL = DotClamped(o.normalDir, o.lightDir);
        o.fresnel = 1;
        UNITY_BRANCH
        if (_RenderMode == 1 && (_Reflections == 1 || _FakeSpec == 1)){
            float NdotV = 1-abs(dot(o.normalDir, o.viewDir));
            float radius = smoothstep(1-_FresnelFade, _IOR, pow(NdotV,3));
            o.fresnel = lerp(0, radius, _FresnelStr);
        }
    }
    else {
        o.NdotL = 0;
        o.lightmask = 0;
        o.ao = 0;
        o.fresnel = 0;
        o.lightDir = 0;
        o.viewDir = 0;
        o.halfVector = 0;
        o.bumpMap = 0;
        o.detailNormal = 0;
        o.tangentNormals = 0;
        o.binormal = 0;
        o.normalDir = 0;
        o.reflectionDir = 0;
    }
    return o;
}

UnityLight GetDirectLight(lighting l, float3 atten){
    UnityLight light;
    light.color = l.lightCol * atten;
    light.dir = l.lightDir;
    return light;
}

UnityIndirect GetIndirectLight(lighting l, v2f i, float roughness){
    UnityIndirect indirectLight;
    indirectLight.diffuse = max(0, ShadeSH9(float4(l.normalDir,1))) * l.ao;
    indirectLight.specular = 0;
    #if defined(UNITY_PASS_FORWARDBASE)
        indirectLight.specular = GetReflections(l, i, 0, roughness);
    #endif
    return indirectLight;
}

//----------------------------
// Parallax Mapping
//----------------------------
float2 GetParallaxOffset(v2f i){
    float2 uvOffset = 0;
    UNITY_BRANCH
    if (_March == 1){
        float stepSize = 0.1;
        float2 uvDelta = i.tangentViewDir.xy * (stepSize * _Parallax);
        float stepHeight = 1;
        float surfaceHeight = tex2D(_ParallaxMap, i.uv.xy);
        float2 prevUVOffset = uvOffset;
        float prevStepHeight = stepHeight;
        float prevSurfaceHeight = surfaceHeight;

        [unroll(10)]
        for (int j = 1; j < 10 && stepHeight > surfaceHeight; j++){
            prevUVOffset = uvOffset;
            prevStepHeight = stepHeight;
            prevSurfaceHeight = surfaceHeight;
            uvOffset -= uvDelta;
            stepHeight -= stepSize;
            surfaceHeight = tex2D(_ParallaxMap, i.uv.xy+uvOffset);
        }

        surfaceHeight = clamp((lerp(0.5, surfaceHeight, _HeightContrast)), 0, 10);
        float prevDifference = prevStepHeight - prevSurfaceHeight;
        float difference = surfaceHeight - stepHeight;
        float t = prevDifference / (prevDifference + difference);
        uvOffset = prevUVOffset - uvDelta * t;
    }
    else {
        float height = tex2D(_ParallaxMap, i.uv.xy);
        height = clamp((lerp(0.5, height, _HeightContrast)), 0, 10);
        height -= 0.5;
        height *= _Parallax;
        uvOffset = i.tangentViewDir.xy * height;
    }
    return uvOffset;
}

float3 GetTangentViewDir(v2f i){
    i.tangentViewDir = normalize(i.tangentViewDir);
    i.tangentViewDir.xy /= (i.tangentViewDir.z + 0.42);
    return i.tangentViewDir;
}
#endif
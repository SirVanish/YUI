#include "MUSFunctions.cginc"

#if defined (UNITY_PASS_FORWARDBASE) || defined(UNITY_PASS_FORWARDADD)

v2f vert (appdata v) {
    v2f o;
    UNITY_INITIALIZE_OUTPUT(v2f, o);
    o.pos = UnityObjectToClipPos(v.vertex);
    o.uv.xy = TRANSFORM_TEX(v.uv, _MainTex);
    o.uv.zw = 0;
    #if defined(UNITY_PASS_FORWARDBASE)
        o.uv.zw = TRANSFORM_TEX(v.uv, _EmissionMap);
        o.uv.z += (_Time.y*_XScroll);
        o.uv.w += (_Time.y*_YScroll);
    #endif
    o.normal = UnityObjectToWorldNormal(v.normal);
    o.worldPos = mul(unity_ObjectToWorld, v.vertex);
    o.tangent = float4(UnityObjectToWorldDir(v.tangent.xyz), v.tangent.w);
    o.binormal = cross(o.normal, o.tangent.xyz) * (v.tangent.w * unity_WorldTransformParams.w);
    o.uvd = TRANSFORM_TEX(v.uv, _DetailAlbedoMap);
    v.tangent.xyz = normalize(v.tangent.xyz);
    v.normal = normalize(v.normal);
    float3x3 objectToTangent = float3x3(v.tangent.xyz, (cross(v.normal, v.tangent.xyz) * v.tangent.w), v.normal);
    o.tangentViewDir = mul(objectToTangent, ObjSpaceViewDir(v.vertex));
    TRANSFER_SHADOW(o);
    UNITY_TRANSFER_FOG(o, o.pos);
    return o;
}

float4 frag (v2f i) : SV_Target {
    // Parallax Mapping
    #if defined(_PARALLAXMAP)
        i.tangentViewDir = GetTangentViewDir(i);
        float2 parallaxOffs = GetParallaxOffset(i);
        i.uv.xy += parallaxOffs;
        #if defined(UNITY_PASS_FORWARDBASE)
            i.uv.zw += parallaxOffs;
            i.normal.xy += parallaxOffs;
        #endif
        #if defined(_DETAIL_MULX2)
            i.uvd += parallaxOffs * (_DetailNormalMap_ST.xy / _MainTex_ST.xy);
        #endif
    #endif

    // Base color and lighting setup
    float4 albedo = GetAlbedo(i.uv.xy, i.uvd);
    float4 diffuse = albedo;
    #if defined(CUTOUT)
        UNITY_BRANCH
        if (_ATM != 1)
            clip(diffuse.a - _Cutoff);
    #endif
    #if defined(UNITY_PASS_FORWARDBASE)
        float3 emiss = GetEmission(i.uv);
    #endif
    UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos);
    lighting o = GetLighting(i, atten);
    float3 worldAtten = GetWorldAttenuation(o.NdotL, atten, i.uv.xy);
    #if defined(UNITY_PASS_FORWARDBASE)
        float3 lightColor = saturate(o.lightCol + o.indirectCol);
        UNITY_BRANCH
        if (_RenderMode == 0){
            diffuse = GetDiffuse(o, albedo, float3(1,1,1));
            diffuse.rgb = PreserveColor(diffuse.rgb, albedo.rgb,0,0,0);
        }
    #else
        UNITY_BRANCH
        if (_RenderMode == 0)
            diffuse = GetDiffuse(o, albedo, atten);
    #endif

    // Toon Shading
    UNITY_BRANCH
    if (_RenderMode == 1){
        float3 SSS = GetSSS(o, albedo.rgb, atten, i.uv);
        float3 reflections = 0;
        #if defined(UNITY_PASS_FORWARDBASE)
            float fresRough = lerp(1, o.fresnel, (1-_FresnelSmooth)*_FresnelStr);
            float roughness = 1-(_ReflSmooth*o.lightmask*fresRough);
            reflections = GetReflections(o, i, albedo.rgb, roughness);
        #endif
        float3 toonSpec = GetToonSpec(o, albedo.rgb, worldAtten);
        o.lightCol *= o.ao;
        diffuse = GetDiffuse(o, albedo, worldAtten);
        #if defined(UNITY_PASS_FORWARDBASE)
            diffuse.rgb = GetToonReflections(o, diffuse.rgb, albedo.rgb, reflections);
        #endif
        diffuse.rgb += toonSpec;
        diffuse.rgb += SSS;
        #if defined(UNITY_PASS_FORWARDBASE)
            diffuse.rgb = PreserveColor(diffuse.rgb, albedo.rgb, toonSpec, reflections, SSS);
        #endif
    }

    // PBR Shading
    UNITY_BRANCH
    if (_RenderMode == 2){
        float3 MRS = 0;
        float4 spec = 0;
        float r = 0;

        UNITY_BRANCH
        switch (_PBRWorkflow){
            case 0: MRS = GetMetallicWorkflow(i.uv.xy); spec = 0; break;
            case 1: spec = GetSpecularWorkflow(i.uv.xy, albedo.a); MRS = float3(0, 1-spec.a, spec.a); break;
            default: break;
        }
        #if defined(UNITY_PASS_FORWARDBASE)
            r = MRS.y;
        #endif

        UnityLight light = GetDirectLight(o, atten);
        UnityIndirect indirectLight = GetIndirectLight(o, i, r);

        UNITY_BRANCH
        switch (_PBRWorkflow){
            case 0: 
                albedo.rgb = DiffuseAndSpecularFromMetallic(albedo, MRS.x, specularTint, omr);
                diffuse.rgb = UNITY_BRDF_PBS(albedo, specularTint.rgb, omr, MRS.z, o.normalDir, o.viewDir, light, indirectLight).rgb;
                break;
            case 1: 
                albedo.rgb = EnergyConservationBetweenDiffuseAndSpecular(albedo, spec, omr);
                diffuse.rgb = UNITY_BRDF_PBS(albedo, spec.rgb, omr, MRS.z, o.normalDir, o.viewDir, light, indirectLight).rgb;
                break;
            default: break;
        }
    }

    diffuse.rgb = GetRim(o, diffuse.rgb, atten, i.uv.xy);
    #if defined(UNITY_PASS_FORWARDBASE)
        diffuse.rgb += GetLREmission(o.worldBrightness * worldAtten, emiss);
    #endif
    
    UNITY_APPLY_FOG(i.fogCoord, diffuse);
    return diffuse;
}
#endif

#if defined(UNITY_PASS_SHADOWCASTER)
v2f vert (appdata v) {
    v2f o;
    o.uv = TRANSFORM_TEX(v.uv, _MainTex);
    TRANSFER_SHADOW_CASTER(o)
    return o;
}

float4 frag(v2f i) : SV_Target {
    #if defined(CUTOUT)
        UNITY_BRANCH
        if (_ATM != 1)
            clip(UNITY_SAMPLE_TEX2D(_MainTex, i.uv).a - _Cutoff);
    #endif
    SHADOW_CASTER_FRAGMENT(i);
}
#endif

#if defined(OUTLINE)
v2f vert (appdata v){
    v2f o;
    v.vertex.xyz += _OutlineThicc*v.normal*0.01;
    o.pos = UnityObjectToClipPos(v.vertex);
    o.uv = TRANSFORM_TEX(v.uv, _MainTex);
    o.color = _OutlineCol;
    #if defined(TRANSPARENT)
        o.color.a *= _Opacity;
    #endif
    UNITY_TRANSFER_FOG(o, o.pos)
    return o;
}

float4 frag(v2f i) : SV_Target {
    UNITY_BRANCH
    if (_Outline == 0)
        clip(-1);

    UNITY_BRANCH
    if (_Outline == 1){
        #if defined(CUTOUT)
            UNITY_BRANCH
            if (_ATM != 1)
                clip(i.color.a - _Cutoff);
        #endif
        return i.color;
    }

    UNITY_BRANCH
    if (_Outline == 2){
        float4 col = UNITY_SAMPLE_TEX2D(_MainTex, i.uv) * i.color;
        #if defined(CUTOUT)
            UNITY_BRANCH
            if (_ATM != 1)
                clip(col.a - _Cutoff);
        #endif
        return col;
    }
    
    return float4(1,0,1,1);
}
#endif
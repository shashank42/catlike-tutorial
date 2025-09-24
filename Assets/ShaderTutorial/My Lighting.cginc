#if !defined(MY_LIGHTING_INCLUDED)
#define MY_LIGHTING_INCLUDED

#include "AutoLight.cginc"
#include "UnityPBSLighting.cginc"

float4 _Tint;
sampler2D _MainTex, _DetailTex;
float4 _MainTex_ST, _DetailTex_ST;
float _Smoothness;
float _Metallic;
sampler2D _NormalMap, _DetailNormalMap;
float _BumpScale, _DetailBumpScale;

struct VertexData
{
    float4 position : POSITION;
    float3 normal : NORMAL;
    float4 tangent : TANGENT;
    float2 uv : TEXCOORD0;
};

struct Interpolators
{
    float4 position : SV_POSITION;
    float4 uv : TEXCOORD0;
    float3 normal : TEXCOORD1;
   
    #if defined(BINORMAL_PER_FRAGMENT)
        float4 tangent : TEXCOORD2;
    #else
        float3 tangent : TEXCOORD2;
        float3 binormal : TEXCOORD3;
    #endif
    float3 worldPos : TEXCOORD4;

    #if defined(VERTEXLIGHT_ON)
    float3 vertexLightColor : TEXCOORD5;
    #endif
};

void ComputeVertexLightColor (inout Interpolators i) {
    #if defined(VERTEXLIGHT_ON)
        // float3 lightPos = float3(
        //     unity_4LightPosX0.x, unity_4LightPosY0.x, unity_4LightPosZ0.x
        // );
        // float3 lightVec = lightPos - i.worldPos;
        // float3 lightDir = normalize(lightVec);
        // float ndotl = DotClamped(i.normal, lightDir);
        // float attenuation = 1 /
        //     (1 + dot(lightVec, lightVec) * unity_4LightAtten0.x);
        // i.vertexLightColor = unity_LightColor[0].rgb;
        i.vertexLightColor = Shade4PointLights(
            unity_4LightPosX0, unity_4LightPosY0, unity_4LightPosZ0,
            unity_LightColor[0].rgb, unity_LightColor[1].rgb,
            unity_LightColor[2].rgb, unity_LightColor[3].rgb,
            unity_4LightAtten0, i.worldPos, i.normal
        );
    #endif
}

float3 CreateBinormal (float3 normal, float3 tangent, float binormalSign) {
    return cross(normal, tangent.xyz) *
        (binormalSign * unity_WorldTransformParams.w);
}

Interpolators MyVertexProgram(
    VertexData v)
{
    Interpolators i;
    i.position = UnityObjectToClipPos(v.position);
    i.uv.xy = TRANSFORM_TEX(v.uv, _MainTex);
    i.uv.zw = TRANSFORM_TEX(v.uv, _DetailTex);
    i.worldPos = mul(unity_ObjectToWorld, v.position);
    i.normal = UnityObjectToWorldNormal(v.normal);
    #if defined(BINORMAL_PER_FRAGMENT)
        i.tangent = float4(UnityObjectToWorldDir(v.tangent.xyz), v.tangent.w);
    #else
        i.tangent = UnityObjectToWorldDir(v.tangent.xyz);
        i.binormal = CreateBinormal(i.normal, i.tangent, v.tangent.w);
    #endif
    // i.normal = mul(transpose((float3x3)unity_WorldToObject), v.normal);
    // i.normal = normalize(i.normal);
    
    ComputeVertexLightColor(i);
    return i;
}

UnityIndirect CreateIndirectLight (Interpolators i) {
    UnityIndirect indirectLight;
    indirectLight.diffuse = 0;
    indirectLight.specular = 0;

    #if defined(VERTEXLIGHT_ON)
        indirectLight.diffuse = i.vertexLightColor;
    #endif
    #if defined(FORWARD_BASE_PASS)
        indirectLight.diffuse += max(0, ShadeSH9(float4(i.normal, 1)));
    #endif
    return indirectLight;
}

UnityLight CreateLight(Interpolators i) {
    UnityLight light;
    #if defined(POINT) || defined(SPOT) || defined(POINT_COOKIE) 
    light.dir = normalize(_WorldSpaceLightPos0.xyz - i.worldPos);
    #else
    light.dir = _WorldSpaceLightPos0.xyz;
    #endif
    UNITY_LIGHT_ATTENUATION(attenuation, 0, i.worldPos);
    light.color = _LightColor0.rgb * attenuation;
    light.ndotl = DotClamped(i.normal, light.dir);
    return light;
}

void InitializeFragmentNormal(inout Interpolators i) {
    // i.normal.xy = tex2D(_NormalMap, i.uv).wy * 2 - 1;
    // i.normal.xy *= _BumpScale;
    // i.normal.z = sqrt(1 - saturate(dot(i.normal.xy, i.normal.xy)));
    float3 mainNormal = UnpackScaleNormal(tex2D(_NormalMap, i.uv.xy), _BumpScale);
    float3 detailNormal = UnpackScaleNormal(tex2D(_DetailNormalMap, i.uv.zw), _DetailBumpScale);
    // i.normal =
    //     float3(mainNormal.xy / mainNormal.z + detailNormal.xy / detailNormal.z, 1);
    // i.normal =
    //     float3(mainNormal.xy + detailNormal.xy, mainNormal.z * detailNormal.z);
    float3 tangentSpaceNormal = BlendNormals(mainNormal, detailNormal);
    tangentSpaceNormal = tangentSpaceNormal.xzy;
    #if defined(BINORMAL_PER_FRAGMENT)
        float3 binormal = CreateBinormal(i.normal, i.tangent.xyz, i.tangent.w);
    #else
        float3 binormal = i.binormal;
    #endif
    i.normal = normalize(
        tangentSpaceNormal.x * i.tangent +
        tangentSpaceNormal.y * binormal +
        tangentSpaceNormal.z * i.normal
    );
}

float4 MyFragmentProgram(
    Interpolators i): SV_TARGET
{
    InitializeFragmentNormal(i);
    float3 viewDir = normalize(_WorldSpaceCameraPos - i.worldPos);
    // float3 specular = _SpecularTint.rgb * lightColor *  pow(
    // 	DotClamped(halfVector, i.normal),
    // 	_Smoothness * 100
    // );
    float3 albedo = tex2D(_MainTex, i.uv.xy).rgb * _Tint.rgb;
    albedo *= tex2D(_DetailTex, i.uv.zw) * unity_ColorSpaceDouble;
    // albedo *= tex2D(_HeightMap, i.uv);
    float3 specularTint; // = albedo * _Metallic;
    float oneMinusReflectivity; // = 1 - _Metallic;
    // float3 specular = lightColor *  pow(
    // 	DotClamped(halfVector, i.normal),
    // 	_Smoothness * 100
    // );

    // albedo *= 1 - max(_SpecularTint.r, max(_SpecularTint.g, _SpecularTint.b));
    albedo = DiffuseAndSpecularFromMetallic(
        albedo, _Metallic, specularTint, oneMinusReflectivity
    );
    // float3 diffuse = albedo * lightColor * DotClamped(lightDir, i.normal);
    // half4 BRDF1_Unity_PBS (half3 diffColor, half3 specColor, half oneMinusReflectivity, half smoothness,
    //     float3 normal, float3 viewDir, UnityLight light, UnityIndirect gi);


    return UNITY_BRDF_PBS(albedo, specularTint, oneMinusReflectivity, _Smoothness, i.normal, viewDir, CreateLight(i),
                          CreateIndirectLight(i));

    return DotClamped(float3(0, 1, 0), i.normal);
    i.normal = normalize(i.normal);
    return float4(i.normal * 0.5 + 0.5, 1);
    return tex2D(_MainTex, i.uv) * _Tint;;
}

#endif
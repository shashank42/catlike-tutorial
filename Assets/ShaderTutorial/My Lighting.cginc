#if !defined(MY_LIGHTING_INCLUDED)
#define MY_LIGHTING_INCLUDED

#include "AutoLight.cginc"
#include "UnityPBSLighting.cginc"

float4 _Tint;
sampler2D _MainTex;
float4 _MainTex_ST;
float _Smoothness;
float _Metallic;
sampler2D _HeightMap;
float4 _HeightMap_TexelSize;

struct VertexData
{
    float4 position : POSITION;
    float3 normal : NORMAL;
    float2 uv : TEXCOORD0;
};

struct Interpolators
{
    float4 position : SV_POSITION;
    float2 uv : TEXCOORD0;
    float3 normal : TEXCOORD1;
    float3 worldPos : TEXCOORD2;
    #if defined(VERTEXLIGHT_ON)
        float3 vertexLightColor : TEXCOORD3;
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

Interpolators MyVertexProgram(
    VertexData v)
{
    Interpolators i;
    i.position = UnityObjectToClipPos(v.position);
    i.uv = TRANSFORM_TEX(v.uv, _MainTex);
    i.worldPos = mul(unity_ObjectToWorld, v.position);
    // i.normal = mul(transpose((float3x3)unity_WorldToObject), v.normal);
    // i.normal = normalize(i.normal);
    i.normal = UnityObjectToWorldNormal(v.normal);
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
    float2 du = float2(_HeightMap_TexelSize.x * 0.5, 0);
    float u1 = tex2D(_HeightMap, i.uv - du);
    float u2 = tex2D(_HeightMap, i.uv + du);

    float2 dv = float2(0, _HeightMap_TexelSize.y * 0.5);
    float v1 = tex2D(_HeightMap, i.uv - dv);
    float v2 = tex2D(_HeightMap, i.uv + dv);

    i.normal = float3(u1 - u2, 1, v1 - v2);
    i.normal = normalize(i.normal);
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
    float3 albedo = tex2D(_MainTex, i.uv).rgb * _Tint.rgb;
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
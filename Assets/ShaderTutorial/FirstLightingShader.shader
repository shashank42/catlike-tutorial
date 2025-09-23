// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Custom/My First Lighting Shader" {
	
	Properties {
		_Tint ("Tint", Color) = (1, 1, 1, 1)
		_MainTex ("Texture", 2D) = "white" {}
		[Gamma] _Metallic ("Metallic", Range(0, 1)) = 0
		_Smoothness ("Smoothness", Range(0, 1)) = 0.5
	}
	
	SubShader {
		Pass {
			Tags {
				"LightMode" = "ForwardBase"
			}
			CGPROGRAM
				#pragma vertex MyVertexProgram
				#pragma fragment MyFragmentProgram
				
				#include "UnityStandardBRDF.cginc"
				#include "UnityStandardUtils.cginc"
				
				float4 _Tint;
				sampler2D _MainTex;
				float4 _MainTex_ST;
				float _Smoothness;
				float _Metallic;

				struct VertexData {
					float4 position : POSITION;
					float3 normal : NORMAL;
					float2 uv : TEXCOORD0;
				};

				struct Interpolators {
					float4 position : SV_POSITION;
					float2 uv : TEXCOORD0;
					float3 normal : TEXCOORD1;
					float3 worldPos : TEXCOORD2;
				};


				Interpolators MyVertexProgram (
					VertexData v) {
						Interpolators i;
					i.position = UnityObjectToClipPos(v.position);
					i.uv = TRANSFORM_TEX(v.uv, _MainTex);
					i.worldPos = mul(unity_ObjectToWorld, v.position);
					// i.normal = mul(transpose((float3x3)unity_WorldToObject), v.normal);
					// i.normal = normalize(i.normal);
					i.normal = UnityObjectToWorldNormal(v.normal);
					return i;
				}

				float4 MyFragmentProgram (
					Interpolators i): SV_TARGET {
						i.normal = normalize(i.normal);
						float3 lightDir = _WorldSpaceLightPos0.xyz;
						float3 viewDir = normalize(_WorldSpaceCameraPos - i.worldPos);
						float3 halfVector = normalize(lightDir + viewDir);
						float3 lightColor = _LightColor0.rgb;
						// float3 specular = _SpecularTint.rgb * lightColor *  pow(
						// 	DotClamped(halfVector, i.normal),
						// 	_Smoothness * 100
						// );
						float3 albedo = tex2D(_MainTex, i.uv).rgb * _Tint.rgb;
						float3 specularTint; // = albedo * _Metallic;
						float oneMinusReflectivity; // = 1 - _Metallic;
						float3 specular = lightColor *  pow(
							DotClamped(halfVector, i.normal),
							_Smoothness * 100
						);
						
						// albedo *= 1 - max(_SpecularTint.r, max(_SpecularTint.g, _SpecularTint.b));
						albedo = DiffuseAndSpecularFromMetallic(
							albedo, _Metallic, specularTint, oneMinusReflectivity
						);
						float3 diffuse = albedo * lightColor * DotClamped(lightDir, i.normal);
						return float4(diffuse + specular, 1);
						return DotClamped(lightDir, i.normal);
						return DotClamped(float3(0, 1, 0), i.normal);
						i.normal = normalize(i.normal);
						return float4(i.normal * 0.5 + 0.5, 1);
					return tex2D(_MainTex, i.uv)  * _Tint;;
				}
			ENDCG
		}
	}
}
Shader "Fractal/Fractal Surface GPU" {
	
	Properties {
		_BaseColor ("Base Color", Color) = (1.0, 1.0, 1.0, 1.0)
		_Smoothness ("Smoothness", Range(0,1)) = 0.5
	}
	
	SubShader
	{
		CGPROGRAM
		#pragma surface ConfigureSurface Standard fullforwardshadows addshadow
		#pragma instancing_options assumeuniformscaling procedural:ConfigureProcedural
		#pragma editor_sync_compilation
		#pragma target 4.5

		#include "FractalGPU.hlsl"

		struct Input {
			float3 worldPos;
		};
		float _Smoothness;
		float4 _BaseColor;

		void ConfigureSurface (Input input, inout SurfaceOutputStandard surface)
		{
			surface.Albedo = saturate(input.worldPos * 0.5 + 0.5);
			// surface.Albedo = _BaseColor.rgb;
			surface.Smoothness = _Smoothness;
		}
		ENDCG
	}
	
	FallBack "Diffuse"
}
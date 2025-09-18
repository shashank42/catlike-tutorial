using System.Collections.Generic;
using UnityEngine;
using static UnityEngine.Mathf;

public static class FunctionLibrary
{
    public enum FunctionType
    {
        Wave,
        MultiWave,
        Ripple,
        Sphere,
        Torus
    }
    
    public static Vector3 Wave (float u, float v, float t) {
        Vector3 p;
        p.x = u;
        p.y = Sin(PI * (u + v + t));
        p.z = v;
        return p;
    }
    
    public static Vector3 MultiWave (float u, float v, float t) {
        Vector3 p;
        p.x = u;
        p.y = Sin(PI * (u + 0.5f * t));
        p.y += 0.5f * Sin(2f * PI * (v + t));
        p.y += Sin(PI * (u + v + 0.25f * t));
        p.y *= 1f / 2.5f;
        p.z = v;
        return p;
    }

    public static Vector3 Ripple (float u, float v, float t) {
        float d = Sqrt(u * u + v * v);
        Vector3 p;
        p.x = u;
        p.y = Sin(PI * (4f * d - t));
        p.y /= 1f + 10f * d;
        p.z = v;
        return p;
    }
    
    // public static Vector3 Sphere (float u, float v, float t) {
    //     Vector3 p;
    //     var r = 1;
    //     p.x = r * Sin((u + 1.0f) * 2.0f * PI) * Cos((v + 1.0f) * PI);
    //     p.y = r * Sin((u + 1.0f) * 2.0f * PI) * Sin((v + 1.0f) * PI);
    //     p.z = Cos((u + 1.0f) * 2.0f * PI);
    //     return p;
    // }
    
    // public static Vector3 Sphere (float u, float v, float t) {
    //     Vector3 p;
    //     var r = 1;
    //     p.x = r * Cos((u + 1.0f) * PI) * Cos(v * PI / 2.0f);
    //     p.y = r * Cos((u + 1.0f) * PI) * Sin(v * PI / 2.0f);
    //     p.z = r * Sin((u + 1.0f) * PI);
    //     return p;
    // }
    
    public static Vector3 Sphere (float u, float v, float t) {
        Vector3 p;
        // var r = 0.5f + 0.5f * Sin(PI * t);
        // float r = 0.9f + 0.1f * Sin(8f * PI * u);
        // float r = 0.9f + 0.1f * Sin(PI * (6f * u + 4f * v + t));
        float r = 0.9f + 0.1f * Sin(PI * (12.0f * u + 8.0f * v + t));
        var s = r * Cos(PI * v / 2.0f);
        p.x = s * Sin(u * PI);
        p.y = r * Sin(PI * v / 2.0f);
        p.z = s * Cos(u * PI);
        return p;
    }
    
    public static Vector3 Torus (float u, float v, float t) {
        float r1 = 0.7f + 0.1f * Sin(PI * (8.0f * u + 0.5f * t));
        float r2 = 0.15f + 0.05f * Sin(PI * (16.0f * u + 8.0f * v + 3.0f * t));
        float s = r1 + r2 * Cos(PI * v);
        Vector3 p;
        p.x = s * Sin(PI * u);
        p.y = r2 * Sin(PI * v);
        p.z = s * Cos(PI * u);
        return p;
    }
    
    public delegate Vector3 Function (float u, float v, float t);

    private static Dictionary<FunctionType, Function> Functionss = new Dictionary<FunctionType, Function>
    {
        { FunctionType.Wave, Wave},
        { FunctionType.MultiWave , MultiWave},
        {FunctionType.Ripple, Ripple},
        {FunctionType.Sphere, Sphere},
        {FunctionType.Torus, Torus},
    };
    
    public static int FunctionCount => Functionss.Count;

    public static Function GetFunction (FunctionType func) {
        Functionss.TryGetValue(func, out Function function);
        return function;
    }
    
    public static FunctionType GetNextFunctionName (FunctionType name) {
        if ((int)name < Functionss.Count - 1) {
            return name + 1;
        }
        else {
            return 0;
        }
    }
    
    public static FunctionType GetRandomFunctionNameOtherThan (FunctionType name) {
        var choice = (FunctionType)Random.Range(1, Functionss.Count);
        return choice == name ? 0 : choice;
    }

    public static Vector3 Morph(
        float u, float v, float t, Function from, Function to, float progress
    )
    {
        return Vector3.LerpUnclamped(
            from(u, v, t), to(u, v, t), SmoothStep(0f, 1f, progress)
        );
    }
}

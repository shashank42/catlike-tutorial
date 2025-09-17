using System.Collections.Generic;
using UnityEngine;
using static UnityEngine.Mathf;

public static class FunctionLibrary
{
    public enum FunctionType
    {
        Wave,
        MultiWave,
        Ripple
    }
    
    public static float Wave (float x, float z,  float t) {
        return Sin(PI * (x + z + t));
    }
    
    public static float MultiWave (float x, float z,  float t) {
        float y = Sin(PI * (x + 0.5f * t));
        y += 0.5f * Sin(2f * PI * (z + t));
        y += Sin(PI * (x + z + 0.25f * t));
        return y * (1f / 2.5f);
    }
    
    public static float Ripple (float x, float z,  float t) {
        float d = Sqrt(x * x + z * z);
        float y = Sin(PI * (4f * d - t));
        return y / (1f + 10f * d);
    }
    
    public delegate float Function (float x, float z, float t);
    
    static Dictionary<FunctionType, Function> functions = new Dictionary<FunctionType, Function>
    {
        { FunctionType.Wave, Wave},
        { FunctionType.MultiWave , MultiWave},
        {FunctionType.Ripple, Ripple}
    };
	
    public static Function GetFunction (FunctionType func) {
        functions.TryGetValue(func, out Function function);
        return function;
    }
}

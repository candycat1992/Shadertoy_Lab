Shader "Shadertoy/Water Color" { // https://www.shadertoy.com/view/XdSSWd
	Properties {
		iMouse ("Mouse Pos", Vector) = (100,100,0,0)
		iChannel0("iChannel0", 2D) = "white" {}  
		iChannelResolution0 ("iChannelResolution0", Vector) = (100,100,0,0)
	}
	
	CGINCLUDE
	
	#include "UnityCG.cginc"
	#pragma target 3.0  
	
	#define vec2 float2
  	#define vec3 float3
  	#define vec4 float4
  	#define mat2 float2x2
  	#define iGlobalTime _Time.y
  	#define mod fmod
  	#define mix lerp
  	#define atan atan2
  	#define fract frac 
  	#define texture2D tex2D
	// 屏幕的尺寸
  	#define iResolution _ScreenParams
  	// 屏幕中的坐标，以pixel为单位
  	#define gl_FragCoord ((_iParam.scrPos.xy/_iParam.scrPos.w)*_ScreenParams.xy)  
    
    fixed4 iMouse;
  	sampler2D iChannel0;
  	fixed4 iChannelResolution0;
  		
    struct v2f {      
        float4 pos : SV_POSITION;      
    	float2 uv : TEXCOORD0;
    	float4 scrPos : TEXCOORD1; 
     };    
    
     v2f vert(appdata_base v) {    
         v2f o; 
         o.uv = v.texcoord;  
    	o.pos = mul (UNITY_MATRIX_MVP, v.vertex);
    	o.scrPos = ComputeScreenPos(o.pos); 
         
         return o;    
     }
     
     vec4 main(vec2 uv);
        
     fixed4 frag(v2f _iParam) : COLOR0 { 
     	vec2 fragCoord = gl_FragCoord;
        return main(gl_FragCoord);
     } 
 	
 	// Table of pigments 
	// from Computer-Generated Watercolor. Cassidy et al.
	// K is absorption. S is scattering
	// a
	#define K_QuinacridoneRose vec3(0.22, 1.47, 0.57)
	#define S_QuinacridoneRose vec3(0.05, 0.003, 0.03)
	// b
	#define K_IndianRed vec3(0.46, 1.07, 1.50)
	#define S_IndianRed vec3(1.28, 0.38, 0.21)
	// c
	#define K_CadmiumYellow vec3(0.10, 0.36, 3.45)
	#define S_CadmiumYellow vec3(0.97, 0.65, 0.007)
	// d
	#define K_HookersGreen vec3(1.62, 0.61, 1.64)
	#define S_HookersGreen vec3(0.01, 0.012, 0.003)
	// e
	#define K_CeruleanBlue vec3(1.52, 0.32, 0.25)
	#define S_CeruleanBlue vec3(0.06, 0.26, 0.40)
	// f
	#define K_BurntUmber vec3(0.74, 1.54, 2.10)
	#define S_BurntUmber vec3(0.09, 0.09, 0.004)
	// g
	#define K_CadmiumRed vec3(0.14, 1.08, 1.68)
	#define S_CadmiumRed vec3(0.77, 0.015, 0.018)
	// h
	#define K_BrilliantOrange vec3(0.13, 0.81, 3.45)
	#define S_BrilliantOrange vec3(0.009, 0.007, 0.01)
	// i
	#define K_HansaYellow vec3(0.06, 0.21, 1.78)
	#define S_HansaYellow vec3(0.50, 0.88, 0.009)
	// j
	#define K_PhthaloGreen vec3(1.55, 0.47, 0.63)
	#define S_PhthaloGreen vec3(0.01, 0.05, 0.035)
	// k
	#define K_FrenchUltramarine vec3(0.86, 0.86, 0.06)
	#define S_FrenchUltramarine vec3(0.005, 0.005, 0.09)
	// l
	#define K_InterferenceLilac vec3(0.08, 0.11, 0.07)
	#define S_InterferenceLilac vec3(1.25, 0.42, 1.43)
	

	// Math functions not available in webgl
	vec3 my_cosh(vec3 val) { vec3 e = exp(val); return (e + vec3(1.0, 1.0, 1.0) / e) / vec3(2.0, 2.0, 2.0); }
	vec3 my_tanh(vec3 val) { vec3 e = exp(val); return (e - vec3(1.0, 1.0, 1.0) / e) / (e + vec3(1.0, 1.0, 1.0) / e); }
	vec3 my_sinh(vec3 val) { vec3 e = exp(val); return (e - vec3(1.0, 1.0, 1.0) / e) / vec3(2.0, 2.0, 2.0); }

	// Kubelka-Munk reflectance and transmitance model
	void KM(vec3 K, vec3 S, float x, out vec3 R, out vec3 T) {
	    vec3 a = (K + S) / S;
	    vec3 b = sqrt(a * a - vec3(1.0, 1.0, 1.0));
	    vec3 bSx = b * S * vec3(x, x, x);
	    vec3 sinh_bSx = my_sinh(bSx);
	    vec3 c = a * sinh_bSx + b * my_cosh(bSx);
	    
	    R = sinh_bSx / c;
	    T = b / c;
	}
	
	// Kubelka-Munk model for optical compositing of layers
	void CompositeLayers(vec3 R0, vec3 T0, vec3 R1, vec3 T1, out vec3 R, out vec3 T) {
		vec3 tmp = vec3(1.0, 1.0, 1.0) / (vec3(1.0, 1.0, 1.0) - R0 * R1);
	    R = R0 + T0 * T0 * R1 * tmp;
	    T = T0 * T1 * tmp;
	}

	// Simulate edge darkening effect
	// Input: dist < 0 outer area, dist > 0 inner area
	float BrushEffect(float dist, float x_avg, float x_var) {
		// Only when abs(dist) < 1.0/10.0, x > 0.0
		// Means that the edges have more thickness of pigments
	    float x = max(0.0, 1.0 - 10.0 * abs(dist));	
	   	x *= x;
	    x *= x;
	    return (x_avg + x_var * x) * smoothstep(-0.01, 0.002, dist);
	}
	
	// Simple 2d noise fbm (Fractional Brownian Motion) with 3 octaves
	float Noise2d(vec2 p) {
	    float t = texture2D(iChannel0, p).x;
	    t += 0.5 * texture2D(iChannel0, p * 2.0).x;
	    t += 0.25 * texture2D(iChannel0, p * 4.0).x;
	    return t / 1.75;
	}
	
	float DistanceCircle(vec2 pos, vec2 center, float radius) {
		return 1.0 - distance(pos, center) / radius;
	}
	
	float DistanceLine(vec2 pos, vec2 point1, vec2 point2, float halfwidth) {
    	vec2 dir0 = point2 - point1;
		vec2 dir1 = pos - point1;
		vec2 dir2 = dir0 * dot(dir0, dir1)/dot(dir0, dir0);
		vec2 dir3 = dir1 - dir2;
		float d = length(dir3);
    	
    	return 1 - d / halfwidth;
    }
    
    float DistanceSegment(vec2 pos, vec2 point0, vec2 point1, float halfwidth) {
	    vec2 dir0 = point1 - point0;
	    vec2 dir1 = pos - point0;
	    float h = clamp(dot(dir0, dir1)/dot(dir0, dir0), 0.0, 1.0);
	    float d = length(dir1 - dir0 * h);
	    
	    return 1 - d / halfwidth;
	}
    
    float DistanceMountain(vec2 pos, float height) {
	    return height + 0.04 * (sin(pos.x * 18.0 + 2.0) + sin(sin(pos.x * 2.0) * 7.0)) - pos.y;
    }
		
	vec4 main(vec2 fragCoord) {
		vec2 uv = fragCoord.xy / iResolution.xy;
    
	    vec3 R0, T0, R1, T1;
	    
	    vec2 pos;
	    float dist;
	    float noise;
	    
	    /// 
	    /// First Scene
	    ///
	    
//	    // Background
//		noise = Noise2d(uv * vec2(1.0, 1.0));
//	    float background = 0.1 + 0.1 * noise;
//	    KM(K_CeruleanBlue, S_CeruleanBlue, background, R0, T0);
//	    
//		noise = 0.04 * Noise2d(uv * vec2(0.1, 0.1));
//	    pos = uv + vec2(noise, noise);
//	    dist = DistanceMountain(pos, 0.5);
//		noise = 0.3 * Noise2d(uv * vec2(0.1, 0.1));
//	    float mountains = BrushEffect(dist, 0.2, noise);
//		noise = Noise2d(uv * vec2(0.2, 0.2));
//	    mountains *= 0.45 + 0.55 * noise;
//	    KM(K_HookersGreen, S_HookersGreen, mountains, R1, T1);
//	    CompositeLayers(R0, T0, R1, T1, R0, T0);
//	    
//		noise = 0.02 * Noise2d(uv * vec2(0.1, 0.1));
//	    pos = uv * vec2(1.0, iResolution.y / iResolution.x) + vec2(noise, noise);
//	    dist = DistanceCircle(pos, vec2(0.2, 0.55), 0.08);
//	    float circle = BrushEffect(dist, 0.2, 0.2);
//	    KM(K_HansaYellow, S_HansaYellow, circle, R1, T1);
//	    CompositeLayers(R0, T0, R1, T1, R0, T0);
	    
	    /// 
	    /// Second Scene
	    ///
	    
	    // Background
	    noise = Noise2d(uv * vec2(1.0, 1.0));
	    float background = 0.1 + 0.2 * noise;
	    KM(K_HansaYellow, S_HansaYellow, background, R0, T0);
	    
	    // Edge roughness: 0.04
	    noise = 0.04 * Noise2d(uv * vec2(0.1, 0.1));
	    pos = uv * vec2(1.0, iResolution.y / iResolution.x) + vec2(noise, noise);
	    dist = DistanceCircle(pos, vec2(0.5, 0.5), 0.15);
	    // Average thickness: 0.2, edge varing thickness: 0.2
	    float circle = BrushEffect(dist, 0.2, 0.2);
	    // Granulation: 0.85
	    noise = Noise2d(uv * vec2(0.2, 0.2));
	    circle *= 0.15 + 0.85 * noise;
	    KM(K_CadmiumRed, S_CadmiumRed, circle, R1, T1);
	    CompositeLayers(R0, T0, R1, T1, R0, T0);
	    
	    // Edge roughness: 0.03
	    noise = 0.03 * Noise2d(uv * vec2(0.1, 0.1));
	    pos = uv * vec2(1.0, iResolution.y / iResolution.x) + vec2(noise, noise);
	    dist = DistanceCircle(pos, vec2(0.4, 0.3), 0.15);
	    // Average thickness: 0.3, edge varing thickness: 0.1
	    circle = BrushEffect(dist, 0.3, 0.1);
	    // Granulation: 0.65
	    noise = Noise2d(uv * vec2(0.2, 0.2));
	    circle *= 0.35 + 0.65 * noise;
	    KM(K_HookersGreen, S_HookersGreen, circle, R1, T1);
	    CompositeLayers(R0, T0, R1, T1, R0, T0);
	    
	    // Edge roughness: 0.02
	    noise = 0.02 * Noise2d(uv * vec2(0.1, 0.1));
	    pos = uv * vec2(1.0, iResolution.y / iResolution.x) + vec2(noise, noise);
	    dist = DistanceCircle(pos, vec2(0.6, 0.3), 0.15);
	    // Average thickness: 0.3, edge varing thickness: 0.2
	    circle = BrushEffect(dist, 0.3, 0.2);
	    // Granulation: 0.45
	    noise = Noise2d(uv * vec2(0.2, 0.2));
	    circle *= 0.55 + 0.45 * noise;
	    KM(K_FrenchUltramarine, S_FrenchUltramarine, circle, R1, T1);
	    CompositeLayers(R0, T0, R1, T1, R0, T0);
	    
	    // Opaque paints, e.g. Indian Red
	    noise = 0.02 * Noise2d(uv * vec2(0.3, 0.3));
	    pos = uv * vec2(1.0, iResolution.y / iResolution.x) + vec2(noise, noise);
	    dist = DistanceSegment(pos, vec2(0.2, 0.1), vec2(0.4, 0.25), 0.03);
	    float stroke = BrushEffect(dist, 0.2, 0.1);
	    KM(K_IndianRed, S_IndianRed, stroke, R1, T1);
	    CompositeLayers(R0, T0, R1, T1, R0, T0);
	    
	    // Transparent paints, e.g. Quinacridone Rose
	    noise = 0.02 * Noise2d(uv * vec2(0.2, 0.2));
	    pos = uv * vec2(1.0, iResolution.y / iResolution.x) + vec2(noise, noise);
	    dist = DistanceSegment(pos, vec2(0.2, 0.5), vec2(0.4, 0.55), 0.03);
	    stroke = BrushEffect(dist, 0.2, 0.1);
	    KM(K_QuinacridoneRose, S_QuinacridoneRose, stroke, R1, T1);
	    CompositeLayers(R0, T0, R1, T1, R0, T0);
	    
	    // Interference paints, e.g. Interference Lilac
	    noise = 0.02 * Noise2d(uv * vec2(0.1, 0.2));
	    pos = uv * vec2(1.0, iResolution.y / iResolution.x) + vec2(noise, noise);
	    dist = DistanceSegment(pos, vec2(0.6, 0.55), vec2(0.8, 0.4), 0.03);
	    stroke = BrushEffect(dist, 0.2, 0.1);
	    KM(K_InterferenceLilac, S_InterferenceLilac, stroke, R1, T1);
	    CompositeLayers(R0, T0, R1, T1, R0, T0);

		return vec4(R0 + T0, 1.0);
	}
	
	ENDCG
	
	SubShader {
		Pass {
			CGPROGRAM
			
			#pragma vertex vert
			#pragma fragment frag
			#pragma fragmentoption ARB_precision_hint_fastest   
			
			ENDCG
		}
	} 
	FallBack "Diffuse"
}

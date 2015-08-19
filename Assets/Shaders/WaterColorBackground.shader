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
	vec3 my_cosh(vec3 val) { vec3 e = exp(val); return (e + vec3(1.0) / e) / vec3(2.0); }
	vec3 my_tanh(vec3 val) { vec3 e = exp(val); return (e - vec3(1.0) / e) / (e + vec3(1.0) / e); }
	vec3 my_sinh(vec3 val) { vec3 e = exp(val); return (e - vec3(1.0) / e) / vec3(2.0); }

	// Kubelka-Munk reflectance and transmitance model
	void KM(vec3 k, vec3 s, float h, out vec3 refl, out vec3 trans)
	{
	    vec3 a = (k + s) / s;
	    vec3 b = sqrt(a * a - vec3(1.0));
	    vec3 bsh = b * s * vec3(h);
	    vec3 sinh_bsh = my_sinh(bsh);
	    vec3 c = b * my_cosh(bsh) + a * sinh_bsh;
	    refl = sinh_bsh / c;
	    trans = b / c;
	}
	
	// Kubelka-Munk model for layering
	void layering(vec3 r0, vec3 t0, vec3 r1, vec3 t1, out vec3 r, out vec3 t)
	{
	    r = r0 + t0 * t0 * r1 / (vec3(1.0) - r0 * r1);
	    t = t0 * t1 / (vec3(1.0) - r0 * r1);
	}

	// The watercolours tends to dry first in the center
	// and accumulate more pigment in the corners
	// Input: dist < 0 outer area, dist > 0 inner area
	float brush_effect(float dist, float h_avg, float h_var)
	{
		// Only when abs(dist) < 1.0/1.0, h > 0.0
		// Means that the edges have more thickness of pigments
	    float h = max(0.0, 1.0 - 10.0 * abs(dist));	
	    h *= h;
	    h *= h;
	    return (h_avg + h_var * h) * smoothstep(-0.01, 0.002, dist);
	}
	
	// Simple 2d noise fbm with 3 octaves
	float noise2d(vec2 p)
	{
	    float t = texture2D(iChannel0, p).x;
	    t += 0.5 * texture2D(iChannel0, p * 2.0).x;
	    t += 0.25 * texture2D(iChannel0, p * 4.0).x;
	    return t / 1.75;
	}
		
	vec4 main(vec2 fragCoord) {
		vec2 uv = fragCoord.xy / iResolution.xy;
    
	    vec3 r0, t0, r1, t1;
	    
	    float sky = 0.1 + 0.1 * noise2d(uv * vec2(0.1));
	    KM(K_CeruleanBlue, S_CeruleanBlue, sky, r0, t0);
	    
	    float mountain_line = 0.5+0.04*(sin(uv.x*18.0+2.0)+sin(sin(uv.x*2.0)*7.0))-uv.y;
	    float s = clamp(2.0-10.0*abs(mountain_line),0.0,1.0);
	    vec2 uv2 = uv + vec2(0.04*s*noise2d(uv * vec2(0.1)));
	    float mountains = brush_effect(0.5+0.04*(sin(uv2.x*18.0+2.0)+sin(sin(uv2.x*2.0)*7.0))-uv2.y, 0.2, 0.1);
	    mountains *= 0.85 + 0.15 * noise2d(uv*vec2(0.2));
	    KM(K_HookersGreen, S_HookersGreen, mountains, r1, t1);
	    layering(r0,t0,r1,t1,r0,t0);
	    
	    vec2 uv3 = uv*vec2(1.0,iResolution.y/iResolution.x) + vec2(0.02*noise2d(uv * vec2(0.1)));
	    float sun = brush_effect(1.0 - distance(uv3, vec2(0.2,0.45)) / 0.08, 0.2, 0.1);
	    KM(K_HansaYellow, S_HansaYellow, sun, r1, t1);
	    layering(r0,t0,r1,t1,r0,t0);

		return vec4(r0+t0,1.0);
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

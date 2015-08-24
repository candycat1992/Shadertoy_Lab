Shader "Shadertoy/Heart" { // https://www.shadertoy.com/view/XsfGRn
	Properties {
		_BackgroundColor ("Background Color", Color) = (1.0, 0.8, 0.7, 1.0)
		_HeartColor ("Heart Color", Color) = (1.0, 0.5, 0.3, 1.0)
		_Eccentricity ("Eccentricity", Range(0, 0.5)) = 0.25
		_Blur ("Edge Blur", Range(0, 0.3)) = 0.01
		_Duration ("Duration", Range(0.5, 10.0)) = 1.5
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
  	             
    vec4 _BackgroundColor;
    vec4 _HeartColor;
    float _Eccentricity;
    float _Blur;
    float _Duration;
    
    struct v2f {      
        float4 pos : SV_POSITION;      
    	float4 scrPos : TEXCOORD0;    
     };    
    
     v2f vert(appdata_base v) {    
         v2f o;    
         o.pos = mul (UNITY_MATRIX_MVP, v.vertex);
         o.scrPos = ComputeScreenPos(o.pos);   
         return o;    
     }
     
     vec4 main(vec2 fragCoord);
        
 	 fixed4 frag(v2f _iParam) : COLOR0 {  
 	 	vec2 fragCoord = gl_FragCoord;
 	 	return main(fragCoord);
 	 }  
 	
	 vec4 main(vec2 fragCoord) {
	 	vec2 p = (2.0 * fragCoord.xy - iResolution.xy)/min(iResolution.y, iResolution.x);
	
		p.y -= 0.25;
		
    	// background color
    	vec3 bcol = vec3(1.0, 0.8, 0.7 - 0.07 * p.y) * (1.0 - 0.25 * length(p));
    	bcol = _BackgroundColor.xyz * (1.0-_Eccentricity * length(p));
		
    	// animate
    	float tt = mod(iGlobalTime, 1.5) / 1.5;
    	tt = mod(iGlobalTime, _Duration) / _Duration;
    	float ss = pow(tt, 0.2) * 0.5 + 0.5;
    	ss = 1.0 + ss * 0.5 * sin(tt * 6.2831 * 3.0 + p.y * 0.5) * exp(-tt * 4.0);
    	p *= vec2(0.5, 1.5) + ss * vec2(0.5, -0.5);
    	
    	// shape
    	float a = atan(p.x, p.y) / 3.141593;
    	float r = length(p);
    	float h = abs(a);
    	float d = (13.0 * h - 22.0 * h * h + 10.0 * h * h * h) / (6.0 - 5.0 * h);
		
		// color
		float s = 1.0 - 0.5 * clamp(r/d, 0.0, 1.0);
		s = 0.75 + 0.75 * p.x;
		s *= 1.0 - 0.25 * r;
		s = 0.5 + 0.6 * s;
		s *= 0.5 + 0.5 * pow( 1.0 - clamp(r/d, 0.0, 1.0 ), 0.1);
		vec3 hcol = vec3(1.0, 0.5 * r, 0.3) * s;
		hcol = _HeartColor.xyz * s;
		
    	vec3 col = mix(bcol, hcol, smoothstep(-0.01, 0.01, d - r));
    	col = mix(bcol, hcol, smoothstep(-_Blur, _Blur, d - r));
		
		return vec4(col, 1.0);
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

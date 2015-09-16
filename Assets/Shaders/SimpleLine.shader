Shader "Shadertoy/Simple Line" { 
	Properties{
		_CircleRadius ("Circle Radius", float) = 5
		_CircleColor ("Circle Color", Color) = (1, 1, 1, 1)
		_LineWidth ("Line Width", float) = 5
		_LineColor ("Line Color", Color) = (1, 1, 1, 1)
		_Antialias ("Antialias Factor", float) = 3
		_BackgroundColor ("Background Color", Color) = (1, 1, 1, 1)
	}
	  
	CGINCLUDE    
	 	#include "UnityCG.cginc"   
  		#pragma target 3.0   
  		#pragma glsl   

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
  		
  		#define PI2 6.28318530718
  		#define pi 3.14159265358979
  		#define halfpi (pi * 0.5)
  		#define oneoverpi (1.0 / pi)
  		
  		float _CircleRadius;
  		float4 _CircleColor;
  		float _LineWidth;
  		float4 _LineColor;
  		float _Antialias;
  		float4 _BackgroundColor;
  		
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
        	return main(gl_FragCoord);
        }  
        
        vec4 Line(vec2 pos, vec2 point1, vec2 point2, float width, float3 color, float antialias) {
//        	float k = (point1.y - point2.y)/(point1.x - point2.x);
//    		float b = point1.y - k * point1.x;
//    		
//    		float d = abs(k * pos.x - pos.y + b) / sqrt(k * k + 1);
//    		float t = smoothstep(width/2.0, width/2.0 + antialias, d);
    		
    		vec2 dir0 = point2 - point1;
			vec2 dir1 = pos - point1;
			vec2 dir2 = dir0 * dot(dir0, dir1)/dot(dir0, dir0);
			vec2 dir3 = dir1 - dir2;
			float d = length(dir3);
			float t = smoothstep(width/2.0, width/2.0 + antialias, d);
    		
        	return vec4(color, 1.0 - t);
        }
        
        vec4 Circle(vec2 pos, vec2 center, float radius, float3 color, float antialias) {
        	float d = length(pos - center) - radius;
        	float t = smoothstep(0, antialias, d);
        	return vec4(color, 1.0 - t);
        }
        
		vec4 main(vec2 fragCoord) {
			vec2 pos = fragCoord; // pos.x ~ (0, iResolution.x), pos.y ~ (0, iResolution.y)

			vec2 point1 = vec2(0.4, 0.1) * iResolution.xy;
			vec2 point2 = vec2(0.7, 0.8) * iResolution.xy;
			
			vec4 layer1 = vec4(_BackgroundColor.rgb, 1.0);
			vec4 layer2 = Line(pos, point1, point2, _LineWidth, _LineColor.rgb, _Antialias);
			vec4 layer3 =  Circle(pos, point1, _CircleRadius, _CircleColor.rgb, _Antialias);
			vec4 layer4 =  Circle(pos, point2, _CircleRadius, _CircleColor.rgb, _Antialias);
			
			vec4 fragColor = mix(layer1, layer2, layer2.a);
			fragColor = mix(fragColor, layer3, layer3.a);
			fragColor = mix(fragColor, layer4, layer4.a);
			
			return fragColor;
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
    FallBack Off    
}

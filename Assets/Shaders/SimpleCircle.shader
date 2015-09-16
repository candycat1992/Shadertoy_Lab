Shader "Shadertoy/Simple Circle" { 
	Properties{
		_Parameters ("Circle Parameters", Vector) = (0.5, 0.5, 10, 1) // Center: (x, y), Radius: z
		_CircleColor ("Circle Color", Color) = (1, 1, 1, 1)
		_BackgroundColor ("Background Color", Color) = (1, 1, 1, 1)
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
  		
  		#define PI2 6.28318530718
  		#define pi 3.14159265358979
  		#define halfpi (pi * 0.5)
  		#define oneoverpi (1.0 / pi)
  		
  		float4 _Parameters;
  		float4 _CircleColor;
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
        
        vec4 Circle(vec2 pos, vec2 center, float radius, float3 color, float antialias) {
        	float d = length(pos - center) - radius;
        	float t = smoothstep(0, antialias, d);
        	return vec4(color, 1.0 - t);
        }
        
		vec4 main(vec2 fragCoord) {
			vec2 pos = fragCoord; // pos.x ~ (0, iResolution.x), pos.y ~ (0, iResolution.y)

			vec4 layer1 = vec4(_BackgroundColor.rgb, 1.0);
			vec4 layer2 = Circle(pos, _Parameters.xy * iResolution.xy, _Parameters.z, _CircleColor.rgb, _Parameters.w);
			
			return mix(layer1, layer2, layer2.a);
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

Shader "Shadertoy/AntiAlias Point Sample" { 	// https://www.shadertoy.com/view/XtB3zw
	Properties{
		_Aniso ("Aniso", float) = 1.0		// if you want stretchy pixels, try change this number to 0.1
		iMouse ("Mouse Pos", Vector) = (100, 100, 0, 0)
		iChannel0("iChannel0", 2D) = "white" {}
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
  		
  		float _Aniso;
  		fixed4 iMouse;
  		sampler2D iChannel0;
  		
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
        
        vec4 AntiAlias_None(vec2 uv, vec2 texsize) {
    		return texture2D(iChannel0, uv / texsize);
		}
		
		vec4 AntiAliasPointSampleTexture_None(vec2 uv, vec2 texsize) {
			vec2 texUV = (floor(uv + vec2(0.5, 0.5)) + vec2(0.5, 0.5)) / texsize;
			return texture2D(iChannel0, texUV);
		}

		vec4 AntiAliasPointSampleTexture_Smoothstep(vec2 uv, vec2 texsize) {	
			vec2 w = fwidth(uv);
			vec2 texUV = (floor(uv) + vec2(0.5, 0.5) + smoothstep(vec2(0.5, 0.5) - w, vec2(0.5, 0.5) + w, fract(uv))) / texsize;
			return texture2D(iChannel0, texUV);	
		}

		vec4 AntiAliasPointSampleTexture_Linear(vec2 uv, vec2 texsize) {	
			vec2 w = fwidth(uv);
			vec2 texUV = (floor(uv) + vec2(0.5, 0.5) + clamp((fract(uv) - vec2(0.5, 0.5) + w) / w, vec2(0.0, 0.0), vec2(1.0, 1.0))) / texsize;
			return texture2D(iChannel0, texUV);	
		}

		vec4 AntiAliasPointSampleTexture_ModifiedFractal(vec2 uv, vec2 texsize) {	
    		uv.xy -= vec2(0.5, 0.5);
			vec2 w = fwidth(uv);
			vec2 texUV = (floor(uv) + vec2(0.5, 0.5) + min(fract(uv) / min(w, vec2(1.0, 1.0)), vec2(1.0, 1.0))) / texsize;
			return texture2D(iChannel0, texUV);
		}
			
		vec4 main(vec2 fragCoord)
		{
			vec4 fragColor;
			
			float split=floor(iResolution.x / 5.0);

			vec2 uv = fragCoord.xy;
			
			if (floor(uv.x) == split || floor(uv.x) == split * 2.0 || floor(uv.x) == split * 3.0 || floor(uv.x) == split * 4.0) { 
        		fragColor=vec4(1, 1, 1, 1); 
        		return fragColor; 
    		}
			
			// rotate the uv with time		
			float c = cos(iGlobalTime * 0.01), s = sin(iGlobalTime * 0.01);
			uv = mul(uv, mat2(c, s, -s, c) * 0.05);	
			
			// sample the texture!
			uv *= vec2(1.0, _Aniso);

			vec2 textureSize = vec2(64.0, 64.0);
			if (fragCoord.x<split)
				fragColor = AntiAlias_None(uv, textureSize);	
			else if (fragCoord.x < split * 2.0)
				fragColor = AntiAliasPointSampleTexture_None(uv, textureSize);	
			else if (fragCoord.x < split * 3.0)
				fragColor = AntiAliasPointSampleTexture_Smoothstep(uv, textureSize);	
			else if (fragCoord.x < split * 4.0)
				fragColor = AntiAliasPointSampleTexture_Linear(uv, textureSize);	
			else
				fragColor = AntiAliasPointSampleTexture_ModifiedFractal(uv, textureSize);
				
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

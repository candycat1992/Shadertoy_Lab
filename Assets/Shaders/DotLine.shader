Shader "Custom/Dot Line" {
	Properties {
		_MainTex ("Base (RGB)", 2D) = "white" {}
		_StartPosition ("Start Position", Vector) = (0, 0, 0)
		_EndPosition ("End Position", Vector) = (0, 0, 0)
//		_Color ("Dot Color", Color) = (241.0/255.0, 241.0/255.0, 184.0/255.0, 1.0)
		_Color ("Dot Color", Color) = (1.0, 1.0, 1.0, 1.0)
	}
	SubShader {    
    	Tags { "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" }  
      
		Blend SrcAlpha OneMinusSrcAlpha
    	Cull Off Lighting Off ZWrite Off Fog { Color (0,0,0,0) } 
    
        Pass {
            CGPROGRAM    
  
  			#include "UnityCG.cginc"  
  			
            #pragma vertex vert    
            #pragma fragment frag    
            #pragma fragmentoption ARB_precision_hint_fastest
            
            #pragma glsl
            
			#define halfLineWidth (_ScreenParams.y / 600.0)
			#define dotlineInterval (_ScreenParams.y / 25.0)
            
            sampler2D _MainTex;
            float4 _StartPosition;
            float4 _EndPosition;
            float4 _Color;
            
            struct v2f {    
            	float4 pos : SV_POSITION;    
        	    float2 uv : TEXCOORD0;
        	    float4 srcPos : TEXCOORD1;  
        	};              
        	
        	v2f vert(appdata_base v) {  
        		v2f o;
        		o.pos = mul (UNITY_MATRIX_MVP, v.vertex);
        	    o.uv = v.texcoord;  
        	    o.srcPos = ComputeScreenPos(o.pos);
        	    return o;    
        	}  
        	
        	float Line(float2 pos, float2 point0, float2 point1, float halfwidth) {
			    float2 dir0 = point1 - point0;
			    float2 dir1 = pos - point0;
			    float h = clamp(dot(dir0, dir1)/dot(dir0, dir0), 0., 1.);
			    float d = length(dir1 - dir0 * h) - halfwidth;
			    return d;
			}

        	float4 DotLine(float2 pos, float2 start, float2 end, float3 color) {
        		float dist = length(start - end);
        		float2 dir = (start - end) / dist; 
			    float seg = floor(dist / dotlineInterval);
			    float2 prevPos = end + (0.0 * dotlineInterval) * dir;
			    float2 nextPos = end + (0.2 * dotlineInterval) * dir;
			    float d = Line(pos, prevPos, nextPos, halfLineWidth);
			    for (float i = 1.; i < seg; i += 1.0) {
			        prevPos = end + ((i - 0.2)  * dotlineInterval) * dir;
			        nextPos = end + ((i + 0.2)  * dotlineInterval) * dir;
			        d = min(d, Line(pos, prevPos, nextPos, halfLineWidth));
			    }
			    
			    float w = fwidth(d) * 2.0;
			    return float4(color, 1.0 - smoothstep(0.0, w, d));
			}
        	
        	float4 frag(v2f i) : COLOR0 {
        	 	float4 col = tex2D(_MainTex, i.uv);
        	 	float2 pos = i.srcPos.xy/i.srcPos.w *_ScreenParams.xy; 
        	 	col = DotLine(pos, _StartPosition.xy, _EndPosition.xy, _Color.rgb);
        		return col;
        	}
  
            ENDCG    
        }
    }
	FallBack "Diffuse"
}

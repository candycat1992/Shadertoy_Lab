Shader "Shadertoy/AntiAlias Cube" {
	Properties {
		_MainTex ("Base (RGB)", 2D) = "white" {}
	}
	SubShader {
		Tags { "RenderType"="Opaque" }
		LOD 200
		
		Pass {
			CGPROGRAM
			#include "UnityCG.cginc"
			#pragma glsl
			
			#pragma vertex vert
			#pragma fragment frag

			sampler2D _MainTex;

			struct v2f {    
	            float4 pos : SV_POSITION;    
	            float4 uv : TEXCOORD0;   
	            float4 scrPos : TEXCOORD1; 
	        };        
	              
	        v2f vert(appdata_base v) {  
	        	v2f o;
	        	o.pos = mul (UNITY_MATRIX_MVP, v.vertex);
	        	o.uv = v.texcoord;
	        	o.scrPos = ComputeScreenPos(o.pos);  
	            return o;    
	        }

	        fixed4 frag(v2f i) : COLOR0 {
 //             float res = 64.0;
 //             float3 rcpRes = float3(1.0 / res, -0.5 / res, 0.5 / res);

	        	float texSize = 30.;
	        	float2 fragCoord = ((i.scrPos.xy/i.scrPos.w));
					
//				float4 fragColor = tex2D(_MainTex, i.uv, ddx(i.uv) * 0, ddy(i.uv) * 0);
//				float4 fragColor = tex2D(_MainTex, i.uv);
				float4 fragColor = tex2D(_MainTex, i.uv, ddx(i.uv), ddy(i.uv));
//				float4 fragColor = tex2D(_MainTex, i.uv, ddx(i.uv) * 5, ddy(i.uv) * 5);
//				float4 fragColor = tex2D(_MainTex, i.uv, float2(0.01, 0.01), float2(0.01, 0.01));

				return fragColor;
	        }  
			ENDCG
		}
	} 
	FallBack "Diffuse"
}

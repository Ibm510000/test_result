﻿Shader "Sand/Sky"
{
	Properties
	{
//		_MainTex ("Texture", 2D) = "white" {}
		_ColorGround( "Ground Color" , color) = (1,1,1,1)
		_ColorSky( "Sky Color" , color ) = (1,1,1,1)
		_ColorHeight( "height Color" , color ) = (1,1,1,1)
	}
	SubShader
	{
		Tags { "RenderType"="Transparent" "RenderQueue" = "Transparent"}

		LOD 100
		cull front


		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			// make fog work
			#pragma multi_compile_fog
			
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
//				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float3 worldPos :TEXCOORD0;

//				float2 uv : TEXCOORD0;
//				UNITY_FOG_COORDS(1)
				float4 vertex : SV_POSITION;
			};

//			sampler2D _MainTex;
//			float4 _MainTex_ST;
			float4 _ColorGround;
			float4 _ColorSky;
			float4 _ColorHeight;

			float n3D(in float3 p){
    
				const float3 s = float3(113, 157, 1);
				float3 ip = floor(p); p -= ip; 
				float4 h = float4(0., s.yz, s.y + s.z) + dot(ip, s);
				p = p*p*(3. - 2.*p); //p *= p*p*(p*(p * 6. - 15.) + 10.);
				h = lerp(frac(sin(h)*43758.5453), frac(sin(h + s.x)*43758.5453), p.x);
				h.xy = lerp(h.xz, h.yw, p.y);
				return lerp(h.x, h.y, p.z); // Range: [0, 1].
			}


			// 3D noise fBm.
			float fBm(in float3 p){
    
				return n3D(p)*0.57 + n3D(p*2.0)*0.28 + n3D(p*4.0)*0.15;
    
			}


			
			v2f vert (appdata v)
			{
				v2f o;

				o.vertex = UnityObjectToClipPos(v.vertex);
				o.worldPos = mul(unity_ObjectToWorld ,v.vertex).xyz;
//				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
//				UNITY_TRANSFER_FOG(o,o.vertex);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				fixed4 col = (1,1,1,1);
				if(i.worldPos.y<100){
					col = lerp( _ColorGround , _ColorSky , saturate( i.worldPos.y / 50 ));
				}
				else{
					col = lerp( _ColorSky , _ColorHeight , saturate( (i.worldPos.y-100) / 100 ));
					//col = ;
				}
				



				// sample the texture
//				fixed4 col = tex2D(_MainTex, i.uv);
				// apply fog
//				UNITY_APPLY_FOG(i.fogCoord, col);
				return col;
			}
			ENDCG
		}
	}
	FallBack "Transparent"
}

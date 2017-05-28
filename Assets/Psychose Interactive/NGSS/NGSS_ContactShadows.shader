Shader "Hidden/NGSS_ContactShadows"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
	}
	SubShader
	{
		Cull Off ZWrite Off ZTest Always

		CGINCLUDE

		#pragma vertex vert
		#pragma fragment frag
			
		#include "UnityCG.cginc"

		struct appdata
		{
			float4 vertex : POSITION;
			float2 uv : TEXCOORD0;
		};

		struct v2f
		{
			float4 vertex : SV_POSITION;
			float2 uv : TEXCOORD0;
		};

		v2f vert (appdata v)
		{
			v2f o;
			o.vertex = UnityObjectToClipPos(v.vertex);
			o.uv = v.uv;
			return o;
		}

		ENDCG
		
		Pass // clip edges
		{
			CGPROGRAM
			
			sampler2D _CameraDepthTexture;

			fixed4 frag (v2f input) : SV_Target
			{
				float depth = tex2D(_CameraDepthTexture, input.uv).r;

				if (input.vertex.x <= 1.0 || input.vertex.x >= _ScreenParams.x - 1.0 ||  input.vertex.y <= 1.0 || input.vertex.y >= _ScreenParams.y - 1.0)
				{
					#if defined(UNITY_REVERSED_Z)
						depth = 0.0;
					#else
						depth = 1.0;
					#endif
				}

				return fixed4(depth, depth, depth, depth);
			}
			ENDCG
		}

		Pass // render screen space rt shadows
		{
			CGPROGRAM
			#pragma target 3.0
			
			sampler2D _MainTex;

			float3 LightDir;
			float ShadowsDistance;
			int RaySamples;
			float RayWidth;
			float ShadowsFade;

			fixed4 frag (v2f input) : SV_Target
			{
				float2 coord = input.uv;
				float depth = tex2Dlod(_MainTex, float4(coord.xy, 0, 0)).r;
				#if defined(UNITY_REVERSED_Z)
					depth = 1.0 - depth;
				#endif

				coord.xy = coord.xy * 2.0 - 1.0;
				float4 viewPos = mul(unity_CameraInvProjection, float4(coord.xy, depth * 2.0 - 1.0, 1.0));
				viewPos.xyz /= viewPos.w;

				float shadow = 1.0;
				float3 rayDir = -LightDir * float3(1.0, 1.0, -1.0) * (ShadowsDistance / RaySamples) * -viewPos.z * 0.1;
				float3 rayPos = viewPos + rayDir * saturate(frac(sin(dot(coord, float2(12.9898, 78.223))) * 43758.5453));//randomize coords, produces too much far plane noise with lot of samplers
				int samples = RaySamples / (-viewPos.z * 0.1 + 0.1);

				for (int i = 0; i < samples; i++)
				{
					rayPos += rayDir;
					
					float4 rayPosProj = mul(unity_CameraProjection, float4(rayPos.xyz, 0.0));
					rayPosProj.xyz = rayPosProj.xyz / rayPosProj.w * 0.5 + 0.5;
					
					float lDepth = LinearEyeDepth(tex2Dlod(_MainTex, float4(rayPosProj.xy, 0, 0)).r);

					float depthDiff = -rayPos.z - lDepth;// + (viewPos.z * 0.00015);
					shadow *= (depthDiff > 0.0 && depthDiff < RayWidth)? (float)i / samples * ShadowsFade : 1.0;
				}
				
				return fixed4(shadow, shadow, shadow, shadow);
			}
			ENDCG
		}

		Pass // poison blur
		{
			CGPROGRAM			

			sampler2D _MainTex;
			//sampler2D _CameraDepthTexture;

			float ShadowsSoftness;

			static float2 poissonDisk[9] =
			{
				float2 ( 0.4636456f, 0.3294131f),
				float2 ( 0.3153244f, 0.8371656f),
				float2 ( 0.7389247f, -0.3152522f),
				float2 ( -0.1819379f, -0.3826133f),
				float2 ( -0.38396f, 0.2479579f),
				float2 ( 0.1985026f, -0.8434925f),
				float2 ( -0.25466f, 0.9213307f),
				float2 ( -0.8729509f, -0.3795996f),
				float2 ( -0.8918442f, 0.3004266f)
			};

			float rand01(float2 seed)
			{
			   float dt = dot(seed, float2(12.9898,78.233));// project seed on random constant vector   
			   return frac(sin(dt) * 43758.5453);// return only fractional part
			}

			// returns random angle
			float randAngle(float2 seed)
			{
				return rand01(seed)*6.283285;
			}

			fixed4 frag(v2f input) : COLOR0
			{
				float result = 0.0;//tex2Dlod(_MainTex, float4(input.uv.xy, 0, 0)).r;
				ShadowsSoftness *= (_ScreenParams.zw - 1.0);
				//float angle = randAngle(input.uv.xy);
				//float s = sin(angle);
				//float c = cos(angle);

				//float lDepth = LinearEyeDepth(tex2Dlod(_CameraDepthTexture, float4(input.uv, 0, 0))) * 0.5;

				for(int i = 0; i < 9; ++i)
				{
					//float2 offs = float2(poissonDisk[i].x * c + poissonDisk[i].y * s, poissonDisk[i].x * -s + poissonDisk[i].y * c) * ShadowsSoftness;//rotated samples
					float2 offs = poissonDisk[i] * ShadowsSoftness;// / lDepth;//no rotation
					result += tex2Dlod(_MainTex, float4(input.uv + offs.xy, 0, 0)).r;
				}

				result *= 0.1111;
				return fixed4(result, result, result, result);
			}

			ENDCG
		}

		Pass // final mix
		{
			Blend DstColor Zero

			CGPROGRAM
			
			sampler2D NGSS_ContactShadowsTexture;

			fixed4 frag (v2f input) : SV_Target
			{				
				return tex2D(NGSS_ContactShadowsTexture, input.uv);
			}
			ENDCG
		}
	}
	Fallback Off
}

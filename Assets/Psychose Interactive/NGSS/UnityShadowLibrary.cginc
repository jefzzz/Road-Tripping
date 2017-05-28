#ifndef UNITY_BUILTIN_SHADOW_LIBRARY_INCLUDED
#define UNITY_BUILTIN_SHADOW_LIBRARY_INCLUDED

// Shadowmap helpers.
//cbuffer POISSON_DISKS 
//{
	static float2 poissonDisk20[20] =
	{ 
		float2 ( 0.2111217f, -0.702272f),
		float2 ( 0.4705284f, -0.3929689f),
		float2 ( 0.5897741f, -0.7773586f),
		float2 ( -0.154882f, -0.4878186f),
		float2 ( -0.08802283f, -0.9208807f),
		float2 ( 0.8209927f, -0.1620779f),
		float2 ( 0.4817981f, 0.04513926f),
		float2 ( 0.0881269f, -0.04166441f),
		float2 ( -0.3571257f, -0.1645149f),
		float2 ( -0.651518f, -0.7295282f),
		float2 ( -0.2112222f, 0.1975897f),
		float2 ( -0.735217f, -0.2109533f),
		float2 ( -0.84478f, 0.1897396f),
		float2 ( -0.5461306f, 0.6595152f),
		float2 ( -0.08115801f, 0.5445821f),
		float2 ( -0.2131593f, 0.8739875f),
		float2 ( 0.4049454f, 0.4862685f),
		float2 ( 0.8282107f, 0.5104074f),
		float2 ( 0.2774227f, 0.84667f),
		float2 ( 0.9371698f, 0.1748641f)
	};
	
	static float2 poissonDisk25[25] =
	{
		float2 ( -0.6351818f, 0.2172711f),
		float2 ( -0.1499606f, 0.2320675f),
		float2 ( -0.67978f, 0.6884924f),
		float2 ( -0.7758647f, -0.253409f),
		float2 ( -0.4731916f, -0.2832723f),
		float2 ( -0.3330079f, 0.6430059f),
		float2 ( -0.1384151f, -0.09830225f),
		float2 ( -0.8182327f, -0.5645939f),
		float2 ( -0.9198472f, 0.06549802f),
		float2 ( -0.1422085f, -0.4872109f),
		float2 ( -0.4980833f, -0.5885599f),
		float2 ( -0.3326159f, -0.8496148f),
		float2 ( 0.3066736f, -0.1401997f),
		float2 ( 0.1148317f, 0.374455f),
		float2 ( -0.0388568f, 0.8071329f),
		float2 ( 0.4102885f, 0.6960295f),
		float2 ( 0.5563877f, 0.3375377f),
		float2 ( -0.01786576f, -0.8873765f),
		float2 ( 0.234991f, -0.4558438f),
		float2 ( 0.6206775f, -0.1551005f),
		float2 ( 0.6640642f, -0.5691427f),
		float2 ( 0.7312726f, 0.5830168f),
		float2 ( 0.8879707f, 0.05715213f),
		float2 ( 0.3128296f, -0.830803f),
		float2 ( 0.8689764f, -0.3397973f)
	};
	
	static fixed3 sampleOffsetDirections[20] =
	{
	   fixed3( 1,  1,  1), fixed3( 1, -1,  1), fixed3(-1, -1,  1), fixed3(-1,  1,  1), 
	   fixed3( 1,  1, -1), fixed3( 1, -1, -1), fixed3(-1, -1, -1), fixed3(-1,  1, -1),
	   fixed3( 1,  1,  0), fixed3( 1, -1,  0), fixed3(-1, -1,  0), fixed3(-1,  1,  0),
	   fixed3( 1,  0,  1), fixed3(-1,  0,  1), fixed3( 1,  0, -1), fixed3(-1,  0, -1),
	   fixed3( 0,  1,  1), fixed3( 0, -1,  1), fixed3( 0, -1, -1), fixed3( 0,  1, -1)
	};
	
	//float2 offsetDirections25[25];
	//float3 offsetDirections20[20];
	float3 offsetDirections25[25];
//};

// Returns a random number based on a float3 and an index.
float randInd(float3 seed, int i)
{
	float4 seed4 = float4(seed,i);
	float dt = dot(seed4, float4(12.9898,78.233,45.164,94.673));
	return frac(sin(dt) * 43758.5453);
}

float rand01(float3 seed)
{
   float dt = dot(seed, float3(12.9898,78.233,45.5432));// project seed on random constant vector   
   return frac(sin(dt) * 43758.5453);// return only fractional part
}

float3 randDir(float3 seed)
{
	float3 dt = float3 (dot(seed, float3 (12.9898,78.233,45.5432)), dot(seed, float3 (78.233,45.5432,12.9898)), dot(seed, float3 (45.5432,12.9898,78.233)));
	return sin(frac(sin(dt) * 43758.5453)*6.283285);
}

int randInt(float3 seed, int maxInt)
{
   return int((float(maxInt) * rand01(seed), maxInt)%16);//fmod() function equivalent as % operator
}

// returns random angle
float randAngle(float3 seed)
{
	return rand01(seed)*6.283285;//*(1.0 - _LightShadowData.r)*10//can be tweaked globally to range between Banding and Noisy
}

uniform sampler2D unity_RandomRotation16;
//uniform sampler2D _randomPoissonTexture;

#if defined( SHADOWS_SCREEN ) && defined( LIGHTMAP_ON )
	#define HANDLE_SHADOWS_BLENDING_IN_GI 1
#endif

// ------------------------------------------------------------------
// Spot light shadows

#if defined (SHADOWS_DEPTH) && defined (SPOT)

// declare shadowmap
#if !defined(SHADOWMAPSAMPLER_DEFINED)
UNITY_DECLARE_SHADOWMAP(_ShadowMapTexture);
#endif

// shadow sampling offsets
#if defined (SHADOWS_SOFT)
float4 _ShadowOffsets[4];
#endif

inline fixed UnitySampleShadowmap (float4 shadowCoord)
{
	// DX11 feature level 9.x shader compiler (d3dcompiler_47 at least)
	// has a bug where trying to do more than one shadowmap sample fails compilation
	// with "inconsistent sampler usage". Until that is fixed, just never compile
	// multi-tap shadow variant on d3d11_9x.

	#if defined (SHADOWS_SOFT) && !defined (SHADER_API_D3D11_9X)
	
		// 25-tap shadows (Penumbra size varies based on receiver distance, PCSS will come in a future update,)
		float4 coord = shadowCoord;
		coord.xyz /= coord.w;
		
		float4 rotation = tex2D(unity_RandomRotation16, coord.xy * _ScreenParams.xy * 0.1) * 2.f - 1.f;// red = cos(theta), green = sin(theta), blue = inverted red, alpha = inverted blue
		//float angle = dot(frac(shadowCoord),fixed3(360.0, 360.0, 360.0)) * 1000000.0;//produces weird artects
		float angle = randAngle(rotation.xyz);//rotated.xyz texture gives stable patterns than shadowCoord.xyz
		float s = sin(angle);
		float c = cos(angle);
		
		float diskRadius = 0.015 * (1-_LightShadowData.r);
		float result = 0.0;
		
		[loop]for(int i = 0; i < 25; ++i)
		{
			/*
			half2 poi = poissonDisk25[i];
			poi.x = dot( poi.xy, rotation.rg );
			poi.y = dot( poi.xy, rotation.ba );
			const half2 rotPoi = poi;
			const half2 rotatedOffset = rotPoi * diskRadius * shadowCoord.z;
			*/
			
			// rotate offset
			//float2 rotatedOffset = poissonDisk25[i] * ((frac(coord.xy)) * 2.0f - 1.0f) * diskRadius;//jitter method
			//float2 rotatedOffset = float2(poissonDisk25[i].x + rotation.x, poissonDisk25[i].y + rotation.y) * diskRadius;//with this method we can directly use texture values
			float2 rotatedOffset = float2(poissonDisk25[i].x * c + poissonDisk25[i].y * s, poissonDisk25[i].x * -s + poissonDisk25[i].y * c) * diskRadius;
			
			#if defined (SHADOWS_NATIVE)
			result += UNITY_SAMPLE_SHADOW(_ShadowMapTexture, float4( coord.xy + rotatedOffset, coord.zw)).x;
			#else
			result += SAMPLE_DEPTH_TEXTURE(_ShadowMapTexture, coord.xy + rotatedOffset).x < coord.z ? 0.0 : 1.0;
			#endif
			
			//result += bilinear_filtering(coord, rotatedOffset);
		}
		half shadow = dot(result, 0.04);
		
	#else
	
		// 25-tap shadows (Penumbra size is maintained)
		float4 coord = shadowCoord;
		coord.xyz /= coord.w;		
		
		float4 rotation = tex2D(unity_RandomRotation16, coord.xy * _ScreenParams.xy * 0.1) * 2.f - 1.f;
		float angle = randAngle(rotation.xyz);
		float s = sin(angle);
		float c = cos(angle);
		
		//float diskRadius = 0.5 / (1-_LightShadowData.r) / (shadowCoord.z / (_LightShadowData.z + _LightShadowData.w));
		float diskRadius = 0.015 * (1-_LightShadowData.r);
		float result = 0.0;
		
		[loop]for(int i = 0; i < 25; ++i)
		{
			// rotate offset
			float2 rotatedOffset = float2(poissonDisk25[i].x * c + poissonDisk25[i].y * s, poissonDisk25[i].x * -s + poissonDisk25[i].y * c) * diskRadius;
			
			#if defined (SHADOWS_NATIVE)
			result += UNITY_SAMPLE_SHADOW(_ShadowMapTexture, float4( coord.xy + rotatedOffset, coord.zw)).x;
			#else
			result += SAMPLE_DEPTH_TEXTURE(_ShadowMapTexture, coord.xy + rotatedOffset).x < coord.z ? 0.0 : 1.0;
			#endif
		}
		half shadow = dot(result, 0.04);
		
	#endif

	return shadow;
}

#endif // #if defined (SHADOWS_DEPTH) && defined (SPOT)

// ------------------------------------------------------------------
// Point light shadows

#if defined (SHADOWS_CUBE)

uniform samplerCUBE_float _ShadowMapTexture;
//UNITY_DECLARE_TEXCUBE(_ShadowMapTexture);
inline float SampleCubeDistance (float3 vec)
{
	#ifdef UNITY_FAST_COHERENT_DYNAMIC_BRANCHING
		//return UnityDecodeCubeShadowDepth(UNITY_SAMPLE_TEXCUBE_LOD(_ShadowMapTexture, float4(vec, 0)));
		return UnityDecodeCubeShadowDepth(texCUBElod(_ShadowMapTexture, float4(vec, 0)));
	#else
		//return UnityDecodeCubeShadowDepth(UNITY_SAMPLE_TEXCUBE(_ShadowMapTexture, vec));
		return UnityDecodeCubeShadowDepth(texCUBE(_ShadowMapTexture, vec));
	#endif
}

float3x3 arbitraryAxisRotation(float3 axis, float angle)
{
    axis = normalize(axis);
    float s = sin(angle);
    float c = cos(angle);	
    float oc = 1.0 - c;
    
    return float3x3(oc * axis.x * axis.x + c,           oc * axis.x * axis.y - axis.z * s,  oc * axis.z * axis.x + axis.y * s,
					oc * axis.x * axis.y + axis.z * s,  oc * axis.y * axis.y + c,           oc * axis.y * axis.z - axis.x * s,
					oc * axis.z * axis.x - axis.y * s,  oc * axis.y * axis.z + axis.x * s,  oc * axis.z * axis.z + c);
}

inline half UnitySampleShadowmap (float3 vec)
{
	float mdst = length(vec);//To get world pos back, simply add _LightPositionRange.xyz to vec
	//receiver distance in 0-1 range
	float mydist = mdst * _LightPositionRange.w;// .xyz is light pos and .w is 1/range
	//mydist -= unity_LightShadowBias.x * _LightPositionRange.w;
	
	#if defined (SHADOWS_SOFT)
		
		//float angle = randAngle(vec);//gives more stable patterns than previous method
		//float3x3 rotMat = arbitraryAxisRotation(vec, angle);//rotation around arbitrary axis
		
		//float dist = SampleCubeDistance (vec);
		//float angle = dot(frac(vec),fixed3(360.0, 360.0, 360.0)) * 500000.0;		
		//float3x3 rotMat = float3x3(c, -s, 0,    s, c, 0,    0, 0, 1);//rotation around Z axis
		//float s = sin(angle);
		//float c = cos(angle);		
		
		float diskRadius = 0.35 * (1.0 - _LightShadowData.r);
		
		// Tangent plane
		float3 xaxis = normalize (cross (vec, randDir(vec.xyz)));
		float3 yaxis = normalize (cross (vec, xaxis));
		xaxis *= diskRadius;
		yaxis *= diskRadius;
		
		float shadow = 1.0;
		
		//PCSS
		float blockerCount = 0;
		float avgBlockerDistance = 0.0;	
				
		for(int i = 0; i < 25; ++i)
		{
			//float3 rotatedOffset = sampleOffsetDirections[i];
			//int index = int(20.0*randInd(floor((vec)*5000.0), i))%20; float3 rotatedOffset = sampleOffsetDirections[index];//this shit is slow as fak
			//float3 rotatedOffset = float3(sampleOffsetDirections[i].x * c + sampleOffsetDirections[i].y * s, sampleOffsetDirections[i].x * -s + sampleOffsetDirections[i].y * c, sampleOffsetDirections[i].z);			
			//float3 rotatedOffset = mul(rotMat, sampleOffsetDirections[i]);//poissonDisk20[i] doesn't give omogene rotations but keeping as an option
			
			float3 sampleDir = xaxis * poissonDisk25[i].x + yaxis * poissonDisk25[i].y;			
			offsetDirections25[i] = sampleDir;
			
			float closestDepth = SampleCubeDistance(vec + sampleDir).r;
			if(closestDepth < mydist)
			{
				blockerCount++;
				avgBlockerDistance += closestDepth;
			}
		}
		
		if( blockerCount == 0 )//There are no occluders so early out (this saves filtering) 
			return 1.0f;
		//else if (blockerCount == 25)//20 = BLOCKER_SEARCH_COUNT (saves filtering but looks ugly as shet with poisson filtering)
			//return 0.0;
			
		float dist = avgBlockerDistance / blockerCount;
		//clamping the kernel size to avoid blocky shadows at close ranges
		diskRadius *= clamp((mydist - dist)/dist, 0.15, 10000.0);
		//diskRadius = lerp(0.15, 0.5, (mydist - dist)/mydist);//who the fuck told you to lerp?

		//PCSS		
		for(int i = 0; i < 25; ++i)
		{			
			float closestDepth = SampleCubeDistance(vec + offsetDirections25[i] * diskRadius).r;
			shadow -= (mydist - closestDepth < 0.0)? 0.0 : 0.04;
		}
		
		return shadow;

	#else
		
		float diskRadius = 0.075 * (1.0 - _LightShadowData.r);
		
		// Tangent plane
		float3 xaxis = normalize (cross (vec, randDir(vec.xyz)));//rotation.xyz
		float3 yaxis = normalize (cross (vec, xaxis));
		xaxis *= diskRadius;
		yaxis *= diskRadius;
		
		float shadow = 1.0;
		
		for(int i = 0; i < 25; ++i)
		{
			float3 sampleDir = xaxis * poissonDisk25[i].x + yaxis * poissonDisk25[i].y;
			float closestDepth = SampleCubeDistance(vec + sampleDir).r;
			shadow -= (mydist - closestDepth < 0.0)? 0.0 : 0.04;
		}
		
		return shadow;
		
	#endif
}

#endif // #if defined (SHADOWS_CUBE)


// ------------------------------------------------------------------
// Baked shadows

#if UNITY_VERSION >= 560

#if UNITY_LIGHT_PROBE_PROXY_VOLUME

half4 LPPV_SampleProbeOcclusion(float3 worldPos)
{
	const float transformToLocal = unity_ProbeVolumeParams.y;
	const float texelSizeX = unity_ProbeVolumeParams.z;

	//The SH coefficients textures and probe occlusion are packed into 1 atlas.
	//-------------------------
	//| ShR | ShG | ShB | Occ |
	//-------------------------

	float3 position = (transformToLocal == 1.0f) ? mul(unity_ProbeVolumeWorldToObject, float4(worldPos, 1.0)).xyz : worldPos;

	//Get a tex coord between 0 and 1
	float3 texCoord = (position - unity_ProbeVolumeMin.xyz) * unity_ProbeVolumeSizeInv.xyz;

	// Sample fourth texture in the atlas
	// We need to compute proper U coordinate to sample.
	// Clamp the coordinate otherwize we'll have leaking between ShB coefficients and Probe Occlusion(Occ) info
	texCoord.x = max(texCoord.x * 0.25f + 0.75f, 0.75f + 0.5f * texelSizeX);

	return UNITY_SAMPLE_TEX3D_SAMPLER(unity_ProbeVolumeSH, unity_ProbeVolumeSH, texCoord);
}

#endif //#if UNITY_LIGHT_PROBE_PROXY_VOLUME

// ------------------------------------------------------------------
inline fixed UnitySampleBakedOcclusion (float2 lightmapUV, float3 worldPos)
{
	#if defined (SHADOWS_SHADOWMASK)
		#if defined(LIGHTMAP_ON)
			fixed4 rawOcclusionMask = UNITY_SAMPLE_TEX2D_SAMPLER(unity_ShadowMask, unity_Lightmap, lightmapUV.xy);
		#else
			fixed4 rawOcclusionMask = fixed4(1.0, 1.0, 1.0, 1.0);
			#if UNITY_LIGHT_PROBE_PROXY_VOLUME
				if (unity_ProbeVolumeParams.x == 1.0)
					rawOcclusionMask = LPPV_SampleProbeOcclusion(worldPos);
				else
					rawOcclusionMask = UNITY_SAMPLE_TEX2D(unity_ShadowMask, lightmapUV.xy);
			#else
				rawOcclusionMask = UNITY_SAMPLE_TEX2D(unity_ShadowMask, lightmapUV.xy);
			#endif
		#endif
		return saturate(dot(rawOcclusionMask, unity_OcclusionMaskSelector));

	#else
		//Handle LPPV baked occlusion for subtractive mode 
		#if UNITY_LIGHT_PROBE_PROXY_VOLUME && !defined(LIGHTMAP_ON) && !UNITY_STANDARD_SIMPLE
			fixed4 rawOcclusionMask = fixed4(1.0, 1.0, 1.0, 1.0);
			if (unity_ProbeVolumeParams.x == 1.0)
				rawOcclusionMask = LPPV_SampleProbeOcclusion(worldPos);
			return saturate(dot(rawOcclusionMask, unity_OcclusionMaskSelector));
		#endif
		
		return 1.0;
	#endif
}

// ------------------------------------------------------------------
inline fixed4 UnityGetRawBakedOcclusions(float2 lightmapUV, float3 worldPos)
{
	#if defined (SHADOWS_SHADOWMASK)
		#if defined(LIGHTMAP_ON)
			return UNITY_SAMPLE_TEX2D_SAMPLER(unity_ShadowMask, unity_Lightmap, lightmapUV.xy);
		#else
			half4 probeOcclusion = unity_ProbesOcclusion;

			#if UNITY_LIGHT_PROBE_PROXY_VOLUME
				if (unity_ProbeVolumeParams.x == 1.0)
					probeOcclusion = LPPV_SampleProbeOcclusion(worldPos);
			#endif

			return probeOcclusion;
		#endif
	#else
		return fixed4(1.0, 1.0, 1.0, 1.0);
	#endif
}

// --------------------------------------------------------
inline half UnityMixRealtimeAndBakedShadows(half realtimeShadowAttenuation, half bakedShadowAttenuation, half fade)
{
	#if !defined(SHADOWS_DEPTH) && !defined(SHADOWS_SCREEN) && !defined(SHADOWS_CUBE)
		#if defined (LIGHTMAP_SHADOW_MIXING) && !defined (SHADOWS_SHADOWMASK)
			//In subtractive mode when there is no shadow we still want to kill
			//the light contribution because its already baked in the lightmap.
			return 0.0;
		#else
			return bakedShadowAttenuation;
		#endif
	#endif

	#if (SHADER_TARGET <= 20) || UNITY_STANDARD_SIMPLE
		//no fading nor blending on SM 2.0 because of instruction count limit.
		#if defined (SHADOWS_SHADOWMASK)
			return min(realtimeShadowAttenuation, bakedShadowAttenuation);
		#else
			return realtimeShadowAttenuation;
		#endif
	#endif 

			
	#if defined (SHADOWS_SHADOWMASK)
		#if defined (LIGHTMAP_SHADOW_MIXING)
				realtimeShadowAttenuation = saturate(realtimeShadowAttenuation + fade);
				return min(realtimeShadowAttenuation, bakedShadowAttenuation);
		#else
				return lerp(realtimeShadowAttenuation, bakedShadowAttenuation, fade);
		#endif

	#else //no shadowmask
		half attenuation = saturate(realtimeShadowAttenuation + fade);

		//Handle LPPV baked occlusion for subtractive mode 
		#if UNITY_LIGHT_PROBE_PROXY_VOLUME && !defined(LIGHTMAP_ON) && !UNITY_STANDARD_SIMPLE
			if (unity_ProbeVolumeParams.x == 1.0)
				attenuation = min(bakedShadowAttenuation, attenuation);
		#endif

		return attenuation;
	#endif
}

// --------------------------------------------------------
// Shadow fade

float UnityComputeShadowFadeDistance(float3 wpos, float z)
{
	float sphereDist = distance(wpos, unity_ShadowFadeCenterAndType.xyz);
	return lerp(z, sphereDist, unity_ShadowFadeCenterAndType.w);
}

// --------------------------------------------------------
half UnityComputeShadowFade(float fadeDist)
{
	return saturate(fadeDist * _LightShadowData.z + _LightShadowData.w);
}

#endif // UNITY_VERSION >= 560

#endif // UNITY_BUILTIN_SHADOW_LIBRARY_INCLUDED

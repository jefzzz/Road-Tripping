#include "EMParticleVariables.cginc"
inline float DistanceFade(float fadeDistEnd, float fadeDistStart, float3 particlePos)
{
	//_WorldSpaceCameraPos comes from Unity defined variables
	float3 cameraPos = _WorldSpaceCameraPos; 
	//You might think that creating cameraPos float3 have performance impact
	//But in reality, it is removed on compile time
	//Compiler knows that it is a dummy variable used only for readibility
	
	//particlePos should be transformed into world space before passing it here!
	float fadeDistance = distance(cameraPos, particlePos) - fadeDistEnd;
	fadeDistance = saturate(fadeDistance / (fadeDistStart - fadeDistEnd));
	return fadeDistance;
}
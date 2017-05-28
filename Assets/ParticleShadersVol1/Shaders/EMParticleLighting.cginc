#include "EMParticleFunctions.cginc"

struct SurfaceOutputSmoke
{
    fixed3 Albedo;  
    fixed3 Normal;  
    fixed3 Emission;
    half Specular;
    fixed Gloss; 
    fixed Alpha; 
};

inline fixed4 LightingSmoke (SurfaceOutputSmoke s, fixed3 lightDir, fixed atten)
{
	fixed diff = max (0, dot (s.Normal, lightDir));
	fixed invertedThickness = 1 - _Thickness;
	
	//Light scattering is achieved with half-lambert technique
	// https://developer.valvesoftware.com/wiki/Half_Lambert
	diff = pow(diff * invertedThickness + _Thickness, 2);

	#ifdef BACKLIGHT_ON
		//diffuse light for the shadowed area
		fixed backLight = max (0, dot (-s.Normal, lightDir));
		//fake light scattering eliminates black rings when particle normals are perpendicular to a light
		backLight = pow(backLight * 0.5 + 0.5, 2);
		//bump the alpha to get more visible details, multiply the result by thickness
		//0.5 is a fixed light absorbtion factor. A magic value really
		backLight *= pow(saturate(1-s.Alpha), 3) * invertedThickness * 0.5;

		diff += backLight;
	#endif
	
	fixed4 c;
	
	c.rgb = s.Albedo * _LightColor0.rgb * diff * atten;
	
	c.a = s.Alpha;
	return c;
}
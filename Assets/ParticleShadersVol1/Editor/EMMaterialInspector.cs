using System;
using System.Collections.Generic;
using UnityEngine;


namespace UnityEditor
{
	internal class EMMaterialInspector : ShaderGUI
	{
		public enum LightingModes {MultiLightLit, MultiLightEmissive, Lit, LitEmissive, Unlit}
		public enum AlphaModes {Fade, Erosion}
		public enum BlendModes {AlphaBlend, Additive, AdditiveSoft} //only for Unlit shader

		private MaterialEditor m_MaterialEditor;

		//Popup properties
		private MaterialProperty m_LightingMode;
		private MaterialProperty m_BlendMode;
		private MaterialProperty m_AlphaMode;

		//Optional properties
		private MaterialProperty m_MainTexture;
		private MaterialProperty m_HDRMultiplier;
		private MaterialProperty m_TintColor;
		private MaterialProperty m_Cutoff;
		private MaterialProperty m_Thickness;
		private MaterialProperty m_InvFade;
		private MaterialProperty m_DistanceFadeStart;
		private MaterialProperty m_DistanceFadeEnd;

		private bool m_Backlight;
		private bool m_SoftParticles;
		private bool m_DistanceFade;

		private static class Styles
		{
			public static readonly string[] m_LightingNames = Enum.GetNames (typeof (LightingModes));
			public static readonly string[] m_BlendNames = Enum.GetNames (typeof (BlendModes));
			public static readonly string[] m_AlphaNames = Enum.GetNames (typeof (AlphaModes));
			public static string m_LightingPopup = "Lighting Mode";
			public static string m_BlendPopup = "Blend Mode";
			public static string m_AlphaPopup = "Alpha Mode";

			public static string HeaderMain = "Main Settings";
			public static string HeaderOptional = "Additional Settings";

			public static GUIContent m_MainTextureText = new GUIContent ("Main Texture", "Diffuse color (RGB) and Transparency (A)");
			public static GUIContent m_HDRMultiplierText = new GUIContent ("HDR Multiplier", "Emissive color HDR multiplier");
			public static GUIContent m_CutoffText = new GUIContent ("Shadow Cutoff", "How much Transparency affects shadow visibility");
			public static GUIContent m_ThicknessText = new GUIContent ("Thickness", "Light transmittance of particle");
			public static GUIContent m_SoftParticlesToggle = new GUIContent ("Soft Particles");
			public static GUIContent m_InvFadeText = new GUIContent ("Soft Particles Factor", "Soft Particles strength factor");
			public static GUIContent m_DistanceFadeToggle = new GUIContent ("Distance Fade");
			public static GUIContent m_DistanceFadeStartText = new GUIContent ("Fade Start", "Startng fade distance from Camera to particle. Negative values are supported");
			public static GUIContent m_DistanceFadeEndText = new GUIContent ("Fade End", "Ending fade distance from Camera to particle");
			public static GUIContent m_BacklightToggle = new GUIContent ("Back light transluscency");
		}

		public void FindProperties (Material material, MaterialProperty[] props)
		{
			m_LightingMode 	= FindProperty ("_LightingMode", props, false);
			m_BlendMode 	= FindProperty ("_BlendMode", props, false);
			m_AlphaMode 	= FindProperty ("_AlphaMode", props, false);

			m_MainTexture 	= FindProperty ("_MainTex", props);
			m_HDRMultiplier	= FindProperty ("_HDRMultiplier", props, false);
			m_TintColor 	= FindProperty ("_TintColor", props);
			m_Cutoff 		= FindProperty ("_Cutoff", props, false);
			m_Thickness	 	= FindProperty ("_Thickness", props, false);
			m_InvFade 		= FindProperty ("_InvFade", props, false);
			m_DistanceFadeStart = FindProperty ("_FadeStart", props, false);
			m_DistanceFadeEnd   = FindProperty ("_FadeEnd", props, false);

			//returns false also when keyword does not exist
			m_Backlight 	= material.IsKeywordEnabled ("BACKLIGHT_ON") ? true : false;
			m_SoftParticles = material.IsKeywordEnabled ("SOFTPARTICLE_ON") ? true : false;
			m_DistanceFade  = material.IsKeywordEnabled ("DISTANCEFADE_ON") ? true : false;
		}

		public override void OnGUI (MaterialEditor materialEditor, MaterialProperty[] props)
		{

			m_MaterialEditor = materialEditor;

			Material material = materialEditor.target as Material;

			FindProperties (material, props);
			ShaderPropertiesGUI (material);
		}


		public void ShaderPropertiesGUI (Material material)
		{
			EditorGUIUtility.labelWidth = 0f;

			EditorGUI.BeginChangeCheck();
			{
				GUILayout.Label(Styles.HeaderMain, EditorStyles.boldLabel);
				LightingModePopup(material);
				AlphaModePopup(material);
				BlendModePopup(material);

				EditorGUILayout.Space();
				EditorGUILayout.Space();
				m_MaterialEditor.TexturePropertySingleLine(Styles.m_MainTextureText, m_MainTexture, m_TintColor);
				m_MaterialEditor.TextureScaleOffsetProperty (m_MainTexture);


				AdditionalSettings(material);
			}

		}

		private void LightingModePopup(Material material)
		{
			EditorGUI.showMixedValue = m_LightingMode.hasMixedValue;
			var lightingMode = (LightingModes)m_LightingMode.floatValue;
		
			EditorGUI.BeginChangeCheck ();
			lightingMode = (LightingModes)EditorGUILayout.Popup (Styles.m_LightingPopup, (int)lightingMode, Styles.m_LightingNames);
			if (EditorGUI.EndChangeCheck ()) {
				m_MaterialEditor.RegisterPropertyChangeUndo ("Lighting Mode");
				m_LightingMode.floatValue = (float)lightingMode;
			}
		
			EditorGUI.showMixedValue = false;

			switch ((int)m_LightingMode.floatValue) {
			case (int)LightingModes.MultiLightLit:
				material.shader = Shader.Find ("Ethical Motion/Particles/Lit MultiLight");
				material.DisableKeyword ("EMISSION_ON");
				break;

			case (int)LightingModes.MultiLightEmissive:
				material.shader = Shader.Find ("Ethical Motion/Particles/Lit MultiLight");
				material.EnableKeyword ("EMISSION_ON");
				break;

			case (int)LightingModes.Lit:
				material.shader = Shader.Find ("Ethical Motion/Particles/Lit");
				material.DisableKeyword ("EMISSION_ON");
				break;

			case (int)LightingModes.LitEmissive:
				material.shader = Shader.Find ("Ethical Motion/Particles/Lit");
				material.EnableKeyword ("EMISSION_ON");
				break;

			case (int)LightingModes.Unlit:
				material.DisableKeyword ("EMISSION_ON");
				material.shader = Shader.Find ("Ethical Motion/Particles/Unlit");
				break;
			}
		}

		private void BlendModePopup(Material material)
		{
			if ((int)m_LightingMode.floatValue == (int)LightingModes.Unlit)
			{
				EditorGUI.showMixedValue = m_BlendMode.hasMixedValue;
				var blendMode = (BlendModes)m_BlendMode.floatValue;
			
				EditorGUI.BeginChangeCheck ();
				blendMode = (BlendModes)EditorGUILayout.Popup (Styles.m_BlendPopup, (int)blendMode, Styles.m_BlendNames);
				if (EditorGUI.EndChangeCheck ()) {
					m_MaterialEditor.RegisterPropertyChangeUndo ("Blend Mode");
					m_BlendMode.floatValue = (float)blendMode;
				}
			
				EditorGUI.showMixedValue = false;

				switch ((int)m_BlendMode.floatValue) {
				case (int)BlendModes.Additive:
					material.SetInt ("_BlendSrc", (int)UnityEngine.Rendering.BlendMode.One);
					material.SetInt ("_BlendDst", (int)UnityEngine.Rendering.BlendMode.One);
					material.EnableKeyword ("ADDITIVE_ON");
					break;
				
				case (int)BlendModes.AdditiveSoft:
					material.SetInt ("_BlendSrc", (int)UnityEngine.Rendering.BlendMode.OneMinusDstColor);
					material.SetInt ("_BlendDst", (int)UnityEngine.Rendering.BlendMode.One);
					material.EnableKeyword ("ADDITIVE_ON");
					break;
				
				case (int)BlendModes.AlphaBlend:
					material.SetInt ("_BlendSrc", (int)UnityEngine.Rendering.BlendMode.SrcAlpha);
					material.SetInt ("_BlendDst", (int)UnityEngine.Rendering.BlendMode.OneMinusSrcAlpha);
					material.DisableKeyword ("ADDITIVE_ON");
					break;
				}
			}

		}

		private void AlphaModePopup(Material material)
		{
			EditorGUI.showMixedValue = m_AlphaMode.hasMixedValue;
			var alphaMode = (AlphaModes)m_AlphaMode.floatValue;
			
			EditorGUI.BeginChangeCheck();
			alphaMode = (AlphaModes)EditorGUILayout.Popup(Styles.m_AlphaPopup, (int)alphaMode, Styles.m_AlphaNames);
			if (EditorGUI.EndChangeCheck())
			{
				m_MaterialEditor.RegisterPropertyChangeUndo("Alpha Mode");
				m_AlphaMode.floatValue = (float)alphaMode;
			}
			
			EditorGUI.showMixedValue = false;

			switch ((int)m_AlphaMode.floatValue)
			{
			case (int)AlphaModes.Erosion:
				material.EnableKeyword("ALPHAEROSION_ON");
				break;
				
			case (int)AlphaModes.Fade:
				material.DisableKeyword("ALPHAEROSION_ON");
				break;
			}
		}

		private void AdditionalSettings(Material material)
		{
			if (m_HDRMultiplier != null)
			{
				if ((LightingModes)m_LightingMode.floatValue == LightingModes.MultiLightEmissive ||
					(LightingModes)m_LightingMode.floatValue == LightingModes.LitEmissive)
				{
					m_MaterialEditor.RegisterPropertyChangeUndo (Styles.m_HDRMultiplierText.text);
					m_MaterialEditor.FloatProperty (m_HDRMultiplier, Styles.m_HDRMultiplierText.text);
				} 
			}

			EditorGUILayout.Space();

			if (m_Cutoff != null)
				m_MaterialEditor.RangeProperty(m_Cutoff, Styles.m_CutoffText.text);

			EditorGUILayout.Space();

			if (m_Thickness != null)
				m_MaterialEditor.RangeProperty (m_Thickness, Styles.m_ThicknessText.text);

			if (m_Backlight)
			{
				EditorGUI.BeginChangeCheck ();
				var backLight = EditorGUILayout.Toggle (Styles.m_BacklightToggle, m_Backlight);
				EditorGUI.EndChangeCheck ();
				{
					m_MaterialEditor.RegisterPropertyChangeUndo (Styles.m_BacklightToggle.text);
					if (backLight) {
						material.EnableKeyword ("BACKLIGHT_ON");
					} else
						material.DisableKeyword ("BACKLIGHT_ON");
				}
			}

			EditorGUILayout.Space();
			EditorGUILayout.Space();
			GUILayout.Label(Styles.HeaderOptional, EditorStyles.boldLabel);

			if (m_InvFade != null) {
				EditorGUI.BeginChangeCheck();
				var softParticles = EditorGUILayout.Toggle(Styles.m_SoftParticlesToggle, m_SoftParticles);
				EditorGUI.EndChangeCheck();
				{
					m_MaterialEditor.RegisterPropertyChangeUndo ("Enable Soft Particle");
					if (softParticles)
					{
						material.EnableKeyword("SOFTPARTICLE_ON");

						m_MaterialEditor.RangeProperty(m_InvFade, Styles.m_InvFadeText.text);
					}
					else material.DisableKeyword("SOFTPARTICLE_ON");
				}
			}

			EditorGUILayout.Space ();

			if (m_DistanceFadeStart != null && m_DistanceFadeEnd != null) {
				EditorGUI.BeginChangeCheck();
				var distanceFade = EditorGUILayout.Toggle(Styles.m_DistanceFadeToggle, m_DistanceFade);
				EditorGUI.EndChangeCheck();
				{
					m_MaterialEditor.RegisterPropertyChangeUndo ("Distance Fade");
					if (distanceFade)
					{
						material.EnableKeyword("DISTANCEFADE_ON");

						m_MaterialEditor.FloatProperty(m_DistanceFadeStart, Styles.m_DistanceFadeStartText.text);
						m_MaterialEditor.FloatProperty(m_DistanceFadeEnd, Styles.m_DistanceFadeEndText.text);
					}
					else material.DisableKeyword("DISTANCEFADE_ON");
				}
			}


		}
	}

}
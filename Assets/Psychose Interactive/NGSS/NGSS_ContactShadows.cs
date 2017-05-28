using UnityEngine;
using UnityEngine.Rendering;
using System.Collections;
using System.Collections.Generic;

[ImageEffectAllowedInSceneView]
[ExecuteInEditMode()]
public class NGSS_ContactShadows : MonoBehaviour
{
    public Light mainDirectionalLight;

    [Range(0.0f, 3.0f)]
    public float shadowsSoftness = 1f;
    [Range(1f, 4.0f)]
    public float shadowsDistance = 2f;
    [Range(0.1f, 4.0f)]
	public float shadowsFade = 1f;
	[Range(0.0f, 1.0f)]
	public float rayWidth = 0.1f;
	[Range(16, 128)]
	public int raySamples = 64;
    
    private CommandBuffer blendShadowsCB;
    private CommandBuffer computeShadowsCB;
    private bool isInitialized = false;

    private Camera _mCamera;
    private Camera mCamera
    {
        get
        {
            if (_mCamera == null)
            {
                _mCamera = GetComponent<Camera>();
                if (_mCamera == null) { _mCamera = Camera.main; }
                if (_mCamera == null) { Debug.LogError("NGSS Error: No MainCamera found, please provide one.", this); }
                else { _mCamera.depthTextureMode |= DepthTextureMode.Depth; }
            }
            return _mCamera;
        }
    }

    private Material _mMaterial;
    private Material mMaterial
    {
        get
        {
            if (_mMaterial == null)
            {
                _mMaterial = new Material(Shader.Find("Hidden/NGSS_ContactShadows"));
            }
            return _mMaterial;
        }
    }

    void AddCommandBuffers()
    {
        computeShadowsCB = new CommandBuffer { name = "NGSS ContactShadows: Compute" };
        blendShadowsCB = new CommandBuffer { name = "NGSS ContactShadows: Mix" };
        
        bool forward = mCamera.renderingPath == RenderingPath.Forward;

        if (mCamera)
        {
            foreach (CommandBuffer cb in mCamera.GetCommandBuffers(forward? CameraEvent.AfterDepthTexture : CameraEvent.BeforeLighting)) { if (cb.name == computeShadowsCB.name) { return; } }
            mCamera.AddCommandBuffer(forward ? CameraEvent.AfterDepthTexture : CameraEvent.BeforeLighting, computeShadowsCB);
        }

        if (mainDirectionalLight)
        {
            foreach (CommandBuffer cb in mainDirectionalLight.GetCommandBuffers(LightEvent.AfterScreenspaceMask)) { if (cb.name == blendShadowsCB.name) { return; } }
            mainDirectionalLight.AddCommandBuffer(LightEvent.AfterScreenspaceMask, blendShadowsCB);
        }
        //else { Debug.LogWarning("NGSS Error: No directional light set. Disabling the component, please provide one and re-enable the component again.", this); enabled = false; }
    }

    void RemoveCommandBuffers()
	{
        _mMaterial = null;
        bool forward = mCamera.renderingPath == RenderingPath.Forward;
        if (mCamera) { mCamera.RemoveCommandBuffer(forward ? CameraEvent.AfterDepthTexture : CameraEvent.BeforeLighting, computeShadowsCB); }
        if (mainDirectionalLight) { mainDirectionalLight.RemoveCommandBuffer(LightEvent.AfterScreenspaceMask, blendShadowsCB); }
        isInitialized = false;
    }

	void Init()
	{
        if (isInitialized) { return; }

        if (mCamera.renderingPath != RenderingPath.Forward && mCamera.renderingPath != RenderingPath.DeferredShading)
        {
            Debug.LogWarning("Please set your camera rendering path to either Forward or Defferred and re-add this component to your main camera again.", this);
            enabled = false;
            DestroyImmediate(this);
            return;
        }

        AddCommandBuffers();

        int cShadow = Shader.PropertyToID("NGSS_ContactShadowRT");
		int dSource = Shader.PropertyToID("NGSS_DepthSourceRT");
        
		computeShadowsCB.GetTemporaryRT(cShadow, -1, -1, 0, FilterMode.Bilinear, RenderTextureFormat.R8);
		computeShadowsCB.GetTemporaryRT(dSource, -1, -1, 0, FilterMode.Point, RenderTextureFormat.RFloat);

        computeShadowsCB.Blit(cShadow, dSource, mMaterial, 0);//clip edges
        computeShadowsCB.Blit(dSource, cShadow, mMaterial, 1);//compute ssrt shadows
        computeShadowsCB.Blit(cShadow, dSource, mMaterial, 2);//filter ssrt shadows
        blendShadowsCB.Blit(BuiltinRenderTextureType.None, BuiltinRenderTextureType.CurrentActive, mMaterial, 3);//mix with screen space shadow mask

        computeShadowsCB.SetGlobalTexture("NGSS_ContactShadowsTexture", dSource);

        isInitialized = true;
	}

	void OnEnable()
	{
        if (mainDirectionalLight) { Init(); }
    }

    void OnDisable()
    {
        if (isInitialized) { RemoveCommandBuffers(); }
    }

    void OnApplicationQuit()
	{
        if (isInitialized) { RemoveCommandBuffers(); }
	}

    void OnPreRender()
	{
        if (mainDirectionalLight) { Init(); }
        if (isInitialized == false || mainDirectionalLight == null) { return; }        

        mMaterial.SetVector("LightDir", mCamera.transform.InverseTransformDirection(mainDirectionalLight.transform.forward));
        mMaterial.SetFloat("ShadowsSoftness", shadowsSoftness);
        mMaterial.SetFloat("ShadowsDistance", shadowsDistance);
        mMaterial.SetFloat("ShadowsFade", shadowsFade);
        mMaterial.SetFloat("RayWidth", rayWidth);
        mMaterial.SetInt("RaySamples", raySamples);
    }
}

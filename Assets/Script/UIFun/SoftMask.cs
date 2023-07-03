using UnityEngine;
using UnityEngine.Profiling;
using UnityEngine.Rendering;
using UnityEngine.UI;

[ExecuteAlways]
public class SoftMask : MonoBehaviour
{
	public Image maskImage;
	public bool isShowMaskGraphic;

	[Range(0, 1)]
	public float softness;

	RenderTexture softMaskBuffer;
	RenderTexture SoftMaskBuffer
	{
		get 
		{
			if (softMaskBuffer == null)
			{
				int w, h;
				w = Camera.main.pixelWidth; h = Camera.main.pixelHeight;
				softMaskBuffer = RenderTexture.GetTemporary(w, h, 0, RenderTextureFormat.ARGB32, RenderTextureReadWrite.Default, 1, RenderTextureMemoryless.Depth);
			}
			return softMaskBuffer; 
		}
	}

	Material _material;
	Material material
	{
		get 
		{
			if (_material == null)
			{
				//_material = 
			}
			return _material; 
		}
	}

	CommandBuffer cb;
	MaterialPropertyBlock mpb;

	Mesh _mesh;
	Mesh mesh
	{
		get { return _mesh ? _mesh : _mesh = new Mesh() { hideFlags = HideFlags.HideAndDontSave }; }
	}
	//
	private void OnPreRender()
	{
		//
		//UpdateMaskTextures();
	}

	private void OnEnable()
	{
		cb = new CommandBuffer();
		mpb = new MaterialPropertyBlock();

		Canvas.willRenderCanvases += UpdateMaskTextures;

	}

	private void OnDisable()
	{
		mpb.Clear();
		mpb = null;
		cb.Release();
		cb = null;


		Canvas.willRenderCanvases += UpdateMaskTextures;
	}

	private void Update()
	{
		maskImage.enabled = isShowMaskGraphic;
		//UpdateMaskTextures();

	}

	private void UpdateMaskTextures() 
	{
		Profiler.BeginSample("UpdateMaskTexture");

		Profiler.BeginSample("Initialize CommandBuffer");
		cb.Clear();
		cb.SetRenderTarget(SoftMaskBuffer);
		cb.ClearRenderTarget(false, true, Color.black);
		Profiler.EndSample();

		
		Graphics.ExecuteCommandBuffer(cb);


		Profiler.EndSample();
	}
}

using UnityEngine;
using UnityEngine.Profiling;
using UnityEngine.Rendering;
using UnityEngine.UI;

[ExecuteAlways]
public class SoftMask : Mask, IMeshModifier, IMaterialModifier
{
	[Range(0, 1)]
	public float softness = 1;

	[Range(0f, 1f), Tooltip("The transparency of the whole masked graphic.")]
	public float m_Alpha = 1;

	private static int s_ColorMaskId = Shader.PropertyToID("_ColorMask");
	private static int s_MainTexId = Shader.PropertyToID("_MainTex");
	private static int s_SoftnessId = Shader.PropertyToID("_Softness");
	private static int s_Alpha = Shader.PropertyToID("_Alpha");

	RenderTexture softMaskBuffer;
	public RenderTexture SoftMaskBuffer
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

	Shader s_SoftMaskShader;

	Material _material;
	Material material
	{
		get 
		{
			return _material
				? _material
				: _material =
					new Material(s_SoftMaskShader
						? s_SoftMaskShader
						: s_SoftMaskShader = Resources.Load<Shader>("SoftMask"))
					{ hideFlags = HideFlags.HideAndDontSave };
		}
	}

	CommandBuffer cb;
	MaterialPropertyBlock mpb;

	Mesh _mesh;
	Mesh mesh
	{
		get { return _mesh ? _mesh : _mesh = new Mesh() { hideFlags = HideFlags.HideAndDontSave }; }
	}

	Graphic m_Graphic;

	public Graphic graphic
	{
		get { return m_Graphic ?? (m_Graphic = GetComponent<Graphic>()); }
	}

	void IMeshModifier.ModifyMesh(VertexHelper verts)
	{
		if (isActiveAndEnabled)
		{
			verts.FillMesh(mesh);
		}
	}

	void IMeshModifier.ModifyMesh(Mesh mesh)
	{
		_mesh = mesh;
	}

	private void OnEnable()
	{
		cb = new CommandBuffer();
		mpb = new MaterialPropertyBlock();

		//Canvas.willRenderCanvases += UpdateMaskTextures;

		ShowMask(showMaskGraphic);		
	}

	private void OnDisable()
	{
		mpb.Clear();
		mpb = null;
		cb.Release();
		cb = null;

		//Canvas.willRenderCanvases -= UpdateMaskTextures;
	}

	Image _image;
	Image image 
	{
		get
		{
			if (_image == null)
			{
				_image = GetComponent<Image>();
			}
			return _image;
		}
	}

	public void ShowMask(bool show)
	{
		if (show)
		{
			image.color = new Color(image.color.r, image.color.g, image.color.b, 1);
			//image.material.SetFloat("_ColorMask", 15);//显示RGBA
		}
		else
		{
			image.color = new Color(image.color.r, image.color.g, image.color.b, 0);
			//image.material.SetFloat("_ColorMask", 0);//不显示RGBA
		}

	}

	//当UI重构时调用
	public Material GetModifiedMaterial(Material baseMaterial)
	{
		base.GetModifiedMaterial(baseMaterial);
		UpdateMaskTextures();
		return baseMaterial;
	}

	private void UpdateMaskTextures() 
	{
		Profiler.BeginSample("UpdateMaskTexture");

		Profiler.BeginSample("Initialize CommandBuffer");
		cb.name = "UpdateMaskTexture";
		cb.Clear();
		cb.SetRenderTarget(SoftMaskBuffer);
		cb.ClearRenderTarget(false, true, Color.black);
		Profiler.EndSample();

		SetViewProjectionMatrices();

		material.SetInt(s_ColorMaskId, 8);//只显示R通道
		mpb.SetTexture(s_MainTexId, graphic.mainTexture);
		mpb.SetFloat(s_SoftnessId, softness);
		mpb.SetFloat(s_Alpha, m_Alpha);

		cb.DrawMesh(mesh, transform.localToWorldMatrix, material, 0, 0, mpb);

		Graphics.ExecuteCommandBuffer(cb);

		Profiler.EndSample();
	}

	void SetViewProjectionMatrices()
	{
		// Set view and projection matrices.
		Profiler.BeginSample("Set view and projection matrices");
		Canvas c = graphic.canvas.rootCanvas;
		Camera cam = c.worldCamera ?? Camera.main;
		if (c && c.renderMode != RenderMode.ScreenSpaceOverlay && cam)
		{
			var p = GL.GetGPUProjectionMatrix(cam.projectionMatrix, false);
			cb.SetViewProjectionMatrices(cam.worldToCameraMatrix, p);
		}
		else
		{
			var pos = c.transform.position;
			var vm = Matrix4x4.TRS(new Vector3(-pos.x, -pos.y, -1000), Quaternion.identity, new Vector3(1, 1, -1f));
			var pm = Matrix4x4.TRS(new Vector3(0, 0, -1), Quaternion.identity, new Vector3(1 / pos.x, 1 / pos.y, -2 / 10000f));
			cb.SetViewProjectionMatrices(vm, pm);
		}

		Profiler.EndSample();
	}

	public void ReleaseMaskBuffer()
	{
		ReleaseRT(ref softMaskBuffer);
	}

	private void ReleaseRT(ref RenderTexture tmpRT)
	{
		if (!tmpRT) return;

		tmpRT.Release();
		RenderTexture.ReleaseTemporary(tmpRT);
		tmpRT = null;
	}
}

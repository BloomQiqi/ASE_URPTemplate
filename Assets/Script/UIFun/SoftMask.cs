using UnityEngine;
using UnityEngine.Profiling;
using UnityEngine.Rendering;
using UnityEngine.UI;

[ExecuteAlways, RequireComponent(typeof(Image))]
public class SoftMask : Mask, IMeshModifier, IMaterialModifier
{
	/// <summary>
	/// Down sampling rate.
	/// </summary>
	public enum DownSamplingRate
	{
		None = 0,
		x1 = 1,
		x2 = 2,
		x4 = 4,
		x8 = 8,
	}

	[Range(0, 1)]
	public float softness = 1;

	[Range(0f, 1f), Tooltip("The transparency of the whole masked graphic.")]
	public float m_Alpha = 1;

	[Header("Advanced Options")]
	[SerializeField, Tooltip("Should the soft mask effected by parent soft masks?")]
	private bool m_EffectByParent = true;
	public bool M_EffectByParent 
	{
		get 
		{ 
			return m_EffectByParent; 
		} 
		set 
		{ 
			m_EffectByParent = value;
		}
	}

	private DownSamplingRate m_DownSamplingRate = DownSamplingRate.x4;

	private static int s_ColorMaskId = Shader.PropertyToID("_ColorMask");
	private static int s_MainTexId = Shader.PropertyToID("_MainTex");
	private static int s_SoftnessId = Shader.PropertyToID("_Softness");
	private static int s_Alpha = Shader.PropertyToID("_Alpha");

	private static int s_SoftMaskTexId = Shader.PropertyToID("_SoftMaskTex");

	private bool _hasChanged = false;
	public bool HasChanged
	{
		get { return _hasChanged; }
		set { _hasChanged = value; }
	}

	RenderTexture softMaskBuffer;
	public RenderTexture SoftMaskBuffer
	{
		get 
		{
			if (softMaskBuffer == null)
			{
				int w, h;
				GetDownSamplingSize(m_DownSamplingRate, out w, out h);
				softMaskBuffer = RenderTexture.GetTemporary(w, h, 0, RenderTextureFormat.R8, RenderTextureReadWrite.Default, 1, RenderTextureMemoryless.Depth);
			}
			return softMaskBuffer; 
		}
	}

	Image m_Image;
	public Image Image
	{
		get 
		{ 
			if(m_Image == null)
			{
				m_Image = GetComponent<Image>();
			}
			return m_Image; 
		}
	}

	Material _imageMat;

	Material ImageMaterial
	{
		get 
		{ 
			if(_imageMat == null)
			{
				_imageMat = new Material(Shader.Find("UI/Default"));
				Image.material = _imageMat;
			}
			return Image.material; 
		}
	}


	//Bake Mask Buffer Material
	Material _material;
	Material material
	{
		get 
		{
			return _material
				? _material
				: _material =
					new Material(Shader.Find("UI/SoftMaskBuffer"));
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
		pri_worldPosition = transform.position;
		pri_scale = transform.localScale;
		pri_rotation = transform.rotation;

		//Canvas.willRenderCanvases += UpdateMaskTextures;
		UpdateMaskTextures();
		ShowMask(showMaskGraphic);
		EffectByParent(M_EffectByParent);
		base.OnEnable();
	}

	private void OnDisable()
	{
		mpb.Clear();
		mpb = null;
		cb.Release();
		cb = null;
		base.OnDisable();
		//Canvas.willRenderCanvases -= UpdateMaskTextures;
	}

	protected override void OnRectTransformDimensionsChange()
	{
		HasChanged = true;
	}

	public void ShowMask(bool show)
	{
		if (show != showMaskGraphic)
		{
			ImageMaterial.SetFloat(s_ColorMaskId, show ? (float)ColorWriteMask.All : 0);
		}
	}

	Vector3 pri_worldPosition;
	Vector3 pri_scale;
	Quaternion pri_rotation;

	private void Update()
	{
		DetectTransformChanged();

		if(HasChanged == true)
		{
			UpdateMaskTextures();
			HasChanged = false;
		}
	}

	void DetectTransformChanged()
	{
		if (!pri_worldPosition.Equals(transform.position)) 
		{ 
			HasChanged = true; 
			pri_worldPosition = transform.position;  
		}
		if (!pri_rotation.Equals(transform.rotation)) 
		{
			HasChanged = true;
			pri_rotation = transform.rotation;
		}
		if (!pri_scale.Equals(transform.localScale)) 
		{
			HasChanged = true; 
			pri_scale = transform.localScale;
		}
	}

	//当UI重构时调用
	public override Material GetModifiedMaterial(Material baseMaterial)
	{
		var result = base.GetModifiedMaterial(baseMaterial);
		UpdateMaskTextures();
		return result;
	}

	private void UpdateMaskTextures() 
	{
		if(!enabled) return;
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

	public void EffectByParent(bool isEffected)
	{
		if (isEffected)
		{
			SoftMask parent = SoftMaskable.GetComponentInParentEx<SoftMask>(this);
			if (parent != null)
			{
				if (!TryGetComponent<SoftMaskable>(out SoftMaskable softMaskable))
				{
					gameObject.AddComponent<SoftMaskable>();
				}
				material.SetTexture(s_SoftMaskTexId, parent.SoftMaskBuffer);
			}
		}
		else
		{
			if (TryGetComponent<SoftMaskable>(out SoftMaskable softMaskable))
			{
				DestroyImmediate(softMaskable);
			}
			material.SetTexture(s_SoftMaskTexId, Texture2D.whiteTexture);
		}
		_hasChanged = true;
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

	private static void GetDownSamplingSize(DownSamplingRate rate, out int w, out int h)
	{
		w = Screen.currentResolution.width / (int)rate; 
		h = Screen.currentResolution.height / (int)rate;
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

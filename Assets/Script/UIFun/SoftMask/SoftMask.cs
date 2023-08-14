using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Profiling;
using UnityEngine.Rendering;
using UnityEngine.UI;


namespace UIExtensions
{
	[ExecuteAlways, RequireComponent(typeof(Image))]
	public class SoftMask : Mask, IMeshModifier, IMaterialModifier, ISoftMask
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
		private bool m_EffectByParent = false;
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

		private DownSamplingRate m_DownSamplingRate = DownSamplingRate.x2;

		private static int s_ColorMaskId = Shader.PropertyToID("_ColorMask");
		private static int s_MainTexId = Shader.PropertyToID("_MainTex");
		private static int s_SoftnessId = Shader.PropertyToID("_Softness");
		private static int s_Alpha = Shader.PropertyToID("_Alpha");

		private static int s_SoftMaskTexId = Shader.PropertyToID("_SoftMaskTex");

		//将需要下一帧需要重新生成MaskBufferd的装进队列，等待生成
		static Queue<SoftMask> softMasksQueue = new Queue<SoftMask>();
		

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
				if (m_Image == null)
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
				if (_imageMat == null)
				{
					_imageMat = Image.material;
				}
				return _imageMat;
			}
		}


		//Bake Mask Buffer Material
		Material _material;
		Material material
		{
			get
			{
				if(_material == null)
				{
					_material = new Material(Shader.Find("UI/SoftMaskBuffer"));
					_material.SetInt(s_ColorMaskId, 8);//只显示R通道
				}
				return _material;
			}
		}

		CommandBuffer cb;
		MaterialPropertyBlock mpb;

		Mesh _mesh;
		public Mesh mesh
		{
			get { return _mesh ? _mesh : _mesh = new Mesh() { hideFlags = HideFlags.HideAndDontSave }; }
		}

		Graphic m_Graphic;

		public Graphic graphic
		{
			get { return m_Graphic ?? (m_Graphic = GetComponent<Graphic>()); }
		}

		Vector3 pri_worldPosition;
		Vector3 pri_scale;
		Quaternion pri_rotation;

		List<GameObject> softMaskablePool = new List<GameObject>();

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
			pri_worldPosition = transform.position;
			pri_scale = transform.localScale;
			pri_rotation = transform.rotation;
			if(cb == null)
				cb = new CommandBuffer();
			if(mpb == null)
				mpb = new MaterialPropertyBlock();
			//Canvas.willRenderCanvases += UpdateSoftMask;

			//EffectByParent(M_EffectByParent);
			Rebuild();
			base.OnEnable();
		}

		private void OnDisable()
		{
			//mpb.Clear();
			//mpb = null;
			//cb.Release();
			//cb = null;
			base.OnDisable();

			//Canvas.willRenderCanvases -= UpdateSoftMask;
		}

		protected override void OnRectTransformDimensionsChange()
		{
			base.OnRectTransformDimensionsChange();
			Rebuild();
		}

		protected override void OnTransformParentChanged()
		{
			base.OnTransformParentChanged();
			Rebuild();
		}

		protected void OnTransformChildrenChanged()
		{
			Rebuild();
		}

		public void ShowMask(Material mat, bool show)
		{
			mat.SetFloat(s_ColorMaskId, show ? (float)ColorWriteMask.All : 0);
		}
		private void Update()
		{
			DetectTransformChanged();

			UpdateSoftMask();
		}

		private void OnDestroy()
		{
			base.OnDestroy();

			//StartCoroutine("UpdateMaskdd");
		}

		bool temp = false;

		void DetectTransformChanged()
		{
			temp = false;
			if (Vector3.Distance(pri_worldPosition, transform.position) > 0.01f)
			{
				temp = true;
				pri_worldPosition = transform.position;
			}
			//if (Vector3.Distance(pri_rotation.eulerAngles, transform.eulerAngles) > 5f)
			//{
			//	temp = true;
			//	pri_rotation = transform.rotation;
			//}
			if (Vector3.Distance(pri_scale, transform.localScale) > 0.1f)
			{
				temp = true;
				pri_scale = transform.localScale;
			}
			if(temp)
			{
				Rebuild();
			}
		}

		void Rebuild()
		{
			if (!isActiveAndEnabled) return;
			if(softMasksQueue == null) softMasksQueue = new Queue<SoftMask>();
			if (!softMasksQueue.Contains(this))
			{
				softMasksQueue.Enqueue(this);

				mpb.SetTexture(s_MainTexId, graphic.mainTexture);
				mpb.SetFloat(s_SoftnessId, softness);
				mpb.SetFloat(s_Alpha, m_Alpha);
			}
		}

		public void UpdateSoftMask()
		{
			if(softMasksQueue.Count > 0)
			{
				Profiler.BeginSample("UpdateMaskTexture");

				Profiler.BeginSample("Initialize CommandBuffer");
				cb.name = "UpdateMaskTexture";
				cb.Clear();
				cb.SetRenderTarget(SoftMaskBuffer);
				cb.ClearRenderTarget(false, true, Color.black);
				Profiler.EndSample();

				int count = softMasksQueue.Count;
				SoftMask mask;
				for (int i = 0; i < count; i++)
				{
					mask = softMasksQueue.Dequeue();
					if (!mask || !mask.isActiveAndEnabled) continue;

					SetViewProjectionMatrices(mask.graphic);

					EffectByParent(mask.m_EffectByParent, mask);

					cb.DrawMesh(mask.mesh, mask.transform.localToWorldMatrix, mask.material, 0, 0, mask.mpb);

					//Debug.Log($"SoftMask:Gen Buffer!{mask.transform.name}  {mask.transform.parent.name}");
				}

				Graphics.ExecuteCommandBuffer(cb);

				Profiler.EndSample();
			}
		}

		//当UI重构时调用
		public override Material GetModifiedMaterial(Material baseMaterial)
		{
			var result = base.GetModifiedMaterial(baseMaterial);

			//Rebuild();

			return result;
		}

		private void UpdateSoftMaskables()
		{
			//GetChildrenSoftMaskable();
			//Graphic gr;
			//for (int i = 0; i < softMaskablePool.Count; i++)
			//{
			//	gr = softMaskablePool[i].GetComponent<Graphic>();
			//	//gr?.SetMaterialDirty();
			//}
		}


		private void GetChildrenSoftMaskable()
		{
			SoftMaskable[] softMaskables = transform.GetComponentsInChildren<SoftMaskable>();//不包含未激活
			softMaskablePool.Clear();
			SoftMask temp; 
			for (int i = 0;i < softMaskables.Length; i++)
			{
				temp = SoftMaskHelper.GetComponentInParentEx<SoftMask>(softMaskables[i]);
				if (this.GetInstanceID() == temp?.GetInstanceID())
				{
					softMaskablePool.Add(softMaskables[i].GetThisComponent().gameObject);
				}
			}
		}

		public void EffectByParent(bool isEffected, SoftMask mask)
		{
			if (isEffected)
			{
				SoftMask parent = SoftMaskHelper.GetComponentInParentEx<SoftMask>(mask);
				if (parent != null)
				{
					if (!TryGetComponent<SoftMaskable>(out SoftMaskable softMaskable))
					{
						mask.gameObject.AddComponent<SoftMaskable>();
					}
					mask.material.SetTexture(s_SoftMaskTexId, parent.SoftMaskBuffer);
				}
			}
			else
			{
				if (TryGetComponent<SoftMaskable>(out SoftMaskable softMaskable))
				{
					DestroyImmediate(softMaskable);
				}
				mask.material.SetTexture(s_SoftMaskTexId, Texture2D.whiteTexture);
			}
		}

		void SetViewProjectionMatrices(Graphic graphic)
		{
			// Set view and projection matrices.
			Profiler.BeginSample("Set view and projection matrices");

			if (graphic == null || !graphic.canvas) return;
			var c = graphic.canvas.rootCanvas;
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

#if UNITY_EDITOR
		protected override void OnValidate()
		{
			base.OnValidate();
		}

#endif
	}
}
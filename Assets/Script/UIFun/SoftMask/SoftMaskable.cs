using UnityEngine;
using UnityEngine.UI;
using UnityEngine.EventSystems;
using System.Collections.Generic;
using UnityEngine.Rendering;

namespace UIExtensions
{
	[ExecuteAlways]
	[RequireComponent(typeof(Image))]
	public class SoftMaskable : UIBehaviour, ISoftMaskable, IMaterialModifier
	{
		private static int s_SoftMaskTexId = Shader.PropertyToID("_SoftMaskTex");
		private static int s_ColorMaskId = Shader.PropertyToID("_ColorMask");

		private Material m_Material;

		private Material M_Material
		{
			get
			{
				if (m_Material == null)
				{
					m_Material = new Material(Shader.Find("UI/UI(SoftMaskable)"));
				}
				return m_Material;
			}
		}

		public Material modifiedMaterial { get; private set; }

		[SerializeField]
		private SoftMask _softMask;
		public SoftMask softMask
		{
			get 
			{ 
				return _softMask ? _softMask : SoftMaskHelper.GetComponentInParentEx<SoftMask>(this);
			}
		}

			private Graphic _graphic;
			public Graphic graphic
			{
				get { return _graphic ? _graphic : _graphic = GetComponent<Graphic>(); }
			}

		protected override void OnEnable()
		{
			base.OnEnable();

			_softMask = null;
			//Rebuild();
		}
		protected override void OnDisable()
		{
			base.OnDisable();

			_softMask = null;
			Rebuild();
		}

		Material IMaterialModifier.GetModifiedMaterial(Material baseMaterial)
		{
			_softMask = null;
			modifiedMaterial = null;

			if(!isActiveAndEnabled || !softMask)
			{
				return baseMaterial;
			}

			UpdateSoftMaskBuffer(true);
			modifiedMaterial = M_Material;
			//处理特殊情况
			if(TryGetComponent<SoftMask>(out SoftMask tmask))
			{
				if(tmask.isActiveAndEnabled)
				{
					modifiedMaterial.SetFloat(s_ColorMaskId, tmask.showMaskGraphic ? (float)ColorWriteMask.All : 0);
				}
			}
			
			return modifiedMaterial;
		}

		protected override void OnRectTransformDimensionsChange()
		{
			_softMask = null;
			Rebuild();
		}

		protected override void OnTransformParentChanged()
		{
			base.OnTransformParentChanged();

			if (!isActiveAndEnabled) return;

			_softMask = null;
			Rebuild();
		}

		void Rebuild()
		{
			graphic.SetMaterialDirty();
		}

		public void UpdateSoftMaskBuffer(bool state)
		{
			if(state == true)
			{
				M_Material.SetTexture(s_SoftMaskTexId, softMask?.SoftMaskBuffer);
			}
			else
			{
				M_Material.SetTexture(s_SoftMaskTexId, Texture2D.whiteTexture);
			}
		}

		public Component GetThisComponent()
		{
			return this;
		}
#if UNITY_EDITOR
		/// <summary>
		/// This function is called when the script is loaded or a value is changed in the inspector (Called in the editor only).
		/// </summary>
		protected override void OnValidate()
		{
			Rebuild();
		}

#endif
	}
}
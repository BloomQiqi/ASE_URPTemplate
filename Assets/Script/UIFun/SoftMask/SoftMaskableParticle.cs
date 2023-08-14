using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.EventSystems;

namespace UIExtensions
{
	public class SoftMaskableParticle : UIBehaviour, ISoftMaskable
	{

		ParticleSystemRenderer ps;
		private ParticleSystemRenderer PSRender
		{
			get
			{
				if (ps == null)
				{
					ps = GetComponent<ParticleSystemRenderer>();
				}
				//return ps ? ps : GetComponent<ParticleSystemRenderer>();
				return ps;
			}
		}

		private static int s_SoftMaskTexId = Shader.PropertyToID("_SoftMaskTex");

		private Material m_Material;
		private Material M_Material
		{
			get
			{
				if (m_Material == null)
				{
					m_Material = PSRender.sharedMaterial;
				}
				return m_Material;
			}
		}

		private SoftMask _softMask;
		public SoftMask softMask
		{
			get
			{
				return _softMask ? _softMask : SoftMaskHelper.GetComponentInParentEx<SoftMask>(this);
			}
		}

		public bool HasChanged { get; private set; }

		Vector3 pri_worldPosition;
		Vector3 pri_scale;
		Quaternion pri_rotation;

		protected override void OnEnable()
		{
			pri_worldPosition = transform.position;
			pri_scale = transform.localScale;
			pri_rotation = transform.rotation;
			//RegisterToParent();
			UpdateSoftMaskBuffer(true);
			_softMask = null;
		}
		protected override void OnDisable()
		{
			//UnRegisterToParent();
			//UpdateSoftMaskBuffer();
			_softMask = null;
		}

		protected void Update()
		{
			//DetectTransformChanged();
			if (HasChanged == true)
			{
				UpdateSoftMaskBuffer(true);
			}
		}

		protected override void OnRectTransformDimensionsChange()
		{
			HasChanged = true;
		}

		protected override void OnTransformParentChanged()
		{
			if (!isActiveAndEnabled) return;
			base.OnTransformParentChanged();
			_softMask = null;
			HasChanged = true;
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

		public void UpdateSoftMaskBuffer(bool state)
		{
			if (state) 
			{
				M_Material.SetTexture(s_SoftMaskTexId, softMask.SoftMaskBuffer);
			}
			else
			{
				M_Material.SetTexture(s_SoftMaskTexId, Texture2D.whiteTexture);
			}
			HasChanged = false;
		}

		public Component GetThisComponent()
		{
			return this;
		}
	}
}
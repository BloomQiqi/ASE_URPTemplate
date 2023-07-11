using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Events;
using UnityEngine.Rendering;
using UnityEngine.UI;

[ExecuteAlways]
[RequireComponent(typeof(Image))]
public class SoftMaskable : MonoBehaviour, IMaterialModifier
{
	private static int s_SoftMaskTexId = Shader.PropertyToID("_SoftMaskTex");

	private bool m_HaveSoftMask = false;

	[HideInInspector]
	public bool HasChanged = false;

	private Material m_Material;

	private Material ImageMaterial
	{
		get 
		{
			//return m_Material ? m_Material : m_Material = new Material(Shader.Find("UI/UI(SoftMaskable)"));
			if (m_Material == null)
			{
				m_Material = new Material(Shader.Find("UI/UI(SoftMaskable)"));
				Image.material = m_Material;
			}
			return m_Material;
		}
	}

	private SoftMask _softMask;
	public SoftMask softMask
	{
		get { return _softMask ? _softMask : _softMask = GetComponentInParentEx<SoftMask>(this); }
	}

	private Image m_Image;

	public Image Image { get { return m_Image ? m_Image : m_Image = GetComponent<Image>(); } }

	Material materialForRendering;

	private void OnEnable()
	{
		//GetComponent<Image>().material = Material;
		UpdateMaskBuffer();
		_softMask = null;

	}
	void OnDisable()
	{
		m_Material = null;
		Image.material = null;
		m_HaveSoftMask = false;
	}

	void Update()
	{
		//UpdateMaskBuffer();
		m_HaveSoftMask = GetComponent<SoftMask>() ? true : false;
		//if (softMask?.HasChanged == true) 
		//{
		//	UpdateMaskBuffer();
		//	softMask.HasChanged = false;
		//}
		if (HasChanged == true)
		{
			UpdateMaskBuffer();
			HasChanged = false;
		}
	}

	public Material GetModifiedMaterial(Material baseMaterial)
	{
		if (!isActiveAndEnabled) return baseMaterial;
		////var result = base.GetModifiedMaterial(baseMaterial);
		if (baseMaterial.shader.name.EndsWith("(SoftMaskable)"))
		{
			UpdateMaskBuffer();
		}
		else
		{
			Debug.LogError("Shader 指定错误！");
		}
		return baseMaterial;
	}

	private void UpdateMaskBuffer()
	{
		_softMask = GetComponentInParentEx<SoftMask>(this);
		if (_softMask)
			ImageMaterial.SetTexture(s_SoftMaskTexId, softMask.SoftMaskBuffer);
	}

	private void OnTransformChildrenChanged()
	{
		UpdateMaskBuffer();
	}

	public static T GetComponentInParentEx<T>(Component component, bool includeInactive = false) where T : MonoBehaviour
	{
		if (!component) return null;
		var trans = component.transform.parent;

		while (trans)
		{
			var c = trans.GetComponent<T>();
			if (c && (includeInactive || c.isActiveAndEnabled))
			{
				return c;
			}
			trans = trans.parent;
		}

		return null;
	}

}

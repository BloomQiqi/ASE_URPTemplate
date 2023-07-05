using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

[ExecuteAlways]
[RequireComponent(typeof(Graphic))]
public class SoftMaskable : MonoBehaviour, IMaterialModifier
{
	private static int s_SoftMaskTexId;


	private Material m_Material;

	public Material Material
	{
		get 
		{
			return m_Material ? m_Material : m_Material = new Material(Shader.Find("UI(SoftMaskable)"));
		}
	}


	private SoftMask _softMask;
	public SoftMask softMask
	{
		get { return _softMask ? _softMask : _softMask = GetComponentInParentEx<SoftMask>(this); }
	}

	private void OnEnable()
	{
		s_SoftMaskTexId = Shader.PropertyToID("_SoftMaskTex");
		GetComponent<Image>().material = Material;

		_softMask = null;
	}

	void Update()
	{
		if (transform.hasChanged)
		{
			UpdateMaskBuffer(Material);
		}
	}

	public Material GetModifiedMaterial(Material baseMaterial)
	{
		if (baseMaterial.shader.name.EndsWith("(SoftMaskable)"))
		{
			//baseMaterial.SetTexture(s_SoftMaskTexId, softMask.SoftMaskBuffer);
			//softMask.ReleaseMaskBuffer();
			UpdateMaskBuffer(baseMaterial);
		}
		else
		{
			Debug.LogError("Shader 指定错误！");
		}

		return baseMaterial;
	}

	void UpdateMaskBuffer(Material material)
	{
		material.SetTexture(s_SoftMaskTexId, softMask.SoftMaskBuffer);
	}


	public static T GetComponentInParentEx<T>(Component component, bool includeInactive = false) where T : MonoBehaviour
	{
		if (!component) return null;
		var trans = component.transform;

		while (trans)
		{
			var c = trans.GetComponent<T>();
			if (c && (includeInactive || c.isActiveAndEnabled)) return c;

			trans = trans.parent;
		}

		return null;
	}
}

using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

[ExecuteAlways]
[RequireComponent(typeof(Graphic))]
public class SoftMaskable : MonoBehaviour, IMaterialModifier
{
	private static int s_SoftMaskTexId;


	private SoftMask _softMask;
	public SoftMask softMask
	{
		get { return _softMask ? _softMask : _softMask = GetComponentInParentEx<SoftMask>(this); }
	}

	private void OnEnable()
	{
		s_SoftMaskTexId = Shader.PropertyToID("_SoftMaskTex");

		_softMask = null;
	}


	public Material GetModifiedMaterial(Material baseMaterial)
	{
		if (baseMaterial.shader.name.EndsWith("(SoftMaskable)"))
		{
			baseMaterial.SetTexture(s_SoftMaskTexId, softMask.SoftMaskBuffer);
			//softMask.ReleaseMaskBuffer();
		}
		else
		{
			Debug.LogError("SoftMaskable 的 Shader 指定错误！");
		}

		return baseMaterial;
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

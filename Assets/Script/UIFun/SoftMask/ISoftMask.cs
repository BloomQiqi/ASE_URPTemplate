using System.Collections.Generic;
using UnityEngine;

namespace UIExtensions
{
	public interface ISoftMask
	{
		 void UpdateSoftMask();
	}

	public interface ISoftMaskable
	{
		void UpdateSoftMaskBuffer(bool state);

		Component GetThisComponent();
	}

	public class SoftMaskHelper
	{
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
}

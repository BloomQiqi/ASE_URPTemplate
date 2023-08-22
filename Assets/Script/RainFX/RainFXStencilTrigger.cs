using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class RainFXStencilTrigger : MonoBehaviour
{

	private void OnTriggerEnter(Collider other)
	{
		OpenStencil(true);
		Debug.Log("Trigger Enter!");
	}

	private void OnTriggerExit(Collider other)
	{
		OpenStencil(false);
		Debug.Log("Trigger Exit!");
	}

	void OpenStencil(bool open)
	{
		if (open)
		{
			Shader.SetGlobalFloat("_StencilRef", 2);
		}
		else
		{
			Shader.SetGlobalFloat("_StencilRef", 0);
		}
	}
}

using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

[ExecuteAlways]
public class Test_BoxCollider2D : MonoBehaviour
{
	int uilayer;
	private void Awake()
	{
		uilayer = LayerMask.NameToLayer("UI");
	}
	private void OnTriggerEnter2D(Collider2D collision)
	{
		if(collision.gameObject.layer == uilayer)
		{
			if(collision.gameObject.TryGetComponent<Image>(out Image image))
			{
				image.enabled = true;
				Debug.Log($"OnTriggerEnter2D,{collision.gameObject.name}");
			}
		}
	}
	private void OnTriggerExit2D(Collider2D collision)
	{
		if (collision.gameObject.layer == uilayer)
		{
			if (collision.gameObject.TryGetComponent<Image>(out Image image))
			{
				image.enabled = false;
				Debug.Log($"OnTriggerExit2D,{collision.gameObject.name}");
			}
		}
	}
}

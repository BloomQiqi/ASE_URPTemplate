using UnityEngine;
using System.Collections;

public class ExampleClass : MonoBehaviour
{
	public Transform target;
	Camera cam;

	void Start()
	{
		cam = GetComponent<Camera>();
	}

	void Update()
	{
		Vector3 screenPos = cam.WorldToScreenPoint(target.position);
		Debug.Log("target is " + screenPos.x + " pixels from the left");
		Debug.Log("target is " + screenPos.y + " pixels from the bottom");
	}
}
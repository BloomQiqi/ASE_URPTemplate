using System.Collections;
using System.Collections.Generic;
using UnityEngine;
[ExecuteAlways]
public class CreatePlane : MonoBehaviour
{
	public int xWidth;
	public int zWidth;

	public Vector3 pos = Vector3.zero;
	public GameObject prefab;

	[ContextMenu("CreatePrefabs")]
	void CreatePrefabs()
	{
		float xSize = prefab.GetComponent<MeshRenderer>().bounds.size.x;
		float zSize = prefab.GetComponent<MeshRenderer>().bounds.size.z;
		for (int i = 0; i < xWidth; i++)
		{
			for(int j = 0; j < zWidth; j++)
			{
				Instantiate(prefab, pos + new Vector3(xSize * (i - xWidth / 2), 0, zSize * (j - zWidth / 2)), Quaternion.identity);
			}
		}
	}

	

}

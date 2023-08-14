using System.Collections;
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;

[CustomEditor(typeof(TextMeshProAddBloom)), CanEditMultipleObjects]
public class TextMeshProAddBloomEditor : Editor
{
	static SerializedProperty addBloom;
	private void OnEnable()
	{
		TextMeshProAddBloom tt = (TextMeshProAddBloom)target;
		priAddBloom = tt.AddBloom;
	}
	bool priAddBloom = false;
	public override void OnInspectorGUI()
	{
		base.OnInspectorGUI();
		TextMeshProAddBloom tt = (TextMeshProAddBloom)target;

		if(priAddBloom != tt.AddBloom )
		{
			priAddBloom = tt.AddBloom;
			tt.AddBloomEffect(tt.AddBloom);
		}

		


		serializedObject.ApplyModifiedProperties();//结尾，应用修改，必须有，不然不能修改
	}
}

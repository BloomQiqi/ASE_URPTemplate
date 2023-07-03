using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class SetSoftMaskPivot : MonoBehaviour
{
    Material _material;

    public Transform imageTransform;

	public Canvas parentCanvas;

	Material Material
    {
        get 
        {
            if ( _material == null)
            {
                _material = GetComponent<Image>().material;
            }
            return _material;
        }
    }
    // Start is called before the first frame update

	private void OnPreRender()
	{
		SetPivotPos();
	}

	private void Update()
	{
		SetPivotPos();
	}

	private void OnWillRenderObject()
	{
		SetPivotPos();
	}

	void SetPivotPos()
    {
		Vector4 _PP = Shader.GetGlobalVector("PivotPos");

		Vector4 inputPos = WorldPointToScreenPoint(imageTransform.position);

		Rect cavRect = parentCanvas.pixelRect;

		Debug.Log("Canvas Rect: " + cavRect);

		Shader.SetGlobalVector("PivotPos", inputPos);//local pos

        _PP = Shader.GetGlobalVector("PivotPos");

	}

	public Vector3 GetScreenPosition(GameObject target)
	{
		RectTransform canvasRtm = parentCanvas.GetComponent<RectTransform>();
		float width = canvasRtm.sizeDelta.x;
		float height = canvasRtm.sizeDelta.y;
		Vector3 pos = Camera.main.WorldToScreenPoint(target.transform.position);
		pos.x *= width / Screen.width;
		pos.y *= height / Screen.height;
		pos.x -= width * 0.5f;
		pos.y -= height * 0.5f;
		return pos;
	}

	public static Vector2 WorldPointToScreenPoint(Vector3 worldPoint)
	{
		// Camera.main 世界摄像机
		Vector2 screenPoint = Camera.main.WorldToScreenPoint(worldPoint);
		Debug.Log("Screen Point: " + screenPoint);
		return screenPoint;
	}
}

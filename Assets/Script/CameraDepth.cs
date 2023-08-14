using System.Collections;
using System.Collections.Generic;
using UnityEngine;
[ExecuteAlways]
public class CameraDepth : MonoBehaviour
{
    // Start is called before the first frame update
    void Start()
    {
        Camera camera = GetComponent<Camera>();
        camera.depthTextureMode |= DepthTextureMode.Depth;

	}

    // Update is called once per frame
    void Update()
    {
        
    }
}

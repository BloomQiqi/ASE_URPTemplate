using UnityEngine;

public class NormalCapture : MonoBehaviour
{
	public Shader normalCaptureShader;

	private Camera cam;
	private Material captureMaterial;
	private RenderTexture normalTexture;

	private void Start()
	{
		cam = GetComponent<Camera>();
		captureMaterial = new Material(normalCaptureShader);
		normalTexture = new RenderTexture(Screen.width, Screen.height, 0, RenderTextureFormat.ARGB32);
	}

	private void Update()
	{
		RenderNormals();
	}

	private void RenderNormals()
	{
		// Set the target Render Texture
		Graphics.SetRenderTarget(normalTexture);
		GL.Clear(true, true, Color.clear); // Clear the Render Texture

		// Render the scene with the custom shader
		Graphics.Blit(null, normalTexture, captureMaterial);

		// Reset the render target
		Graphics.SetRenderTarget(null);

		// Use the normalTexture for further processing or display
	}
}

﻿using UnityEngine.Experimental.Rendering;
using UnityEngine.Networking.Types;

namespace UnityEngine.Rendering.Universal
{
	/// <summary>
	/// 附加的后处理Pass
	/// </summary>
	public class AdditionPostProcessPass : ScriptableRenderPass
	{
		//标签名，用于续帧调试器中显示缓冲区名称
		const string CommandBufferTag = "AdditionalPostProcessing Pass";

		// 用于后处理的材质
		Material m_BlitMaterial;
		AdditionalMaterialLibrary m_Materials;
		AdditionalPostProcessData m_Data;

		// 主纹理信息
		RenderTargetIdentifier m_Source;
		RenderTexture m_Tmp;
		// 深度信息
		RenderTargetIdentifier m_Depth;
		// 当前帧的渲染纹理描述
		RenderTextureDescriptor m_Descriptor;
		// 目标相机信息
		RenderTargetHandle m_Destination;

		// 临时的渲染目标
		RenderTargetHandle m_TemporaryColorTexture01;
		RenderTargetHandle m_TemporaryColorTexture02;
		//相机

		//全屏Mesh
		Mesh m_Mesh;
		Mesh Mesh
		{
			get 
			{ 
				if(m_Mesh == null)
					m_Mesh = new Mesh() { hideFlags = HideFlags.HideAndDontSave };
				return m_Mesh; 
			}
		}
		MaterialPropertyBlock m_Mpb;
		MaterialPropertyBlock Mpb
		{
			get
			{
				if (m_Mpb == null)
				{
					m_Mpb = new MaterialPropertyBlock();
				}
				return m_Mpb;
			}
		}

		/// 这里扩展后续的属性参数组件引用
		// 属性参数组件 
		BrightnessSaturationContrast m_BrightnessSaturationContrast;
		Fog m_Fog;
		RainRippleVolume m_RainRippleVolume;
		
		public AdditionPostProcessPass(RenderPassEvent evt, AdditionalPostProcessData data, Material blitMaterial = null)
		{
			renderPassEvent = evt;
			m_Data = data;
			m_Materials = new AdditionalMaterialLibrary(data);
			m_BlitMaterial = blitMaterial;
		}

		public void Setup(in RenderTextureDescriptor baseDescriptor, in RenderTargetIdentifier source, in RenderTargetIdentifier depth, in RenderTargetHandle destination)
		{
			m_Descriptor = baseDescriptor;
			m_Source = source;
			m_Tmp = new RenderTexture(m_Descriptor);
			m_Depth = depth;
			m_Destination = destination;
		}


		/// <summary>
		/// URP会自动调用该执行方法
		/// </summary>
		/// <param name="context"></param>
		/// <param name="renderingData"></param>
		public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
		{
			// 从Volume框架中获取所有堆栈
			var stack = VolumeManager.instance.stack;

			// 从堆栈中查找对应的属性参数组件
			/// 这里扩展后续的属性参数组件获取
			m_BrightnessSaturationContrast = stack.GetComponent<BrightnessSaturationContrast>();
			m_Fog = stack.GetComponent<Fog>();
			m_RainRippleVolume = stack.GetComponent<RainRippleVolume>();
			
			// 从命令缓冲区池中获取一个带标签的渲染命令，该标签名可以在后续帧调试器中见到
			var cmd = CommandBufferPool.Get(CommandBufferTag);

			// 调用渲染函数
			Render(cmd, ref renderingData);

			// 执行命令缓冲区
			context.ExecuteCommandBuffer(cmd);
			// 释放命令缓存
			CommandBufferPool.Release(cmd);
		}

		// 渲染
		void Render(CommandBuffer cmd, ref RenderingData renderingData)
		{
			ref var cameraData = ref renderingData.cameraData;
			bool m_IsStereo = renderingData.cameraData.isStereoEnabled;
			bool isSceneViewCamera = cameraData.isSceneViewCamera;

			/// 这里扩展后续的后处理方法的开关校验
			// 亮度、对比度、饱和度 VolumeComponent是否开启，且非Scene视图摄像机
			if (m_BrightnessSaturationContrast.IsActive() && !isSceneViewCamera)
			{
				SetBrightnessSaturationContrast(cmd, m_Materials.brightnessSaturationContrast);
			}

			if (m_Fog.IsActive())
			{
				SetFog(cmd, m_Materials.fog);
			}

			if (m_RainRippleVolume.IsActive() && !isSceneViewCamera)
			{
				SetRainFx(cmd, ref renderingData);
			}
		}

		RenderTextureDescriptor GetStereoCompatibleDescriptor(int width, int height, int depthBufferBits = 0)
		{
			var desc = m_Descriptor;
			desc.depthBufferBits = depthBufferBits;
			desc.msaaSamples = 1;
			desc.width = width;
			desc.height = height;
			return desc;
		}

		//void BlitSp(Camera camera, CommandBuffer cmd, RenderTargetIdentifier source, RenderTargetIdentifier dest,
		//	RenderTargetIdentifier depth, Material mat, int passIndex, Rect rect, MaterialPropertyBlock mpb = null)
		//{
		//	cmd.SetGlobalTexture("_MainTex", source);
		//	cmd.SetRenderTarget(dest, RenderBufferLoadAction.DontCare, RenderBufferStoreAction.Store,
		//		depth, RenderBufferLoadAction.DontCare, RenderBufferStoreAction.Store);
		//	cmd.ClearRenderTarget(false, false, Color.clear);
		//	cmd.SetViewProjectionMatrices(Matrix4x4.identity, Matrix4x4.identity);
		//	cmd.SetViewport(rect);
		//	cmd.DrawMesh(RenderingUtils.fullscreenMesh, Matrix4x4.identity, mat, 0, passIndex, mpb);
		//	cmd.SetViewProjectionMatrices(camera.worldToCameraMatrix, camera.projectionMatrix);
		//}

		#region 处理材质渲染
		// 亮度、饱和度、对比度渲染
		void SetBrightnessSaturationContrast(CommandBuffer cmd, Material uberMaterial)
		{
			// 写入参数
			uberMaterial.SetFloat("_Brightness", m_BrightnessSaturationContrast.brightness.value);
			uberMaterial.SetFloat("_Saturation", m_BrightnessSaturationContrast.saturation.value);
			uberMaterial.SetFloat("_Contrast", m_BrightnessSaturationContrast.contrast.value);

			// 通过目标相机的渲染信息创建临时缓冲区
			//RenderTextureDescriptor opaqueDesc = m_Descriptor;
			//opaqueDesc.depthBufferBits = 0;
			//cmd.GetTemporaryRT(m_TemporaryColorTexture01.id, opaqueDesc);
			//or
			int tw = m_Descriptor.width;
			int th = m_Descriptor.height;
			var desc = GetStereoCompatibleDescriptor(tw, th);
			m_TemporaryColorTexture01.Init("tmp_BrightnessSaturationContrastRT");
			cmd.GetTemporaryRT(m_TemporaryColorTexture01.id, desc, FilterMode.Bilinear);

			// 通过材质，将计算结果存入临时缓冲区
			cmd.Blit(m_Source, m_TemporaryColorTexture01.Identifier(), uberMaterial);
			// 再从临时缓冲区存入主纹理
			cmd.Blit(m_TemporaryColorTexture01.Identifier(), m_Source);

			// 释放临时RT
			cmd.ReleaseTemporaryRT(m_TemporaryColorTexture01.id);
		}

		/// 这里扩展后处理对材质填充方法
		void SetFog(CommandBuffer cmd, Material uMaterial)
		{
			//parmater from volume component
			int downSample = m_Fog.downSample.value;
			Color fogColor = m_Fog.fogColor.value;
			Color sunFogColor = m_Fog.sunFogColor.value;
			float fogDistanceStart = m_Fog.fogDistanceStart.value;
			float fogDistanceEnd = m_Fog.fogDistanceEnd.value;
			float fogHeightDensity = m_Fog.fogHeightDensity.value;
			float fogHeightEnd = m_Fog.fogHeightEnd.value;
			float heightFalloff = m_Fog.heightFalloff.value;
			float sunFogRange = m_Fog.sunFogRange.value;
			float sunFogIntensity = m_Fog.sunFogIntensity.value;

			//set shader property
			uMaterial.SetColor("_FogColor", fogColor);
			uMaterial.SetColor("_SunFogColor", sunFogColor);
			uMaterial.SetFloat("_FogDistanceStart", fogDistanceStart);
			uMaterial.SetFloat("_FogDistanceEnd", fogDistanceEnd);
			uMaterial.SetFloat("_FogHeightDensity", fogHeightDensity);
			uMaterial.SetFloat("_FogHeightEnd", fogHeightEnd);
			uMaterial.SetFloat("_HeightFalloff", heightFalloff);
			uMaterial.SetFloat("_SunFogRange", sunFogRange);
			uMaterial.SetFloat("_SunFogIntensity", sunFogIntensity);

			//write post process logic code
			int tw = m_Descriptor.width / downSample;
			int th = m_Descriptor.height / downSample;
			RenderTextureDescriptor desc = GetStereoCompatibleDescriptor(tw, th);
			desc.colorFormat = RenderTextureFormat.ARGB32;
			m_TemporaryColorTexture01.Init("tmp_FogRT");
			cmd.GetTemporaryRT(m_TemporaryColorTexture01.id, desc, FilterMode.Bilinear);

			cmd.Blit(m_Source, m_TemporaryColorTexture01.Identifier());
			cmd.Blit(m_TemporaryColorTexture01.Identifier(), m_Source, uMaterial);

			cmd.ReleaseTemporaryRT(m_TemporaryColorTexture01.id);
		}

		///
		void SetRainFx(CommandBuffer cmd, ref RenderingData renderingData)
		{
			//
			m_Materials.rainRippleFX.SetVector("_CameraForward", renderingData.cameraData.camera.transform.forward);

			////计算相机视锥体的方向
			//Vector3[] v3 = new Vector3[4];
			//renderingData.cameraData.camera.CalculateFrustumCorners(new Rect(0,0,1,1), renderingData.cameraData.camera.farClipPlane, Camera.MonoOrStereoscopicEye.Mono, v3);
			//Vector4[] v4 = new Vector4[4];
			//v4[0] = v3[0];
			//v4[1] = v3[1];
			//v4[2] = v3[2];
			//v4[3] = v3[3];
			//m_Materials.rainRippleFX.SetVectorArray("_FrustumDir", v4);
			//m_Materials.rainRippleFX.SetTexture("_CameraDepthTexture",new Texture2D(m_Depth));
			//cmd.SetGlobalTexture("_CameraDepthTexture", m_Depth);
			int tw = m_Descriptor.width;
			int th = m_Descriptor.height;
			var desc = GetStereoCompatibleDescriptor(tw, th);
			m_TemporaryColorTexture01.Init("tmp_RainFXRT");
			cmd.GetTemporaryRT(m_TemporaryColorTexture01.id, desc, FilterMode.Bilinear);
			//创建模板缓冲
			cmd.SetGlobalTexture("_MainTex", m_Source);
			cmd.SetViewProjectionMatrices(Matrix4x4.identity, Matrix4x4.identity);
			cmd.SetViewport(new Rect(0, 0, renderingData.cameraData.camera.pixelWidth, renderingData.cameraData.camera.pixelHeight));
			
			//cmd.Blit( m_Source , m_Tmp);
			//Mpb.SetTexture("_MainTex", m_Tmp);
			
			cmd.DrawMesh(RenderingUtils.fullscreenMesh, Matrix4x4.identity, m_Materials.rainRippleFX);
			cmd.SetViewProjectionMatrices(renderingData.cameraData.camera.worldToCameraMatrix, renderingData.cameraData.camera.projectionMatrix);

			//cmd.Blit(m_Source, m_TemporaryColorTexture01.Identifier(), m_Materials.rainRippleFX);
			//cmd.SetGlobalTexture("_MainTex", m_TemporaryColorTexture01.Identifier());
			//cmd.Blit(m_TemporaryColorTexture01.Identifier(), m_Source);
			//cmd.SetRenderTarget(m_Texture);
			// 释放临时RT
			cmd.ReleaseTemporaryRT(m_TemporaryColorTexture01.id);
			//cmd.ReleaseTemporaryRT(m_TemporaryColorTexture02.id);
			//cmd.ReleaseTemporaryRT(m_Texture);
		}
		#endregion
	}
}

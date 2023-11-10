using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class DoubleSidedRenderPassFeature : ScriptableRendererFeature
{
    class DoubleSidedRenderPass : ScriptableRenderPass
    {
        FilteringSettings m_FilteringSettings;
		//test 设置LightMode类型
		string m_ProfilerTag;
		ProfilingSampler m_ProfilingSampler;
		RenderStateBlock m_RenderStateBlock;
		List<ShaderTagId> m_ShaderTagIdList = new List<ShaderTagId>();
		bool m_IsOpaque;

        static readonly int s_DrawObjectPassDataPropID = Shader.PropertyToID("_DrawObjectPassData");

        public DoubleSidedRenderPass(string profilerTag, bool opaque, RenderPassEvent evt, RenderQueueRange renderQueueRange,
            LayerMask layerMask, StencilState stencilState, int stencilReference)
        {
            m_ProfilerTag = profilerTag;
            m_ProfilingSampler = new ProfilingSampler(profilerTag);
            m_ShaderTagIdList.Add(new ShaderTagId("BackFace"));//要使用的Pass名 对应 Tags{"LightMode" = "BackFace"}
            renderPassEvent = evt;
            m_FilteringSettings = new FilteringSettings(renderQueueRange, layerMask);
            m_RenderStateBlock = new RenderStateBlock(RenderStateMask.Nothing);
            m_IsOpaque = opaque;

            if(stencilState.enabled)
            {
                m_RenderStateBlock.stencilState = stencilState;
                m_RenderStateBlock.stencilReference = stencilReference;
                m_RenderStateBlock.mask = RenderStateMask.Stencil;
            }
        }

		// This method is called before executing the render pass.
		// It can be used to configure render targets and their clear state. Also to create temporary render target textures.
		// When empty this render pass will render to the active camera render target.
		// You should never call CommandBuffer.SetRenderTarget. Instead call <c>ConfigureTarget</c> and <c>ConfigureClear</c>.
		// The render pipeline will ensure target setup and clearing happens in a performant manner.
		public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
        {
        }

        // Here you can implement the rendering logic.
        // Use <c>ScriptableRenderContext</c> to issue drawing commands or execute command buffers
        // https://docs.unity3d.com/ScriptReference/Rendering.ScriptableRenderContext.html
        // You don't have to call ScriptableRenderContext.submit, the render pipeline will call it at specific points in the pipeline.
        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            CommandBuffer cmd = CommandBufferPool.Get(m_ProfilerTag);
			using (new ProfilingScope(cmd, m_ProfilingSampler))
			{
                Vector4 drawObjectPassData = new Vector4(0f, 0f, 0f, m_IsOpaque ? 1f : 0f);
                cmd.SetGlobalVector(s_DrawObjectPassDataPropID, drawObjectPassData);
                context.ExecuteCommandBuffer(cmd);
                cmd.Clear();

                Camera camera = renderingData.cameraData.camera;

				SortingCriteria sortFlags = (m_IsOpaque) ? renderingData.cameraData.defaultOpaqueSortFlags : SortingCriteria.CommonTransparent;
				DrawingSettings drawSettings = CreateDrawingSettings(m_ShaderTagIdList, ref renderingData, sortFlags);

                context.DrawRenderers(renderingData.cullResults, ref drawSettings, ref m_FilteringSettings, ref m_RenderStateBlock);
			}

            context.ExecuteCommandBuffer(cmd);
            CommandBufferPool.Release(cmd);
		}

		// Cleanup any allocated resources that were created during the execution of this render pass.
		public override void OnCameraCleanup(CommandBuffer cmd)
        {
        }
    }

	DoubleSidedRenderPass m_DoubleSidedPass;

    /// <inheritdoc/>
    public override void Create()
    {
        StencilStateData stencilData = new StencilStateData();
        StencilState m_DefaultStencilState = StencilState.defaultValue;
        m_DefaultStencilState.enabled = stencilData.overrideStencilState;
        m_DefaultStencilState.SetCompareFunction(stencilData.stencilCompareFunction);
        m_DefaultStencilState.SetPassOperation(stencilData.passOperation);
        m_DefaultStencilState.SetFailOperation(stencilData.failOperation);
        m_DefaultStencilState.SetZFailOperation(stencilData.zFailOperation);


		m_DoubleSidedPass = new DoubleSidedRenderPass("Render Transparents", false, RenderPassEvent.BeforeRenderingTransparents, RenderQueueRange.all, LayerMask.GetMask("Transparent")
                            , m_DefaultStencilState, 0);

        // Configures where the render pass should be injected.
        m_DoubleSidedPass.renderPassEvent = RenderPassEvent.AfterRenderingOpaques;
    }

    // Here you can inject one or multiple render passes in the renderer.
    // This method is called when setting up the renderer once per-camera.
    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        renderer.EnqueuePass(m_DoubleSidedPass);
    }
}



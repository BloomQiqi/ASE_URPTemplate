namespace UnityEngine.Rendering.Universal
{
	/// <summary>
	/// 材质列表
	/// </summary>
	public class AdditionalMaterialLibrary
	{
		/// 这里扩展后处理材质属性
		public readonly Material brightnessSaturationContrast;
		public readonly Material fog;
		public readonly Material rainRippleFX;

		/// <summary>
		/// 初始化时从配置文件中获取材质
		/// </summary>
		/// <param name="data"></param>
		public AdditionalMaterialLibrary(AdditionalPostProcessData data)
		{
			/// 这里扩展后处理材质的加载
			brightnessSaturationContrast = Load(data.materials.brightnessSaturationContrast);
			fog = Load(data.materials.fog);
			rainRippleFX = Load(data.materials.rainRippleFX);
		}
		Material Load(Material mat)
		{
			if (mat == null)
			{
				Debug.LogError("材质球为空！");
				return null;
			}
			return mat;
		}
		Material Load(Shader shader)
		{
			if (shader == null)
			{
				Debug.LogErrorFormat($"丢失 shader. {GetType().DeclaringType.Name} 渲染通道将不会执行。检查渲染器资源中是否缺少引用。");
				return null;
			}
			else if (!shader.isSupported)
			{
				Debug.LogError($"shader {shader.name} 不被支持。");
				return null;
			}
			Material mat = Resources.Load<Material>("Custom_RenderFeature_Fog");
			return mat;
		}
		Material Load(string matName)
		{
			Material mat = Resources.Load<Material>(matName);
			if (mat == null)
			{
				Debug.LogError($"未成功加载 Name:{matName} 的材质球！");
				return null;
			}
			return mat;
		}

		internal void Cleanup()
		{
			CoreUtils.Destroy(brightnessSaturationContrast);
			CoreUtils.Destroy(fog);
			CoreUtils.Destroy(rainRippleFX);
		}
	}
}

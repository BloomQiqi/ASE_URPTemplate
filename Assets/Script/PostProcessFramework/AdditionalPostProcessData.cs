using System;

namespace UnityEngine.Rendering.Universal
{
	/// <summary>
	/// 附加后处理数据
	/// </summary>
	[Serializable]
	public class AdditionalPostProcessData : ScriptableObject
	{
		[Serializable]
		public sealed class Materials
		{
			///在这里扩展后续其他后处理Material引用
			public Material brightnessSaturationContrast;
			public Material fog;
			public Material rainRippleFX;
		}
		public Materials materials;
	}
}

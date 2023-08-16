using System;

namespace UnityEngine.Rendering.Universal
{
	[System.Serializable, VolumeComponentMenu("Addtional PostProcess Effeccts/RainRippleFX")]
	public sealed class RainRippleVolume : VolumeComponent, IPostProcessComponent
	{
		[Tooltip("是否开启效果")]
		public BoolParameter enableEffect = new BoolParameter(false);
		//[Tooltip("降采样")]
		//public ClampedIntParameter downSample = new ClampedIntParameter(1, 1, 4);

		//public ColorParameter fogColor = new ColorParameter(new Color(0.41f, 0.65f, 1, 1));

		//public ColorParameter sunFogColor = new ColorParameter(new Color(1, 0.83f, 0.65f, 1), true, false, true);//HDR
		//public 

		//public FloatParameter enforce = new FloatParameter(0);

		//public FloatParameter fogDistanceEnd = new FloatParameter(5500);

		//public FloatParameter fogHeightDensity = new FloatParameter(7.5f);

		//public FloatParameter fogHeightEnd = new FloatParameter(1);

		//public ClampedFloatParameter heightFalloff = new ClampedFloatParameter(0.02f, 0f, 0.5f);

		//public FloatParameter sunFogRange = new FloatParameter(50);

		//public ClampedFloatParameter sunFogIntensity = new ClampedFloatParameter(0.3f, 0f, 1f);

		public bool IsActive() => enableEffect.value == true;

		public bool IsTileCompatible() => false;
	}


}
using System.Collections;
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;
using UnityEngine.Rendering;
using static UnityEditor.Experimental.GraphView.GraphView;
[ExecuteAlways]
public class TextMeshProAddBloom : MonoBehaviour
{
    [SerializeField]
    public bool AddBloom;

	int uilayer;
	int mask;
    Volume vo;
    VolumeProfile profile;

	Volume Vol
	{
		get
		{
			if(vo == null)
			{
				gameObject.TryGetComponent<Volume>(out Volume vol);
				vo = vol;
				if (vo == null || !vo.sharedProfile)
				{
					vo = gameObject.AddComponent<Volume>();
					profile = Resources.Load<VolumeProfile>("ArtAssets/TextMeshProBloom");
					vo.sharedProfile = profile;

				}
			}
			return vo;
		}
	}

	private void Awake()
	{
		uilayer = LayerMask.NameToLayer("UI");
		int mask = LayerMask.NameToLayer("Default");
		Debug.Log($"NameToLayer:{uilayer} Mask:{mask}");
		Debug.Log($"NameToLayer:{gameObject.layer} Mask:{LayerMask.LayerToName(gameObject.layer)}");
		AddBloomEffect(AddBloom);
	}

	private void OnEnable()
	{
		AddBloomEffect(AddBloom);
	}
    
	private void OnDisable()
	{
		AddBloomEffect(false);
	}

	private void OnDestroy()
	{
        AddBloomEffect(false);
		RemoveVolume();
	}

	public void AddBloomEffect(bool add)
    {
        if (add)
        {
            VolumeManager.instance.Register(Vol, mask);
		}
        else
        {
			VolumeManager.instance.Unregister(Vol, mask);
			RemoveVolume();
		}
    }

	void RemoveVolume()
	{
		if (Vol && gameObject.activeInHierarchy)
		{
			DestroyImmediate(Vol);
		}
	}


}

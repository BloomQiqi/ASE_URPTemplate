using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;
using UnityEditor;
using System.Linq;



namespace UIExtensions
{
    /// <summary>
    /// SoftMask editor.
    /// </summary>
    [CustomEditor(typeof(SoftMask))]
    [CanEditMultipleObjects]
    public class SoftMaskEditor : Editor
    {
        private const int k_PreviewSize = 128;
        private const string k_PrefsPreview = "SoftMaskEditor_Preview";
        private static readonly List<Graphic> s_Graphics = new List<Graphic>();
        private static bool s_Preview;
        private bool s_EffectByParentChanged = false;

        private void OnEnable()
        {
            s_Preview = EditorPrefs.GetBool(k_PrefsPreview, false);
        }

        public override void OnInspectorGUI()
        {
            base.OnInspectorGUI();

            SoftMask current = target as SoftMask;
            current.GetComponentsInChildren<Graphic>(true, s_Graphics);

            //current.ShowMask(current.showMaskGraphic);

            if (current.M_EffectByParent != s_EffectByParentChanged)
            {
                current.EffectByParent(current.M_EffectByParent, current);
                s_EffectByParentChanged = current.M_EffectByParent;

            }

            //Image currentImage = current.graphic as Image;
            //if (currentImage && IsMaskUI(currentImage.sprite))
            //{
            //    GUILayout.BeginHorizontal();
            //    EditorGUILayout.HelpBox("SoftMask does not recommend to use 'UIMask' sprite as a source image.\n(It contains only small alpha pixels.)\nDo you want to use 'UISprite' instead?", MessageType.Warning);
            //    GUILayout.EndHorizontal();
            //}

            // Preview buffer.
            GUILayout.BeginVertical(EditorStyles.helpBox);
            if (s_Preview != (s_Preview = EditorGUILayout.ToggleLeft("Preview Soft Mask Buffer", s_Preview)))
            {
                EditorPrefs.SetBool(k_PrefsPreview, s_Preview);
            }

            if (s_Preview)
            {
                var tex = current.SoftMaskBuffer;
                var width = tex.width * k_PreviewSize / tex.height;
                EditorGUI.DrawPreviewTexture(GUILayoutUtility.GetRect(width, k_PreviewSize), tex, null, ScaleMode.ScaleToFit);
                Repaint();
            }
            GUILayout.EndVertical();
        }

        //private static bool IsMaskUI(Object obj)
        //{
        //    return obj
        //            && obj.name == "UIMask"
        //            && AssetDatabase.GetAssetPath(obj) == "Resources/unity_builtin_extra";
        //}
    }

}
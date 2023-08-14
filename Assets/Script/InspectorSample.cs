using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

public class InspectorSample : EditorWindow
{
	string PasswordField = "";
	string m_textArea = "";
	float sliders = 0;
	int slidera = 0;
	string BeginToggleGroup = "BeginToggleGroup";
	bool ToggleGroup = false;
	string Textfield = "";
	bool fg = false;
	float sum = 0;
	int count = 0;
	string tag = "aaa";
	int Layerfield = 0;
	string[] pathname = new string[] { "All", "Asset", "..." };
	float minVal = 1;
	float maxVal = 2;
	float minLimit = -5;
	float maxLimit = 5;
	static Vector3 center = new Vector3(1, 2, 3);
	static Vector3 size1 = new Vector3(1, 2, 3);
	Bounds _bounds = new Bounds(center, size1);
	Color m_color = Color.white;
	AnimationCurve m_curve = AnimationCurve.Linear(0, 0, 10, 10);
	Vector2 size = new Vector2(100, 100);
	int flags = 0;
	string[] options = new string[] { "CanJump", "CanShoot", "CanSwim", "Canabc", "Canacc" };
	GameObject game;
	bool showFoldout;
	Vector2 m_vector2 = new Vector2();
	Vector3 m_vector3 = new Vector3();
	Vector4 m_vector4 = new Vector4();
	Transform selectedTransform;
	GameObject selectedGameObject;
	bool fold;
	bool fold2;
	[MenuItem("MyWindow/InspectorSampleWindow")]
	static void window()
	{
		InspectorSample mybianyi = GetWindow<InspectorSample>();
		mybianyi.Show();
	}
	private void OnGUI()
	{

		// GUILayout.Width  控制在窗口中物体所在的宽
		// GUILayout.Height  控制在窗口中物体所在的高
		//它们的返回的类型为GUILayoutOption
		#region GUILayout.Label 提示语句

		GUILayout.Label("我的编译器（My compiler）", GUILayout.Width(50), GUILayout.Height(10)); //提示语句
		#endregion
		#region GUILayout.Button( 按钮
		GUILayout.Label("按钮");
		if (GUILayout.Button("按钮", GUILayout.Width(40), GUILayout.Height(40)))
		{

		}
		#endregion
		#region GUILayout.TextField 文本
		GUILayout.Label("文本（可以输入）");
		Textfield = GUILayout.TextField(Textfield);//单行
												   //参数2 maxLength 最大有效长度
												   // Textfield = GUILayout.TextField(Textfield,5);
		#endregion
		#region GUILayout.Space 空行
		//参数为float类型代表空行的距离
		GUILayout.Space(10);
		#endregion
		#region EditorGUILayout.Toggle 开关（跟Toggle一样）
		fg = EditorGUILayout.Toggle("Toggle", fg);//开关
		#endregion
		#region GUILayout.BeginHorizontal 横向
		GUILayout.BeginHorizontal();//可以在里面存放多个如果不规定大小系统会平均分配大小
		GUILayout.Button("按钮");
		Textfield = GUILayout.TextField(Textfield);
		GUILayout.EndHorizontal();//结束语一定要有
		#endregion
		#region GUILayout.BeginVertical 纵向
		GUILayout.BeginVertical();//可以在里面存放多个如果不规定大小系统会平均分配大小
		GUILayout.Button("按钮");
		Textfield = GUILayout.TextField(Textfield);
		GUILayout.EndVertical();//结束语一定要有
		#endregion
		#region  GUILayout.HorizontalSlider（横） GUILayout.VerticalSlider（纵）  Slider(分横纵 上横下纵)
		sum = GUILayout.HorizontalSlider(sum, 0, 10);
		// sum = GUILayout.VerticalSlider(sum, 0, 10);
		GUILayout.Space(20);
		#endregion
		#region EditorGUILayout.Popup  下拉
		count = EditorGUILayout.Popup("下拉：", count, pathname);
		#endregion
		#region GUILayout.BeginScrollView  滑动列表  
		//两个true可以让横纵两条线显示出了
		//两个false可以让横纵两条线不显示出来
		size = GUILayout.BeginScrollView(size, true, true);

		GUILayout.EndScrollView();
		#endregion
		#region EditorGUILayout.BoundsField （边界输入）   EditorGUILayout.ColorField（颜色输入）  EditorGUILayout.CurveField（曲线输入）   输入框
		//BoundsField 边界输入框
		_bounds = EditorGUILayout.BoundsField("BoundsField:", _bounds);
		//ColorField 颜色输入框
		m_color = EditorGUILayout.ColorField("ColorField:", m_color);
		//CurveField 曲线输入框
		m_curve = EditorGUILayout.CurveField("CurveField:", m_curve);
		#endregion
		#region EditorGUILayout.TagField    tag(标签)
		tag = EditorGUILayout.TagField("TagField:", tag);

		#endregion
		#region   EditorGUILayout.LayerField(可以获取所有的Layer)
		//Layerfield 可以获取所有的Layer
		Layerfield = EditorGUILayout.LayerField("LayerField:", Layerfield);

		#endregion
		#region   EditorGUILayout.MaskField (下拉可以多选)
		flags = EditorGUILayout.MaskField("MaskField:", flags, options);
		//Debug.Log(flags);// 除了数组的第一个是1 后面全是2的幂（幂为对应的下标）   如果多选它们会相加   系统默认会添加Nothing （对应的值0） 和Everything（-1）
		#endregion
		#region EditorGUILayout.ObjectField(选择物体)
		game = (GameObject)EditorGUILayout.ObjectField(game, typeof(GameObject), true);//typeof(类型) 确定好类型系统会自动帮我找到所有的关于这个类型的物体
		#endregion
		#region  EditorGUILayout.Foldout 折叠
		showFoldout = EditorGUILayout.Foldout(showFoldout, "折叠子物体：");
		if (showFoldout)
		{
			EditorGUI.indentLevel++;//缩进级别
			EditorGUILayout.LabelField("折叠块内容1");
			EditorGUI.indentLevel++;
			EditorGUILayout.LabelField("折叠块内容2");
			EditorGUI.indentLevel--;
			EditorGUI.indentLevel--;
			EditorGUILayout.LabelField("折叠块内容3");
		}
		#endregion
		#region EditorGUILayout.BeginToggleGroup(开关)
		ToggleGroup = EditorGUILayout.BeginToggleGroup(BeginToggleGroup, ToggleGroup);
		Textfield = GUILayout.TextField(Textfield);
		EditorGUILayout.EndToggleGroup();
		#endregion
		#region  GUILayout.FlexibleSpace（布局之间左右对齐）
		EditorGUILayout.BeginHorizontal();//开始最外层横向布局
		GUILayout.FlexibleSpace();//布局之间左右对齐
		GUILayout.Label("-----------------分割线-----------------");
		GUILayout.FlexibleSpace();//布局之间左右对齐
		EditorGUILayout.EndHorizontal();
		#endregion
		#region  EditorGUILayout.HelpBox（提示语句）
		EditorGUILayout.HelpBox("HelpBox Error:", MessageType.Error);//红色错误号
		EditorGUILayout.HelpBox("HelpBox Info:", MessageType.Info);//白色提示号
		EditorGUILayout.HelpBox("HelpBox None:", MessageType.None);//解释号
		EditorGUILayout.HelpBox("HelpBox Warning:", MessageType.Warning);//黄色警告号
		#endregion
		#region EditorGUILayout.Slider(Slider)
		sliders = EditorGUILayout.Slider("Slider:", sliders, 0, 10);
		#endregion
		#region  EditorGUILayout.TextArea（text 自适应高）
		m_textArea = EditorGUILayout.TextArea(m_textArea);//可以多行
		#endregion
		#region GUILayout.PasswordField(可以改变成对应的符号)
		EditorGUILayout.BeginHorizontal();
		GUILayout.Label("密码text", GUILayout.Width(60));
		PasswordField = GUILayout.PasswordField(PasswordField, '*');//可以改变成对应的符号
		EditorGUILayout.EndHorizontal();
		#endregion
		#region  EditorGUILayout.Vector2Field  EditorGUILayout.Vector3Field  EditorGUILayout.Vector4Field  
		m_vector2 = EditorGUILayout.Vector2Field("Vector2:", m_vector2);
		m_vector3 = EditorGUILayout.Vector3Field("Vector3:", m_vector3);
		m_vector4 = EditorGUILayout.Vector4Field("Vector4:", m_vector4);
		#endregion
		#region EditorGUILayout.SelectableLabel （可以复制粘贴）
		EditorGUILayout.SelectableLabel("SelectableLabel");
		#endregion
		#region  EditorGUILayout.MinMaxSlider （取值范围）
		EditorGUILayout.LabelField("Min Val:", minVal.ToString());
		EditorGUILayout.LabelField("Max Val:", maxVal.ToString());
		EditorGUILayout.MinMaxSlider("MinMaxSlider", ref minVal, ref maxVal, minLimit, maxLimit);
		//现在最小  现在最大 最小长度 最大长度      
		#endregion
		#region   EditorGUILayout.IntSlider（只能是整数）
		slidera = EditorGUILayout.IntSlider("IntSlider:", slidera, 1, 10);
		#endregion
		#region  EditorGUILayout.InspectorTitlebar（将物体返回回来）
		//Transform selectedTransform = Selection.activeGameObject.transform;
		//GameObject selectedGameObject = Selection.activeGameObject;//选择物体（GameObject）
		//fold = EditorGUILayout.InspectorTitlebar(fold, selectedTransform);
		//fold2 = EditorGUILayout.InspectorTitlebar(fold2, selectedGameObject);
		#endregion
	}
}
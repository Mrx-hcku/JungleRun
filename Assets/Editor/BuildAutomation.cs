#if UNITY_EDITOR
using System.Collections.Generic;
using System.Linq;
using UnityEditor;
using UnityEditor.Animations;
using UnityEditor.SceneManagement;
using UnityEngine;
using UnityEngine.UI;

/// <summary>
/// Headless build automation. Runs inside the GitHub Actions Unity
/// container (batch mode, no human, no Editor UI) via `-executeMethod
/// BuildAutomation.BuildAndroid`. It performs everything a person would
/// normally do by hand in the Editor:
///   1. Fix FBX import settings (Humanoid rig) for character + animations
///   2. Build an AnimatorController wiring Run/Jump/Slide/Death clips
///   3. Assemble the whole scene (player, camera, ground, animals,
///      obstacles, jungle decor, house/victory zone, UI) from assets it
///      finds using the Assets/Models/... folder convention
///   4. Build the Android player
///
/// ASSET FOLDER CONVENTION (see ASSET_SETUP.md for the full guide):
///   Assets/Models/Character/*.fbx        -> the Remy character (with skin)
///   Assets/Models/Animations/Run/*.fbx   -> run clip (without skin)
///   Assets/Models/Animations/Jump/*.fbx  -> jump clip
///   Assets/Models/Animations/Slide/*.fbx -> slide clip
///   Assets/Models/Animations/Death/*.fbx -> death clip
///   Assets/Models/Wolf/*                 -> wolf model (fbx/glb)
///   Assets/Models/Tiger/*                -> tiger model (fbx/glb)
///   Assets/Models/Forest/*               -> ALL forest pack files dumped
///                                            here; categorized below by
///                                            filename keyword
///   Assets/Models/House/*                -> house/neighborhood pack files
/// </summary>
public static class BuildAutomation
{
    private const float DistanceToComplete = 800f;
    private const float GroundLength = 1100f; // a bit more than DistanceToComplete, for margin
    private const float LaneWidth = 2.5f;

    // ---------------------------------------------------------------
    // Entry point called by the GitHub Actions workflow
    // ---------------------------------------------------------------
    public static void BuildAndroid()
    {
        EnsureTags();
        RetargetHumanoidClips();
        AnimatorController animatorController = BuildPlayerAnimatorController();
        BuildScene(animatorController);

        string buildPath = GetBuildPathArg();
        var buildOptions = new BuildPlayerOptions
        {
            scenes = new[] { "Assets/Scenes/Main.unity" },
            locationPathName = buildPath,
            target = BuildTarget.Android,
            options = BuildOptions.None
        };

        var report = BuildPipeline.BuildPlayer(buildOptions);
        Debug.Log($"Build finished: {report.summary.result}, size {report.summary.totalSize} bytes");

        if (report.summary.result != UnityEditor.Build.Reporting.BuildResult.Succeeded)
        {
            EditorApplication.Exit(1);
        }
    }

    private static string GetBuildPathArg()
    {
        string[] args = System.Environment.GetCommandLineArgs();
        for (int i = 0; i < args.Length; i++)
        {
            if (args[i] == "-customBuildPath" && i + 1 < args.Length)
                return args[i + 1];
        }
        return "build/Android/JungleEscapeRunner.apk";
    }

    // ---------------------------------------------------------------
    // Tags
    // ---------------------------------------------------------------
    private static void EnsureTags()
    {
        foreach (var tag in new[] { "Obstacle", "Animal", "Coin", "SafeZone" })
            AddTagIfMissing(tag);
    }

    private static void AddTagIfMissing(string tag)
    {
        SerializedObject tagManager = new SerializedObject(AssetDatabase.LoadAllAssetsAtPath("ProjectSettings/TagManager.asset")[0]);
        SerializedProperty tagsProp = tagManager.FindProperty("tags");

        for (int i = 0; i < tagsProp.arraySize; i++)
            if (tagsProp.GetArrayElementAtIndex(i).stringValue == tag) return;

        tagsProp.InsertArrayElementAtIndex(tagsProp.arraySize);
        tagsProp.GetArrayElementAtIndex(tagsProp.arraySize - 1).stringValue = tag;
        tagManager.ApplyModifiedProperties();
    }

    // ---------------------------------------------------------------
    // FBX import fix — mark character + animation-only files as Humanoid
    // so Mixamo animations retarget correctly onto the character.
    // ---------------------------------------------------------------
    private static void RetargetHumanoidClips()
    {
        List<string> paths = new List<string>();
        paths.AddRange(FindAssetPaths("Assets/Models/Character", new[] { ".fbx" }));
        paths.AddRange(FindAssetPaths("Assets/Models/Animations", new[] { ".fbx" }));

        foreach (var path in paths)
        {
            var importer = AssetImporter.GetAtPath(path) as ModelImporter;
            if (importer == null) continue;
            importer.animationType = ModelImporterAnimationType.Human;
            importer.avatarSetup = ModelImporterAvatarSetup.CreateFromThisModel;
            importer.importAnimation = true;
            EditorUtility.SetDirty(importer);
            importer.SaveAndReimport();
        }
    }

    // ---------------------------------------------------------------
    // Animator Controller
    // ---------------------------------------------------------------
    private static AnimatorController BuildPlayerAnimatorController()
    {
        const string controllerPath = "Assets/Generated/PlayerAnimator.controller";
        System.IO.Directory.CreateDirectory("Assets/Generated");

        var controller = AnimatorController.CreateAnimatorControllerAtPath(controllerPath);
        controller.AddParameter("Speed", AnimatorControllerParameterType.Float);
        controller.AddParameter("Jump", AnimatorControllerParameterType.Trigger);
        controller.AddParameter("Slide", AnimatorControllerParameterType.Trigger);
        controller.AddParameter("Death", AnimatorControllerParameterType.Trigger);

        var rootSm = controller.layers[0].stateMachine;

        AnimationClip runClip = FindAnimationClip("Assets/Models/Animations/Run");
        AnimationClip jumpClip = FindAnimationClip("Assets/Models/Animations/Jump");
        AnimationClip slideClip = FindAnimationClip("Assets/Models/Animations/Slide");
        AnimationClip deathClip = FindAnimationClip("Assets/Models/Animations/Death");

        var runState = rootSm.AddState("Run");
        if (runClip != null) runState.motion = runClip;
        rootSm.defaultState = runState;

        if (jumpClip != null)
        {
            var jumpState = rootSm.AddState("Jump");
            jumpState.motion = jumpClip;
            var toJump = rootSm.AddAnyStateTransition(jumpState);
            toJump.AddCondition(AnimatorConditionMode.If, 0, "Jump");
            toJump.hasExitTime = false;
            toJump.duration = 0.05f;
            var backToRun = jumpState.AddTransition(runState);
            backToRun.hasExitTime = true;
            backToRun.exitTime = 0.9f;
            backToRun.duration = 0.1f;
        }

        if (slideClip != null)
        {
            var slideState = rootSm.AddState("Slide");
            slideState.motion = slideClip;
            var toSlide = rootSm.AddAnyStateTransition(slideState);
            toSlide.AddCondition(AnimatorConditionMode.If, 0, "Slide");
            toSlide.hasExitTime = false;
            toSlide.duration = 0.05f;
            var backToRun = slideState.AddTransition(runState);
            backToRun.hasExitTime = true;
            backToRun.exitTime = 0.9f;
            backToRun.duration = 0.1f;
        }

        if (deathClip != null)
        {
            var deathState = rootSm.AddState("Death");
            deathState.motion = deathClip;
            var toDeath = rootSm.AddAnyStateTransition(deathState);
            toDeath.AddCondition(AnimatorConditionMode.If, 0, "Death");
            toDeath.hasExitTime = false;
            toDeath.duration = 0.05f;
        }

        AssetDatabase.SaveAssets();
        return controller;
    }

    private static AnimationClip FindAnimationClip(string folder)
    {
        foreach (var path in FindAssetPaths(folder, new[] { ".fbx" }))
        {
            var assets = AssetDatabase.LoadAllAssetsAtPath(path);
            foreach (var a in assets)
            {
                if (a is AnimationClip clip && !clip.name.StartsWith("__preview__"))
                    return clip;
            }
        }
        return null;
    }

    // ---------------------------------------------------------------
    // Scene assembly
    // ---------------------------------------------------------------
    private static void BuildScene(AnimatorController animatorController)
    {
        System.IO.Directory.CreateDirectory("Assets/Scenes");
        var scene = EditorSceneManager.NewScene(NewSceneSetup.EmptyScene, NewSceneMode.Single);

        // --- Lighting: dark-ish default directional light for the jungle ---
        GameObject lightGO = new GameObject("Directional Light");
        var light = lightGO.AddComponent<Light>();
        light.type = LightType.Directional;
        light.color = new Color(0.55f, 0.6f, 0.65f);
        light.intensity = 0.7f;
        lightGO.transform.rotation = Quaternion.Euler(50, -30, 0);
        RenderSettings.ambientIntensity = 0.4f;
        RenderSettings.fogColor = new Color(0.05f, 0.08f, 0.05f);
        RenderSettings.fog = true;
        RenderSettings.fogDensity = 0.012f;

        // --- Player ---
        GameObject characterAsset = FindFirstPrefabAsset("Assets/Models/Character");
        GameObject player = new GameObject("Player");
        player.tag = "Player";
        player.transform.position = new Vector3(0, 0, 0);

        GameObject characterInstance = null;
        if (characterAsset != null)
        {
            characterInstance = (GameObject)PrefabUtility.InstantiatePrefab(characterAsset, scene);
            characterInstance.transform.SetParent(player.transform, false);
            characterInstance.transform.localPosition = Vector3.zero;
        }

        var controllerComp = player.AddComponent<CharacterController>();
        controllerComp.center = new Vector3(0, 1f, 0);
        controllerComp.height = 2f;
        controllerComp.radius = 0.35f;

        var animator = player.AddComponent<Animator>();
        animator.runtimeAnimatorController = animatorController;
        if (characterAsset != null)
        {
            var srcImporter = AssetImporter.GetAtPath(AssetDatabase.GetAssetPath(characterAsset)) as ModelImporter;
            if (srcImporter != null) animator.avatar = AssetDatabase.LoadAssetAtPath<Avatar>(AssetDatabase.GetAssetPath(characterAsset));
        }

        var swipeInput = player.AddComponent<SwipeInput>();
        var playerController = player.AddComponent<PlayerController>();
        SetPrivateField(playerController, "animator", animator);
        SetPrivateField(playerController, "swipeInput", swipeInput);

        // Trigger collider child for coin/animal/safezone detection
        GameObject triggerGO = new GameObject("TriggerZone");
        triggerGO.transform.SetParent(player.transform, false);
        var triggerCol = triggerGO.AddComponent<CapsuleCollider>();
        triggerCol.isTrigger = true;
        triggerCol.height = 2f;
        triggerCol.radius = 0.4f;
        triggerCol.center = new Vector3(0, 1f, 0);
        triggerGO.AddComponent<Rigidbody>().isKinematic = true;

        // --- Camera ---
        GameObject camGO = new GameObject("MainCamera");
        camGO.tag = "MainCamera";
        var cam = camGO.AddComponent<Camera>();
        cam.farClipPlane = 300f;
        camGO.AddComponent<AudioListener>();
        var camFollow = camGO.AddComponent<CameraFollow>();
        SetPrivateField(camFollow, "target", player.transform);

        // --- GameManager + AudioManager ---
        GameObject gmGO = new GameObject("GameManager");
        var gameManager = gmGO.AddComponent<GameManager>();
        var audioManager = gmGO.AddComponent<AudioManager>();
        WireAudioClips(audioManager);

        // --- Jungle environment root ---
        GameObject jungleRoot = new GameObject("JungleEnvironment");
        CreateGroundStrip(jungleRoot.transform, "JungleGround", GroundLength, new Color(0.12f, 0.16f, 0.1f));

        List<GameObject> treeBushGrass = FindPrefabsByKeyword("Assets/Models/Forest", new[] { "tree", "bush", "grass", "plant", "fern" });
        if (treeBushGrass.Count > 0)
        {
            GameObject decorGO = new GameObject("EnvironmentDecorator");
            decorGO.transform.SetParent(jungleRoot.transform, false);
            var decorator = decorGO.AddComponent<EnvironmentDecorator>();
            SetPrivateField(decorator, "propPrefabs", treeBushGrass.ToArray());
            SetPrivateField(decorator, "startZ", 10f);
            SetPrivateField(decorator, "endZ", DistanceToComplete);
        }

        // --- Obstacle / animal spawner ---
        List<GameObject> obstaclePrefabs = WrapPrefabs(FindPrefabsByKeyword("Assets/Models/Forest", new[] { "rock", "log", "stump" }), "Obstacle", "Generated/Obstacles");
        List<GameObject> animalPrefabs = new List<GameObject>();
        animalPrefabs.AddRange(FindPrefabsInFolder("Assets/Models/Wolf"));
        animalPrefabs.AddRange(FindPrefabsInFolder("Assets/Models/Tiger"));
        animalPrefabs = WrapPrefabs(animalPrefabs, "Animal", "Generated/Animals");

        GameObject spawnerGO = new GameObject("Spawner");
        var spawner = spawnerGO.AddComponent<ObstacleSpawner>();
        SetPrivateField(spawner, "player", player.transform);
        SetPrivateField(spawner, "obstaclePrefabs", obstaclePrefabs.ToArray());
        SetPrivateField(spawner, "animalPrefabs", animalPrefabs.ToArray());
        SetPrivateField(spawner, "laneWidth", LaneWidth);

        // --- Home / victory environment root (inactive at start) ---
        GameObject homeRoot = new GameObject("HomeEnvironment");
        CreateGroundStrip(homeRoot.transform, "HomeGround", 200f, new Color(0.55f, 0.55f, 0.5f));

        List<GameObject> houseParts = FindPrefabsInFolder("Assets/Models/House");
        float houseZ = 60f;
        foreach (var housePrefab in houseParts)
        {
            var inst = (GameObject)PrefabUtility.InstantiatePrefab(housePrefab, scene);
            inst.transform.SetParent(homeRoot.transform, false);
            inst.transform.localPosition = new Vector3(0, 0, houseZ);
        }

        GameObject entryPoint = new GameObject("HomeEntryPoint");
        entryPoint.transform.SetParent(homeRoot.transform, false);
        entryPoint.transform.localPosition = new Vector3(0, 0, 5f);

        GameObject safeZoneGO = new GameObject("SafeZoneTrigger");
        safeZoneGO.tag = "SafeZone";
        safeZoneGO.transform.SetParent(homeRoot.transform, false);
        safeZoneGO.transform.localPosition = new Vector3(0, 1f, houseZ - 10f);
        var safeZoneCol = safeZoneGO.AddComponent<BoxCollider>();
        safeZoneCol.isTrigger = true;
        safeZoneCol.size = new Vector3(8f, 4f, 4f);

        GameObject homeLightGO = new GameObject("Home Directional Light");
        var homeLight = homeLightGO.AddComponent<Light>();
        homeLight.type = LightType.Directional;
        homeLight.color = new Color(1f, 0.98f, 0.9f);
        homeLight.intensity = 1.3f;
        homeLightGO.transform.SetParent(homeRoot.transform, false);
        homeLightGO.transform.rotation = Quaternion.Euler(55, -30, 0);

        homeRoot.SetActive(false);

        // --- UI Canvas ---
        GameObject canvasGO = new GameObject("UI_Canvas");
        var canvas = canvasGO.AddComponent<Canvas>();
        canvas.renderMode = RenderMode.ScreenSpaceOverlay;
        var scaler = canvasGO.AddComponent<CanvasScaler>();
        scaler.uiScaleMode = CanvasScaler.ScaleMode.ScaleWithScreenSize;
        scaler.referenceResolution = new Vector2(1080, 1920);
        canvasGO.AddComponent<GraphicRaycaster>();
        canvasGO.AddComponent<UIManager>();

        GameObject eventSystemGO = new GameObject("EventSystem");
        eventSystemGO.AddComponent<UnityEngine.EventSystems.EventSystem>();
        eventSystemGO.AddComponent<UnityEngine.EventSystems.StandaloneInputModule>();

        // Fade overlay (full-screen image + CanvasGroup) for jungle->home transition
        GameObject fadeGO = new GameObject("TransitionFade", typeof(RectTransform), typeof(Image), typeof(CanvasGroup));
        fadeGO.transform.SetParent(canvasGO.transform, false);
        var fadeRt = fadeGO.GetComponent<RectTransform>();
        fadeRt.anchorMin = Vector2.zero;
        fadeRt.anchorMax = Vector2.one;
        fadeRt.offsetMin = Vector2.zero;
        fadeRt.offsetMax = Vector2.zero;
        fadeGO.GetComponent<Image>().color = Color.black;
        var fadeCanvasGroup = fadeGO.GetComponent<CanvasGroup>();
        fadeCanvasGroup.alpha = 0f;
        fadeCanvasGroup.blocksRaycasts = false;

        // --- Wire GameManager fields ---
        SetPrivateField(gameManager, "playerTransform", player.transform);
        SetPrivateField(gameManager, "distanceToComplete", DistanceToComplete);
        SetPrivateField(gameManager, "iceLandEntryPoint", entryPoint.transform);
        SetPrivateField(gameManager, "jungleEnvironmentRoot", jungleRoot);
        SetPrivateField(gameManager, "iceEnvironmentRoot", homeRoot);
        SetPrivateField(gameManager, "transitionFadeCanvas", fadeCanvasGroup);

        EditorSceneManager.SaveScene(scene, "Assets/Scenes/Main.unity");
        EditorBuildSettings.scenes = new[] { new EditorBuildSettingsScene("Assets/Scenes/Main.unity", true) };
    }

    // ---------------------------------------------------------------
    // Audio wiring — finds sound files by filename keyword and assigns
    // them to AudioManager's fields, so the person never has to open
    // the Editor to drag clips onto slots.
    // ---------------------------------------------------------------
    private static void WireAudioClips(AudioManager audioManager)
    {
        var clipMap = new (string field, string[] keywords)[]
        {
            ("footstepRunLoop", new[] { "footstep", "run" }),
            ("jumpSfx",         new[] { "jump" }),
            ("slideSfx",        new[] { "slide" }),
            ("deathSfx",        new[] { "death", "dying" }),
            ("animalGrowlSfx",  new[] { "growl", "roar" }),
            ("coinCollectSfx",  new[] { "coin", "collect" }),
            ("gameOverSfx",     new[] { "gameover", "game_over", "game-over" }),
            ("victorySfx",      new[] { "victory", "win" }),
            ("jungleMusic",     new[] { "jungle", "junglemusic" }),
            ("homeMusic",       new[] { "home", "safe", "housemusic" }),
        };

        List<string> audioPaths = FindAssetPaths("Assets/Audio", new[] { ".mp3", ".wav", ".ogg" });

        foreach (var (field, keywords) in clipMap)
        {
            string match = audioPaths.FirstOrDefault(p =>
            {
                string lower = System.IO.Path.GetFileNameWithoutExtension(p).ToLowerInvariant();
                return keywords.Any(k => lower.Contains(k));
            });
            if (match == null) continue;

            var clip = AssetDatabase.LoadAssetAtPath<AudioClip>(match);
            if (clip != null) SetPrivateField(audioManager, field, clip);
        }
    }

    private static void CreateGroundStrip(Transform parent, string name, float length, Color color)
    {
        GameObject ground = GameObject.CreatePrimitive(PrimitiveType.Cube);
        ground.name = name;
        ground.transform.SetParent(parent, false);
        ground.transform.localScale = new Vector3(20f, 1f, length);
        ground.transform.localPosition = new Vector3(0, -0.5f, length / 2f - 5f);

        var renderer = ground.GetComponent<Renderer>();
        var mat = new Material(Shader.Find("Standard")) { color = color };
        renderer.sharedMaterial = mat;
    }

    // ---------------------------------------------------------------
    // Asset discovery helpers
    // ---------------------------------------------------------------
    private static List<string> FindAssetPaths(string folder, string[] extensions)
    {
        List<string> result = new List<string>();
        if (!AssetDatabase.IsValidFolder(folder)) return result;

        string[] guids = AssetDatabase.FindAssets("", new[] { folder });
        foreach (var guid in guids)
        {
            string path = AssetDatabase.GUIDToAssetPath(guid);
            if (extensions.Any(ext => path.ToLowerInvariant().EndsWith(ext)))
                result.Add(path);
        }
        return result.Distinct().ToList();
    }

    private static GameObject FindFirstPrefabAsset(string folder)
    {
        var paths = FindAssetPaths(folder, new[] { ".fbx", ".glb", ".gltf", ".obj" });
        foreach (var p in paths)
        {
            var go = AssetDatabase.LoadAssetAtPath<GameObject>(p);
            if (go != null) return go;
        }
        return null;
    }

    private static List<GameObject> FindPrefabsInFolder(string folder)
    {
        List<GameObject> result = new List<GameObject>();
        foreach (var p in FindAssetPaths(folder, new[] { ".fbx", ".glb", ".gltf", ".obj" }))
        {
            var go = AssetDatabase.LoadAssetAtPath<GameObject>(p);
            if (go != null) result.Add(go);
        }
        return result;
    }

    private static List<GameObject> FindPrefabsByKeyword(string folder, string[] keywords)
    {
        List<GameObject> result = new List<GameObject>();
        foreach (var p in FindAssetPaths(folder, new[] { ".fbx", ".glb", ".gltf", ".obj" }))
        {
            string lower = System.IO.Path.GetFileNameWithoutExtension(p).ToLowerInvariant();
            if (keywords.Any(k => lower.Contains(k)))
            {
                var go = AssetDatabase.LoadAssetAtPath<GameObject>(p);
                if (go != null) result.Add(go);
            }
        }
        return result;
    }

    private static void TagPrefabsRecursively(List<GameObject> prefabs, string tag)
    {
        // superseded by WrapPrefabs — kept as no-op for compatibility
    }

    /// <summary>
    /// Creates a new saved prefab per source model that wraps it with a
    /// tagged, trigger-collider root — this is how the tag/collider
    /// actually reach spawned instances (imported model assets can't be
    /// tagged directly in a way that survives).
    /// </summary>
    private static List<GameObject> WrapPrefabs(List<GameObject> sources, string tag, string subFolder)
    {
        string folder = "Assets/" + subFolder;
        System.IO.Directory.CreateDirectory(folder);
        List<GameObject> wrapped = new List<GameObject>();

        foreach (var src in sources)
        {
            if (src == null) continue;
            GameObject wrapper = new GameObject(src.name + "_Wrapped");
            wrapper.tag = tag;
            var visual = (GameObject)PrefabUtility.InstantiatePrefab(src);
            visual.transform.SetParent(wrapper.transform, false);

            var col = wrapper.AddComponent<BoxCollider>();
            col.isTrigger = true;
            col.size = new Vector3(1.5f, 2f, 1.5f);
            col.center = new Vector3(0, 1f, 0);

            string prefabPath = $"{folder}/{src.name}_Wrapped.prefab";
            var savedPrefab = PrefabUtility.SaveAsPrefabAsset(wrapper, prefabPath);
            Object.DestroyImmediate(wrapper);
            wrapped.Add(savedPrefab);
        }
        return wrapped;
    }

    // ---------------------------------------------------------------
    // Reflection helper to set private [SerializeField] fields
    // ---------------------------------------------------------------
    private static void SetPrivateField(object target, string fieldName, object value)
    {
        var so = new SerializedObject(target as Object);
        var prop = so.FindProperty(fieldName);
        if (prop == null)
        {
            Debug.LogWarning($"BuildAutomation: field '{fieldName}' not found on {target.GetType().Name}");
            return;
        }

        switch (prop.propertyType)
        {
            case SerializedPropertyType.ObjectReference:
                prop.objectReferenceValue = value as Object;
                break;
            case SerializedPropertyType.Float:
                prop.floatValue = (float)value;
                break;
            case SerializedPropertyType.Integer:
                prop.intValue = (int)value;
                break;
            case SerializedPropertyType.Generic when value is GameObject[] arr:
                prop.arraySize = arr.Length;
                for (int i = 0; i < arr.Length; i++)
                    prop.GetArrayElementAtIndex(i).objectReferenceValue = arr[i];
                break;
        }
        so.ApplyModifiedPropertiesWithoutUndo();
    }
}
#endif

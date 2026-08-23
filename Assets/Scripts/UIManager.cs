using UnityEngine;
using UnityEngine.UI;

/// <summary>
/// Builds all runtime UI (HUD score/distance, Game Over panel, Victory
/// panel) purely in code at Awake — no Canvas/Text objects need to exist
/// in the scene beforehand. Subscribes to GameManager events for updates.
/// Attach this to an empty GameObject with a Canvas + CanvasScaler +
/// GraphicRaycaster (the build automation adds those); this script fills
/// in the rest.
/// </summary>
[RequireComponent(typeof(Canvas))]
public class UIManager : MonoBehaviour
{
    private Text scoreText;
    private Text distanceText;
    private GameObject gameOverPanel;
    private GameObject victoryPanel;

    private void Awake()
    {
        BuildHud();
        BuildGameOverPanel();
        BuildVictoryPanel();
    }

    private void OnEnable()
    {
        if (GameManager.Instance == null) return;
        GameManager.Instance.OnScoreChanged += HandleScoreChanged;
        GameManager.Instance.OnDistanceChanged += HandleDistanceChanged;
        GameManager.Instance.OnGameOver += HandleGameOver;
        GameManager.Instance.OnVictory += HandleVictory;
    }

    private void OnDisable()
    {
        if (GameManager.Instance == null) return;
        GameManager.Instance.OnScoreChanged -= HandleScoreChanged;
        GameManager.Instance.OnDistanceChanged -= HandleDistanceChanged;
        GameManager.Instance.OnGameOver -= HandleGameOver;
        GameManager.Instance.OnVictory -= HandleVictory;
    }

    private void HandleScoreChanged(int score) => scoreText.text = $"Score: {score}";
    private void HandleDistanceChanged(float dist) => distanceText.text = $"{Mathf.FloorToInt(dist)}m";
    private void HandleGameOver() => gameOverPanel.SetActive(true);
    private void HandleVictory() => victoryPanel.SetActive(true);

    // ---------- UI construction helpers ----------

    private GameObject CreateText(Transform parent, string text, int fontSize, Vector2 anchorMin, Vector2 anchorMax, Vector2 anchoredPos, out Text component)
    {
        GameObject go = new GameObject("Text", typeof(RectTransform), typeof(Text));
        go.transform.SetParent(parent, false);
        var rt = go.GetComponent<RectTransform>();
        rt.anchorMin = anchorMin;
        rt.anchorMax = anchorMax;
        rt.anchoredPosition = anchoredPos;
        rt.sizeDelta = new Vector2(400, 80);

        component = go.GetComponent<Text>();
        component.text = text;
        component.fontSize = fontSize;
        component.alignment = TextAnchor.MiddleCenter;
        component.color = Color.white;
        component.font = Resources.GetBuiltinResource<Font>("LegacyRuntime.ttf");
        return go;
    }

    private GameObject CreatePanel(Transform parent, Color bgColor)
    {
        GameObject go = new GameObject("Panel", typeof(RectTransform), typeof(Image));
        go.transform.SetParent(parent, false);
        var rt = go.GetComponent<RectTransform>();
        rt.anchorMin = Vector2.zero;
        rt.anchorMax = Vector2.one;
        rt.offsetMin = Vector2.zero;
        rt.offsetMax = Vector2.zero;
        go.GetComponent<Image>().color = bgColor;
        return go;
    }

    private Button CreateButton(Transform parent, string label, Vector2 anchoredPos, System.Action onClick)
    {
        GameObject go = new GameObject(label + "Button", typeof(RectTransform), typeof(Image), typeof(Button));
        go.transform.SetParent(parent, false);
        var rt = go.GetComponent<RectTransform>();
        rt.anchoredPosition = anchoredPos;
        rt.sizeDelta = new Vector2(280, 90);
        go.GetComponent<Image>().color = new Color(0.2f, 0.6f, 0.2f);

        CreateText(go.transform, label, 32, Vector2.one * 0.5f, Vector2.one * 0.5f, Vector2.zero, out _);

        var btn = go.GetComponent<Button>();
        btn.onClick.AddListener(() => onClick?.Invoke());
        return btn;
    }

    private void BuildHud()
    {
        GameObject hud = new GameObject("HUD", typeof(RectTransform));
        hud.transform.SetParent(transform, false);
        var rt = hud.GetComponent<RectTransform>();
        rt.anchorMin = Vector2.zero;
        rt.anchorMax = Vector2.one;
        rt.offsetMin = Vector2.zero;
        rt.offsetMax = Vector2.zero;

        CreateText(hud.transform, "Score: 0", 40, new Vector2(0f, 1f), new Vector2(0f, 1f), new Vector2(220, -60), out scoreText);
        scoreText.alignment = TextAnchor.UpperLeft;

        CreateText(hud.transform, "0m", 40, new Vector2(1f, 1f), new Vector2(1f, 1f), new Vector2(-150, -60), out distanceText);
        distanceText.alignment = TextAnchor.UpperRight;
    }

    private void BuildGameOverPanel()
    {
        gameOverPanel = CreatePanel(transform, new Color(0f, 0f, 0f, 0.75f));
        gameOverPanel.name = "GameOverPanel";
        CreateText(gameOverPanel.transform, "GAME OVER", 60, Vector2.one * 0.5f, Vector2.one * 0.5f, new Vector2(0, 100), out _);
        CreateButton(gameOverPanel.transform, "Retry", new Vector2(0, -60), () => GameManager.Instance?.RestartLevel());
        gameOverPanel.SetActive(false);
    }

    private void BuildVictoryPanel()
    {
        victoryPanel = CreatePanel(transform, new Color(0.05f, 0.2f, 0.05f, 0.85f));
        victoryPanel.name = "VictoryPanel";
        CreateText(victoryPanel.transform, "LEVEL CLEARED!", 60, Vector2.one * 0.5f, Vector2.one * 0.5f, new Vector2(0, 100), out _);
        CreateText(victoryPanel.transform, "You made it home safe.", 32, Vector2.one * 0.5f, Vector2.one * 0.5f, new Vector2(0, 30), out _);
        CreateButton(victoryPanel.transform, "Play Again", new Vector2(0, -80), () => GameManager.Instance?.RestartLevel());
        victoryPanel.SetActive(false);
    }
}

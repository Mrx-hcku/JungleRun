using System;
using UnityEngine;
using UnityEngine.SceneManagement;

/// <summary>
/// Central game state controller. Singleton — one instance per scene.
/// Tracks distance/score, drives spawn difficulty, handles Game Over and
/// the jungle -> ice land level-complete transition.
/// </summary>
public class GameManager : MonoBehaviour
{
    public static GameManager Instance { get; private set; }

    public enum GameState { Playing, Transitioning, GameOver, Victory }

    [Header("Player")]
    [SerializeField] private Transform playerTransform;

    [Header("Level Goal")]
    [Tooltip("Distance (meters) the player must cover before the ice-land transition triggers.")]
    [SerializeField] private float distanceToComplete = 800f;

    [Header("Ice Land Transition")]
    [Tooltip("World-space point where the ice biome begins (teleport / fade target).")]
    [SerializeField] private Transform iceLandEntryPoint;
    [SerializeField] private GameObject jungleEnvironmentRoot;
    [SerializeField] private GameObject iceEnvironmentRoot;
    [SerializeField] private CanvasGroup transitionFadeCanvas;
    [SerializeField] private float fadeDuration = 1.2f;

    [Header("UI Hooks")]
    public Action<float> OnDistanceChanged;   // meters
    public Action<int> OnScoreChanged;
    public Action OnGameOver;
    public Action OnVictory;

    public GameState State { get; private set; } = GameState.Playing;

    private float distanceTravelled;
    private int score;
    private float startZ;

    private void Awake()
    {
        if (Instance != null && Instance != this)
        {
            Destroy(gameObject);
            return;
        }
        Instance = this;
    }

    private void Start()
    {
        if (playerTransform != null)
            startZ = playerTransform.position.z;

        if (iceEnvironmentRoot != null)
            iceEnvironmentRoot.SetActive(false);

        if (transitionFadeCanvas != null)
        {
            transitionFadeCanvas.alpha = 0f;
            transitionFadeCanvas.blocksRaycasts = false;
        }

        AudioManager.Instance?.PlayJungleMusic();
    }

    private void Update()
    {
        if (State != GameState.Playing || playerTransform == null) return;

        distanceTravelled = playerTransform.position.z - startZ;
        OnDistanceChanged?.Invoke(distanceTravelled);

        if (distanceTravelled >= distanceToComplete)
        {
            BeginIceLandTransition();
        }
    }

    /// <summary>Call from PlayerController when a coin/pickup is collected.</summary>
    public void AddScore(int amount)
    {
        if (State != GameState.Playing) return;
        score += amount;
        OnScoreChanged?.Invoke(score);
    }

    /// <summary>Call from PlayerController (or obstacle trigger) when the player is hit.</summary>
    public void TriggerGameOver()
    {
        if (State != GameState.Playing) return;
        State = GameState.GameOver;
        Time.timeScale = 0f;
        AudioManager.Instance?.PlayGameOver();
        OnGameOver?.Invoke();
    }

    public void RestartLevel()
    {
        Time.timeScale = 1f;
        SceneManager.LoadScene(SceneManager.GetActiveScene().buildIndex);
    }

    /// <summary>
    /// Handles the "jungle goes dark and dangerous -> bright safe ice land" moment.
    /// Uses a screen fade + environment swap rather than a full scene load, so it stays
    /// cheap on Android and avoids an asset-loading hitch mid-run.
    /// </summary>
    private void BeginIceLandTransition()
    {
        State = GameState.Transitioning;
        StartCoroutine(TransitionRoutine());
    }

    private System.Collections.IEnumerator TransitionRoutine()
    {
        // Fade to white/black
        if (transitionFadeCanvas != null)
        {
            transitionFadeCanvas.blocksRaycasts = true;
            float t = 0f;
            while (t < fadeDuration)
            {
                t += Time.deltaTime;
                transitionFadeCanvas.alpha = Mathf.Clamp01(t / fadeDuration);
                yield return null;
            }
            transitionFadeCanvas.alpha = 1f;
        }

        // Swap environments while screen is covered
        if (jungleEnvironmentRoot != null) jungleEnvironmentRoot.SetActive(false);
        if (iceEnvironmentRoot != null) iceEnvironmentRoot.SetActive(true);

        if (playerTransform != null && iceLandEntryPoint != null)
        {
            var cc = playerTransform.GetComponent<CharacterController>();
            if (cc != null) cc.enabled = false; // must disable CC before teleporting transform
            playerTransform.position = iceLandEntryPoint.position;
            playerTransform.rotation = iceLandEntryPoint.rotation;
            if (cc != null) cc.enabled = true;

            startZ = playerTransform.position.z; // reset distance baseline for the new stretch
        }

        AudioManager.Instance?.PlayHomeMusic();

        // Fade back in
        if (transitionFadeCanvas != null)
        {
            float t = 0f;
            while (t < fadeDuration)
            {
                t += Time.deltaTime;
                transitionFadeCanvas.alpha = 1f - Mathf.Clamp01(t / fadeDuration);
                yield return null;
            }
            transitionFadeCanvas.alpha = 0f;
            transitionFadeCanvas.blocksRaycasts = false;
        }

        State = GameState.Playing;
    }

    /// <summary>Call when the player reaches the safe-zone trigger collider in the ice land.</summary>
    public void TriggerVictory()
    {
        if (State != GameState.Playing) return;
        State = GameState.Victory;
        Time.timeScale = 0f;
        AudioManager.Instance?.StopFootsteps();
        AudioManager.Instance?.PlayVictory();
        OnVictory?.Invoke();
    }
}

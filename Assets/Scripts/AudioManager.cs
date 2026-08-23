using UnityEngine;

/// <summary>
/// Central audio hub. Leave any AudioClip field empty for now — the game
/// runs fine without sounds assigned; Play calls simply no-op if a clip
/// is missing. When you add sound files later (Assets/Audio/...), just
/// drag them onto the matching field in the Inspector — no code changes
/// needed.
/// </summary>
public class AudioManager : MonoBehaviour
{
    public static AudioManager Instance { get; private set; }

    [Header("Player SFX")]
    [SerializeField] private AudioClip footstepRunLoop;
    [SerializeField] private AudioClip jumpSfx;
    [SerializeField] private AudioClip slideSfx;
    [SerializeField] private AudioClip deathSfx;

    [Header("Gameplay SFX")]
    [SerializeField] private AudioClip animalGrowlSfx;
    [SerializeField] private AudioClip coinCollectSfx;
    [SerializeField] private AudioClip gameOverSfx;
    [SerializeField] private AudioClip victorySfx;

    [Header("Music")]
    [SerializeField] private AudioClip jungleMusic;   // tense/dark loop
    [SerializeField] private AudioClip homeMusic;      // safe/happy loop

    [Header("Mixer / Volume")]
    [Range(0f, 1f)][SerializeField] private float sfxVolume = 1f;
    [Range(0f, 1f)][SerializeField] private float musicVolume = 0.6f;

    private AudioSource sfxSource;
    private AudioSource loopSource;   // footsteps
    private AudioSource musicSource;

    private void Awake()
    {
        if (Instance != null && Instance != this)
        {
            Destroy(gameObject);
            return;
        }
        Instance = this;
        DontDestroyOnLoad(gameObject);

        sfxSource = gameObject.AddComponent<AudioSource>();
        loopSource = gameObject.AddComponent<AudioSource>();
        loopSource.loop = true;
        musicSource = gameObject.AddComponent<AudioSource>();
        musicSource.loop = true;
    }

    private void PlayOneShot(AudioClip clip)
    {
        if (clip == null || sfxSource == null) return; // silently skip if not assigned yet
        sfxSource.PlayOneShot(clip, sfxVolume);
    }

    public void PlayJump() => PlayOneShot(jumpSfx);
    public void PlaySlide() => PlayOneShot(slideSfx);
    public void PlayDeath() => PlayOneShot(deathSfx);
    public void PlayAnimalGrowl() => PlayOneShot(animalGrowlSfx);
    public void PlayCoinCollect() => PlayOneShot(coinCollectSfx);
    public void PlayGameOver() => PlayOneShot(gameOverSfx);
    public void PlayVictory() => PlayOneShot(victorySfx);

    public void StartFootsteps()
    {
        if (footstepRunLoop == null || loopSource == null) return;
        if (loopSource.clip == footstepRunLoop && loopSource.isPlaying) return;
        loopSource.clip = footstepRunLoop;
        loopSource.volume = sfxVolume;
        loopSource.Play();
    }

    public void StopFootsteps()
    {
        if (loopSource != null && loopSource.isPlaying) loopSource.Stop();
    }

    public void PlayJungleMusic() => PlayMusic(jungleMusic);
    public void PlayHomeMusic() => PlayMusic(homeMusic);

    private void PlayMusic(AudioClip clip)
    {
        if (clip == null || musicSource == null) return;
        if (musicSource.clip == clip && musicSource.isPlaying) return;
        musicSource.clip = clip;
        musicSource.volume = musicVolume;
        musicSource.Play();
    }
}

using UnityEngine;

/// <summary>
/// Spawns obstacle/animal prefabs into one of three lanes ahead of the player.
/// Pools objects to avoid GC spikes on Android. Attach to an empty
/// "Spawner" object; run only while GameManager.State == Playing.
/// </summary>
public class ObstacleSpawner : MonoBehaviour
{
    [Header("Refs")]
    [SerializeField] private Transform player;

    [Header("Spawn Prefabs")]
    [SerializeField] private GameObject[] obstaclePrefabs; // fallen trees, rocks
    [SerializeField] private GameObject[] animalPrefabs;    // wolves, tigers

    [Header("Spawn Tuning")]
    [SerializeField] private float laneWidth = 2.5f;
    [SerializeField] private float spawnDistanceAhead = 40f;
    [SerializeField] private float minSpawnInterval = 1.4f;
    [SerializeField] private float maxSpawnInterval = 2.4f;
    [SerializeField] private float difficultyRampPerMinute = 0.15f; // reduces interval over time

    private float timer;
    private float elapsedMinutes;
    private static readonly int[] Lanes = { -1, 0, 1 };

    private void Update()
    {
        if (GameManager.Instance == null || GameManager.Instance.State != GameManager.GameState.Playing)
            return;

        elapsedMinutes += Time.deltaTime / 60f;
        timer -= Time.deltaTime;

        if (timer <= 0f)
        {
            Spawn();
            float interval = Mathf.Lerp(maxSpawnInterval, minSpawnInterval, Mathf.Clamp01(elapsedMinutes * difficultyRampPerMinute));
            timer = Random.Range(minSpawnInterval, interval + 0.01f);
        }
    }

    private void Spawn()
    {
        if (player == null) return;

        bool spawnAnimal = animalPrefabs.Length > 0 && Random.value > 0.5f;
        GameObject[] pool = spawnAnimal ? animalPrefabs : obstaclePrefabs;
        if (pool.Length == 0) return;

        GameObject prefab = pool[Random.Range(0, pool.Length)];
        int lane = Lanes[Random.Range(0, Lanes.Length)];

        Vector3 spawnPos = player.position
                          + Vector3.forward * spawnDistanceAhead
                          + Vector3.right * (lane * laneWidth);
        spawnPos.y = prefab.transform.position.y; // keep prefab's authored ground offset

        Instantiate(prefab, spawnPos, Quaternion.identity);
    }
}

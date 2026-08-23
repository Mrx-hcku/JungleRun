using System.Collections.Generic;
using UnityEngine;

/// <summary>
/// Scatters decorative props (trees, bushes, grass) off to the sides of the
/// running lane, once, at Start. Purely visual — these are NOT obstacles
/// (those come from ObstacleSpawner). Keeps the jungle from looking empty
/// without needing hand-placed scene layout.
/// </summary>
public class EnvironmentDecorator : MonoBehaviour
{
    [SerializeField] private GameObject[] propPrefabs;
    [SerializeField] private float startZ = 0f;
    [SerializeField] private float endZ = 900f;
    [SerializeField] private float minSideOffset = 3.5f;
    [SerializeField] private float maxSideOffset = 12f;
    [SerializeField] private int propCount = 150;
    [SerializeField] private float groundY = 0f;

    private void Start()
    {
        if (propPrefabs == null || propPrefabs.Length == 0) return;
        Scatter();
    }

    private void Scatter()
    {
        for (int i = 0; i < propCount; i++)
        {
            GameObject prefab = propPrefabs[Random.Range(0, propPrefabs.Length)];
            float z = Random.Range(startZ, endZ);
            float side = Random.value > 0.5f ? 1f : -1f;
            float x = side * Random.Range(minSideOffset, maxSideOffset);
            Vector3 pos = new Vector3(x, groundY, z);
            Quaternion rot = Quaternion.Euler(0f, Random.Range(0f, 360f), 0f);
            Instantiate(prefab, pos, rot, transform);
        }
    }
}

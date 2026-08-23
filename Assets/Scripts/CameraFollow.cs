using UnityEngine;

/// <summary>
/// Smooth chase camera. Follows the player's forward (Z) and vertical (Y)
/// motion tightly but damps lane-change (X) motion so the camera doesn't
/// snap-whip when the player dodges — cheap and stable for mobile.
/// </summary>
public class CameraFollow : MonoBehaviour
{
    [SerializeField] private Transform target;
    [SerializeField] private Vector3 offset = new Vector3(0f, 3.5f, -6f);
    [SerializeField] private float positionSmoothTime = 0.15f;
    [SerializeField] private float lookAheadDistance = 4f;
    [SerializeField] private float rotationSmoothSpeed = 6f;

    private Vector3 velocity = Vector3.zero;

    private void LateUpdate()
    {
        if (target == null) return;

        Vector3 desiredPosition = target.position + offset;
        transform.position = Vector3.SmoothDamp(transform.position, desiredPosition, ref velocity, positionSmoothTime);

        Vector3 lookTarget = target.position + Vector3.forward * lookAheadDistance + Vector3.up * 1f;
        Quaternion desiredRotation = Quaternion.LookRotation(lookTarget - transform.position);
        transform.rotation = Quaternion.Slerp(transform.rotation, desiredRotation, rotationSmoothSpeed * Time.deltaTime);
    }

    public void SetTarget(Transform newTarget) => target = newTarget;
}

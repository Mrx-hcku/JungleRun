using System;
using UnityEngine;

/// <summary>
/// Detects swipe gestures on touch devices (with mouse-drag fallback for
/// testing in the Editor). Fires directional events that PlayerController
/// subscribes to. Keep this as its own component so input and movement
/// logic stay decoupled — swap this out later for button-based input
/// without touching PlayerController.
/// </summary>
public class SwipeInput : MonoBehaviour
{
    [Tooltip("Minimum swipe distance in inches, scaled by screen DPI.")]
    [SerializeField] private float minSwipeDistanceInches = 0.3f;

    public event Action OnSwipeLeft;
    public event Action OnSwipeRight;
    public event Action OnSwipeUp;
    public event Action OnSwipeDown;

    private Vector2 touchStartPos;
    private bool isTracking;
    private float minSwipeDistancePixels;

    private void Awake()
    {
        float dpi = Screen.dpi > 0 ? Screen.dpi : 160f; // fallback for devices reporting 0
        minSwipeDistancePixels = minSwipeDistanceInches * dpi;
    }

    private void Update()
    {
#if UNITY_EDITOR
        HandleMouseInput();
#else
        HandleTouchInput();
#endif
    }

    private void HandleTouchInput()
    {
        if (Input.touchCount == 0) return;

        Touch touch = Input.GetTouch(0);

        switch (touch.phase)
        {
            case TouchPhase.Began:
                touchStartPos = touch.position;
                isTracking = true;
                break;

            case TouchPhase.Ended:
            case TouchPhase.Canceled:
                if (isTracking)
                    EvaluateSwipe(touch.position);
                isTracking = false;
                break;
        }
    }

    private void HandleMouseInput()
    {
        if (Input.GetMouseButtonDown(0))
        {
            touchStartPos = Input.mousePosition;
            isTracking = true;
        }
        else if (Input.GetMouseButtonUp(0) && isTracking)
        {
            EvaluateSwipe(Input.mousePosition);
            isTracking = false;
        }
    }

    private void EvaluateSwipe(Vector2 endPos)
    {
        Vector2 delta = endPos - touchStartPos;

        if (delta.magnitude < minSwipeDistancePixels)
            return; // treat as a tap, ignore

        if (Mathf.Abs(delta.x) > Mathf.Abs(delta.y))
        {
            if (delta.x > 0) OnSwipeRight?.Invoke();
            else OnSwipeLeft?.Invoke();
        }
        else
        {
            if (delta.y > 0) OnSwipeUp?.Invoke();
            else OnSwipeDown?.Invoke();
        }
    }
}

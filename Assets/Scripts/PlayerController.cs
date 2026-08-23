using UnityEngine;

/// <summary>
/// Auto-forward runner controller: 3-lane dodge, jump, slide.
/// Reads swipe input from SwipeInput and drives a CharacterController.
/// Attach to the player rig (boy character), with an Animator for
/// Run/Jump/Slide/Death states and a CharacterController component.
/// </summary>
[RequireComponent(typeof(CharacterController))]
public class PlayerController : MonoBehaviour
{
    [Header("Forward Movement")]
    [SerializeField] private float forwardSpeed = 8f;
    [SerializeField] private float speedIncreasePerSecond = 0.05f;
    [SerializeField] private float maxForwardSpeed = 18f;

    [Header("Lanes")]
    [Tooltip("Distance in meters between adjacent lanes.")]
    [SerializeField] private float laneWidth = 2.5f;
    [SerializeField] private float laneChangeSpeed = 12f;
    private int currentLane = 0; // -1 left, 0 center, 1 right

    [Header("Jump")]
    [SerializeField] private float jumpHeight = 1.6f;
    [SerializeField] private float gravity = -30f;

    [Header("Slide")]
    [SerializeField] private float slideDuration = 0.7f;
    [SerializeField] private float slideColliderHeight = 0.6f;

    [Header("Refs")]
    [SerializeField] private Animator animator;
    [SerializeField] private SwipeInput swipeInput;

    private CharacterController controller;
    private Vector3 verticalVelocity;
    private float standingHeight;
    private Vector3 standingCenter;
    private bool isSliding;
    private float slideTimer;
    private bool isDead;

    private static readonly int AnimSpeed = Animator.StringToHash("Speed");
    private static readonly int AnimJump = Animator.StringToHash("Jump");
    private static readonly int AnimSlide = Animator.StringToHash("Slide");
    private static readonly int AnimDeath = Animator.StringToHash("Death");

    private void Awake()
    {
        controller = GetComponent<CharacterController>();
        standingHeight = controller.height;
        standingCenter = controller.center;
    }

    private void OnEnable()
    {
        if (swipeInput != null)
        {
            swipeInput.OnSwipeLeft += HandleSwipeLeft;
            swipeInput.OnSwipeRight += HandleSwipeRight;
            swipeInput.OnSwipeUp += HandleJump;
            swipeInput.OnSwipeDown += HandleSlide;
        }
    }

    private void OnDisable()
    {
        if (swipeInput != null)
        {
            swipeInput.OnSwipeLeft -= HandleSwipeLeft;
            swipeInput.OnSwipeRight -= HandleSwipeRight;
            swipeInput.OnSwipeUp -= HandleJump;
            swipeInput.OnSwipeDown -= HandleSlide;
        }
    }

    private void Update()
    {
        if (isDead || GameManager.Instance == null || GameManager.Instance.State != GameManager.GameState.Playing)
            return;

        forwardSpeed = Mathf.Min(maxForwardSpeed, forwardSpeed + speedIncreasePerSecond * Time.deltaTime);

        AudioManager.Instance?.StartFootsteps();

        HandleSlideTimer();
        Move();

        if (animator != null)
            animator.SetFloat(AnimSpeed, forwardSpeed);
    }

    private void Move()
    {
        // Forward
        Vector3 forwardMove = Vector3.forward * forwardSpeed;

        // Lane (sideways) — smoothly interpolate local X toward target lane position
        float targetX = currentLane * laneWidth;
        float currentX = transform.position.x;
        float newX = Mathf.MoveTowards(currentX, targetX, laneChangeSpeed * Time.deltaTime);
        float sideDelta = newX - currentX;

        // Gravity / jump
        if (controller.isGrounded && verticalVelocity.y < 0)
            verticalVelocity.y = -2f; // small stick-to-ground force
        verticalVelocity.y += gravity * Time.deltaTime;

        Vector3 motion = forwardMove * Time.deltaTime
                        + new Vector3(sideDelta, 0, 0)
                        + new Vector3(0, verticalVelocity.y * Time.deltaTime, 0);

        controller.Move(motion);
    }

    private void HandleSwipeLeft()
    {
        if (isSliding) return;
        currentLane = Mathf.Max(currentLane - 1, -1);
    }

    private void HandleSwipeRight()
    {
        if (isSliding) return;
        currentLane = Mathf.Min(currentLane + 1, 1);
    }

    private void HandleJump()
    {
        if (!controller.isGrounded || isSliding) return;
        verticalVelocity.y = Mathf.Sqrt(jumpHeight * -2f * gravity);
        animator?.SetTrigger(AnimJump);
        AudioManager.Instance?.PlayJump();
    }

    private void HandleSlide()
    {
        if (isSliding || !controller.isGrounded) return;
        isSliding = true;
        slideTimer = slideDuration;
        controller.height = slideColliderHeight;
        controller.center = new Vector3(standingCenter.x, slideColliderHeight / 2f, standingCenter.z);
        animator?.SetTrigger(AnimSlide);
        AudioManager.Instance?.PlaySlide();
    }

    private void HandleSlideTimer()
    {
        if (!isSliding) return;
        slideTimer -= Time.deltaTime;
        if (slideTimer <= 0f)
        {
            isSliding = false;
            controller.height = standingHeight;
            controller.center = standingCenter;
        }
    }

    /// <summary>
    /// Obstacles/animals should be on a dedicated layer and use a trigger collider,
    /// or call this directly from their own OnCollisionEnter/OnTriggerEnter.
    /// </summary>
    private void OnControllerColliderHit(ControllerColliderHit hit)
    {
        if (isDead) return;

        if (hit.gameObject.CompareTag("Obstacle") || hit.gameObject.CompareTag("Animal"))
        {
            Die();
        }
        else if (hit.gameObject.CompareTag("SafeZone"))
        {
            GameManager.Instance?.TriggerVictory();
        }
    }

    private void OnTriggerEnter(Collider other)
    {
        if (isDead) return;

        if (other.CompareTag("Coin"))
        {
            GameManager.Instance?.AddScore(1);
            AudioManager.Instance?.PlayCoinCollect();
            other.gameObject.SetActive(false);
        }
        else if (other.CompareTag("Obstacle") || other.CompareTag("Animal"))
        {
            if (other.CompareTag("Animal")) AudioManager.Instance?.PlayAnimalGrowl();
            Die();
        }
        else if (other.CompareTag("SafeZone"))
        {
            GameManager.Instance?.TriggerVictory();
        }
    }

    private void Die()
    {
        isDead = true;
        animator?.SetTrigger(AnimDeath);
        AudioManager.Instance?.StopFootsteps();
        AudioManager.Instance?.PlayDeath();
        GameManager.Instance?.TriggerGameOver();
    }
}

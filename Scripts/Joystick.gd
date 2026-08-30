extends Control

@export var base_radius: float = 75.0
@export var knob_radius: float = 35.0

var _touch_index: int = -1
var _center: Vector2 = Vector2.ZERO
var _knob_offset: Vector2 = Vector2.ZERO
var _active: bool = false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	resized.connect(_update_position)
	_update_position()

func _update_position() -> void:
	# Image 2 ke hisaab se exact bottom-left corner padding
	_center = Vector2(base_radius + 45.0, size.y - base_radius - 45.0)
	queue_redraw()

func _draw() -> void:
	var base_alpha: float = 0.35 if _active else 0.2
	var knob_alpha: float = 0.6 if _active else 0.3
	
	# Outer ring matching image style
	draw_circle(_center, base_radius, Color(1, 1, 1, base_alpha))
	draw_circle(_center, base_radius, Color(1, 1, 1, base_alpha + 0.2), false, 3.0)
	
	# Inner knob
	draw_circle(_center + (_knob_offset if _active else Vector2.ZERO), knob_radius, Color(1, 1, 1, knob_alpha))

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and _touch_index == -1:
			# Touch karne par check karein ki wo joystick ke circle ke andar hai ya nahi
			if event.position.distance_to(_center) <= base_radius * 1.5:
				_touch_index = event.index
				_active = true
				_update_knob(event.position)
		elif not event.pressed and event.index == _touch_index:
			_touch_index = -1
			_active = false
			_knob_offset = Vector2.ZERO
			InputState.move_vector = Vector2.ZERO
			queue_redraw()
	elif event is InputEventScreenDrag:
		if event.index == _touch_index:
			_update_knob(event.position)

func _update_knob(pos: Vector2) -> void:
	var offset: Vector2 = pos - _center
	var dist: float = min(offset.length(), base_radius)
	_knob_offset = offset.normalized() * dist if offset.length() > 0.001 else Vector2.ZERO
	InputState.move_vector = _knob_offset / base_radius
	queue_redraw()

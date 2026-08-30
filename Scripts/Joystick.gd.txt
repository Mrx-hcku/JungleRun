extends Control
## Floating virtual joystick. Covers a touch zone (left side of screen,
## sized in HUD.tscn). Shows a faint base circle at all times (so the
## player knows where to touch), which becomes brighter and follows the
## touch position while held. Self-drawn (no textures needed).

@export var base_radius: float = 90.0
@export var knob_radius: float = 42.0

var _touch_index: int = -1
var _home_center: Vector2 = Vector2.ZERO
var _base_center: Vector2 = Vector2.ZERO
var _knob_offset: Vector2 = Vector2.ZERO
var _active: bool = false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	resized.connect(_update_home_position)
	_update_home_position()

func _update_home_position() -> void:
	_home_center = Vector2(base_radius + 60.0, size.y - base_radius - 60.0)
	if not _active:
		_base_center = _home_center
		queue_redraw()

func _draw() -> void:
	var center: Vector2 = _base_center if _active else _home_center
	var base_alpha: float = 0.32 if _active else 0.14
	var knob_alpha: float = 0.5 if _active else 0.22
	draw_circle(center, base_radius, Color(1, 1, 1, base_alpha))
	draw_circle(center, base_radius, Color(1, 1, 1, base_alpha + 0.15), false, 3.0)
	draw_circle(center + (_knob_offset if _active else Vector2.ZERO), knob_radius, Color(1, 1, 1, knob_alpha))

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and _touch_index == -1:
			_touch_index = event.index
			_active = true
			_base_center = event.position
			_knob_offset = Vector2.ZERO
			queue_redraw()
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
	var offset: Vector2 = pos - _base_center
	var dist: float = min(offset.length(), base_radius)
	_knob_offset = offset.normalized() * dist if offset.length() > 0.001 else Vector2.ZERO
	InputState.move_vector = _knob_offset / base_radius
	queue_redraw()

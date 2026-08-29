extends Control
## Floating virtual joystick. Covers a touch zone (left side of screen,
## sized in HUD.tscn) - appears wherever that zone is touched, and writes
## the drag direction into InputState.move_vector every frame it's held.
## Self-drawn (no textures needed).

@export var base_radius: float = 90.0
@export var knob_radius: float = 42.0

var _touch_index: int = -1
var _base_center: Vector2 = Vector2.ZERO
var _knob_offset: Vector2 = Vector2.ZERO
var _active: bool = false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP

func _draw() -> void:
	if not _active:
		return
	draw_circle(_base_center, base_radius, Color(1, 1, 1, 0.16))
	draw_circle(_base_center, base_radius, Color(1, 1, 1, 0.35), false, 3.0)
	draw_circle(_base_center + _knob_offset, knob_radius, Color(1, 1, 1, 0.45))

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

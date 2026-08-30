extends Node
## Autoload singleton: res://Scripts/InputState.gd -> "InputState"
## Bridge between the on-screen joystick (Control, in HUD's CanvasLayer)
## and the 3D Player node. Decouples them so neither needs a direct
## cross-tree node reference.

## Normalized direction from the virtual joystick: x = -1..1 (left/right),
## y = -1..1 (up/down, screen space - negative y = pushed "up" on screen).
## Length 0..1 (0 = centered / not touched).
var move_vector: Vector2 = Vector2.ZERO

## Set to true when the on-screen Jump button is tapped. Player.gd checks
## and clears this every physics frame.
var jump_requested: bool = false

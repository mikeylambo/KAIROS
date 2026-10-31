class_name SimInput
extends RefCounted
## One tick of gameplay input (already quantized through InputLog packing).

var held: int = 0
var pressed: int = 0
var released: int = 0
var move: Vector2 = Vector2.ZERO

func is_held(b: int) -> bool:
	return held & b != 0

func is_pressed(b: int) -> bool:
	return pressed & b != 0

func is_released(b: int) -> bool:
	return released & b != 0

static func from_packed(v: int, prev_held: int) -> SimInput:
	var i := SimInput.new()
	i.held = InputLog.unpack_buttons(v)
	i.move = InputLog.unpack_move(v)
	i.pressed = i.held & ~prev_held
	i.released = prev_held & ~i.held
	return i

## Stick → 8-dir unit vector (22.5° sectors), ZERO inside deadzone.
static func snap8(v: Vector2, deadzone: float = 0.2) -> Vector2:
	if v.length() < deadzone:
		return Vector2.ZERO
	var a: float = round(v.angle() / (PI / 4.0)) * (PI / 4.0)
	return Vector2(cos(a), sin(a)).snapped(Vector2(0.0001, 0.0001)).normalized()

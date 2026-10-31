class_name InputLog
extends RefCounted
## Per-tick input record. Same seed + same log → same run.

const B_JUMP := 1
const B_BURST := 2
const B_LIGHT := 4
const B_HEAVY := 8
const B_TRANSMIT := 16
const B_GUARD := 32
const B_KI := 64
const B_FIELD := 128

var frames: PackedInt32Array = PackedInt32Array()  # buttons | (mx+127)<<8 | (my+127)<<16
var commands: Array = []  # [tick, name, arg]

static func pack(buttons: int, move: Vector2) -> int:
	var mx: int = clampi(int(round(move.x * 100.0)), -100, 100) + 127
	var my: int = clampi(int(round(move.y * 100.0)), -100, 100) + 127
	return (buttons & 0xFF) | (mx << 8) | (my << 16)

static func unpack_buttons(v: int) -> int:
	return v & 0xFF

static func unpack_move(v: int) -> Vector2:
	return Vector2(float(((v >> 8) & 0xFF) - 127) / 100.0, float(((v >> 16) & 0xFF) - 127) / 100.0)

func record(buttons: int, move: Vector2) -> void:
	frames.append(pack(buttons, move))

func command(tick: int, name: String, arg: Variant) -> void:
	commands.append([tick, name, arg])

func commands_at(tick: int) -> Array:
	var out: Array = []
	for c: Array in commands:
		if int(c[0]) == tick:
			out.append(c)
	return out

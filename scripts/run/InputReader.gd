class_name InputReader
extends RefCounted
## Live device input → packed InputLog frame. Accessibility toggles (guard/beam
## hold-vs-toggle) are resolved here so the sim only ever sees "held".

var guard_latched: bool = false
var ki_latched: bool = false
var discard: int = 0

const MAP: Dictionary = {
	"jump": InputLog.B_JUMP, "burst": InputLog.B_BURST, "light": InputLog.B_LIGHT,
	"heavy": InputLog.B_HEAVY, "transmit": InputLog.B_TRANSMIT, "guard": InputLog.B_GUARD,
	"ki": InputLog.B_KI, "burst_field": InputLog.B_FIELD,
}

func read() -> int:
	if discard > 0:
		discard -= 1
		return InputLog.pack(0, Vector2.ZERO)
	var b: int = 0
	for action: String in MAP:
		if Input.is_action_pressed(action):
			b |= int(MAP[action])
	if Profile.setting("guard_toggle"):
		if Input.is_action_just_pressed("guard"):
			guard_latched = not guard_latched
		b = (b | InputLog.B_GUARD) if guard_latched else (b & ~InputLog.B_GUARD)
	if Profile.setting("beam_toggle"):
		if Input.is_action_just_pressed("ki"):
			ki_latched = not ki_latched
		b = (b | InputLog.B_KI) if ki_latched else (b & ~InputLog.B_KI)
	var mv: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down", 0.2)
	return InputLog.pack(b, mv)

## Scene transitions discard input for a few frames (GDD §6).
func discard_for(frames: int) -> void:
	discard = frames
	guard_latched = false
	ki_latched = false

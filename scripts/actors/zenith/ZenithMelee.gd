class_name ZenithMelee
extends RefCounted
## Melee hitbox sweep + hit application (light string, heavy launcher).

const U: float = 32.0

static func hitbox(c: ZenithCombat) -> Rect2:
	var z: Zenith = c.z
	if c.move_id == "heavy":
		var off: Vector2 = c.launch_dir * 1.3 * U
		if absf(c.launch_dir.x) < 0.1:
			off.x += z.facing * 0.6 * U
		var hh: Vector2 = Vector2(1.6, 1.6) * U
		return Rect2(z.pos + off - hh, hh * 2.0)
	var center: Vector2 = z.pos + Vector2(z.facing * (z.half.x + 1.0 * U), -0.1 * U)
	var h: Vector2 = Vector2(1.35, 1.25) * U
	return Rect2(center - h, h * 2.0)

static func sweep(c: ZenithCombat) -> void:
	var box: Rect2 = hitbox(c)
	for e: Object in c.z.sim.enemies_in_rect(box):
		if c.hit_set.has(e):
			continue
		c.hit_set.append(e)
		land(c, e)

static func land(c: ZenithCombat, e: Object) -> void:
	var t: KairosTuning = Tuning.t
	var z: Zenith = c.z
	var b: BuildModifiers = Run.build
	var heavy: bool = c.move_id == "heavy"
	var base: float = t.heavy_damage if heavy else t.light_damage[int(c.move_id.substr(5, 1))]
	var h: Dictionary = {
		"damage": base * Run.power(),
		"kind": &"heavy" if heavy else &"light",
		"dir": c.launch_dir if heavy else Vector2(z.facing, 0),
		"launch": heavy,
		"launch_speed": t.launch_speed * U,
		"hitstun": t.light_hitstun_f,
		"pin": int(b.add(&"pin_f")),
		"crush": b.mul(&"crush"),
		"src": z.pos,
	}
	if not e.take_hit(h):
		return
	z.add_ki(t.ki_per_hit * b.mul(&"ki_gain"))
	z.sim.on_hit_landed(e, h)
	if heavy:
		if e.is_launched():
			c.chase_target = e
			c.chase_t = t.chase_window_f + int(b.add(&"chase_window_f"))
		Run.request_hitstop(t.heavy_hitstop_f)
		Events.launched.emit(e.pos, c.launch_dir)
		Events.flash.emit(1.0)
		Events.shake.emit(6.0)
	else:
		Run.request_hitstop(t.light_hitstop_f)
		Events.shake.emit(2.0)
	if z.state == Zenith.S.TRANSMIT:
		z.state_t = 0

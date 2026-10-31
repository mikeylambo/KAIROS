class_name EffectDef
extends Resource
## One entry of the typed effect vocabulary (BUILD_BRIEF §3).
## kind: "stat_mul" | "stat_add" | "flag" | "on_event_spawn"

@export var kind: String = "stat_mul"
@export var stat: StringName = &""
@export var value: float = 1.0
@export var event: StringName = &""
@export var spawn: StringName = &""

static func make(k: String, s: StringName, v: float = 1.0, ev: StringName = &"", sp: StringName = &"") -> EffectDef:
	var e := EffectDef.new()
	e.kind = k
	e.stat = s
	e.value = v
	e.event = ev
	e.spawn = sp
	return e

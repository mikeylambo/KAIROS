class_name ThreatDef
extends Resource

@export var id: StringName = &"bloom"
@export var display_name: String = "The Bloom"
@export var spread_interval: float = 240.0
@export var lair_time: float = 360.0
@export var phase_hp: PackedFloat32Array = PackedFloat32Array([1400.0, 0.0, 600.0])
@export var core_hp: float = 520.0
@export var telegraph_f: int = 60
@export var clash_need: float = 100.0
@export var clash_drain: float = 22.0
@export var clash_per_press: float = 6.0

class_name DimensionDef
extends Resource

@export var id: StringName = &""
@export var display_name: String = ""
@export var band: int = 1
@export var grounded: bool = true
@export var chunks_wide: int = 6
@export var chunks_tall: int = 1
@export var clock_rate: float = 1.0
## Rule effects applied while inside (same vocabulary as options).
@export var rules: Array[EffectDef] = []
@export var rule_text: String = ""
@export var adaptation_id: StringName = &""
@export var palette: PackedColorArray = PackedColorArray()
@export var music_key: StringName = &""
@export var chunk_pool: StringName = &""
@export var enemy_table: PackedStringArray = PackedStringArray()
@export var enemy_target: int = 10
@export var map_pos: Vector2 = Vector2.ZERO
@export var is_corridor: bool = false

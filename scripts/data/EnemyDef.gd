class_name EnemyDef
extends Resource

@export var id: StringName = &""
@export var display_name: String = ""
@export var behavior: StringName = &"drone"
@export var hp: float = 60.0
@export var armor: int = 0
@export var flies: bool = false
@export var size: Vector2 = Vector2(1.2, 1.2)
@export var speed: float = 8.0
@export var windup_f: int = 30
@export var attack_f: int = 14
@export var recover_f: int = 40
@export var attack_range: float = 6.0
@export var heavy_attack: bool = false
@export var xp: float = 10.0
@export var color: Color = Color(0.5, 0.5, 0.55)

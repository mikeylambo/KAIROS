class_name FxRecipe
extends Resource
## Mirrors SLU FX Lab recipe fields so recipes port to the catalog.

@export var id: StringName = &""
@export var family: StringName = &"spark"
@export var count: int = 8
@export var lifetime: float = 0.25
@export var speed: Vector2 = Vector2(4.0, 12.0)
@export var spread_deg: float = 360.0
@export var size: Vector2 = Vector2(2.0, 6.0)
@export var colors: PackedColorArray = PackedColorArray([Color.WHITE])
@export var shake_px: float = 0.0
@export var flash: float = 0.0
@export var sfx: StringName = &""

class_name ThresholdOptionDef
extends Resource

@export var id: StringName = &""
@export var display_name: String = ""
@export var category: String = "technique"
@export var description: String = ""
@export var effects: Array[EffectDef] = []
@export var power_bonus: float = 0.25
@export var unlocked_by_default: bool = true

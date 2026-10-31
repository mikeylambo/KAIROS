class_name AdaptationDef
extends Resource

@export var id: StringName = &""
@export var display_name: String = ""
@export var glyph: String = ""
@export var description: String = ""
@export var effects: Array[EffectDef] = []
## Dimension this adaptation marks when carried into it.
@export var marks_dimension: StringName = &""
@export var power_bonus: float = 0.35

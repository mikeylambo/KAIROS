extends Node
## Read-only access to data tables.

var t: KairosTuning
var prog: ProgressionDef
var threat: ThreatDef
var fx: FxRecipeSet
var assets: AssetManifest
var audio: AssetManifest
var fade_lines: StringList
var enemies: Dictionary = {}
var adaptations: Dictionary = {}

func _ready() -> void:
	t = load("res://data/tuning.tres")
	prog = load("res://data/progression.tres")
	threat = load("res://data/threats/bloom.tres")
	fx = load("res://data/fx_recipes.tres")
	assets = load("res://data/asset_manifest.tres")
	audio = load("res://data/audio_manifest.tres")
	fade_lines = load("res://data/fade_lines.tres")
	for id: String in ["drone", "brute", "slammer", "gunner", "flyer", "lancer", "bloom_spore"]:
		enemies[StringName(id)] = load("res://data/enemies/%s.tres" % id)
	for id: String in ["weight", "lift"]:
		adaptations[StringName(id)] = load("res://data/adaptations/%s.tres" % id)

func enemy(id: StringName) -> EnemyDef:
	return enemies.get(id)

func adaptation(id: StringName) -> AdaptationDef:
	return adaptations.get(id)

class_name AssetManifest
extends Resource
## key → res:// path. Missing file → caller uses its procedural stand-in.

@export var entries: Dictionary = {}

func resolve(key: StringName) -> String:
	var p: String = entries.get(String(key), "")
	if p != "" and ResourceLoader.exists(p):
		return p
	return ""

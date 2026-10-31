class_name AttackTokens
extends RefCounted
## Max N enemies in Windup/Attack against Zenith at once (GDD AI).

var max_tokens: int = 2
var holders: Array = []

func acquire(e: Object) -> bool:
	if holders.has(e):
		return true
	if holders.size() >= max_tokens:
		return false
	holders.append(e)
	return true

func release(e: Object) -> void:
	holders.erase(e)

func clear() -> void:
	holders.clear()

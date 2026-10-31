class_name ChunkLibrary
extends RefCounted
## Authored chunks, 60×34 tiles each, 8 per slice dimension. Each feature:
## ["floor", x, top, w]  solid from `top` to the chunk bottom
## ["solid"|"oneway", x, y, w, h]
## ["prop", x, y, w, h]   breakable billboard / sign
## ["spawn", x, y]        enemy spawn marker (air or ground)

const W := 60
const H := 34

static func pool(id: StringName) -> Array:
	match id:
		&"threshold":
			return THRESHOLD
		&"leadfall":
			return LEADFALL
		&"skyreach":
			return SKYREACH
		&"bloom_lair":
			return LAIR
		&"corridor":
			return CORRIDOR
	return THRESHOLD

const THRESHOLD: Array = [
	[["floor", 0, 30, 60], ["solid", 6, 24, 8, 6], ["solid", 40, 20, 10, 10], ["prop", 22, 22, 6, 4], ["spawn", 20, 26], ["spawn", 34, 16], ["spawn", 52, 14]],
	[["floor", 0, 30, 60], ["solid", 0, 26, 12, 4], ["oneway", 18, 22, 10, 1], ["solid", 34, 18, 6, 12], ["oneway", 46, 20, 10, 1], ["spawn", 24, 18], ["spawn", 50, 26], ["spawn", 10, 14]],
	[["floor", 0, 28, 60], ["solid", 14, 22, 4, 6], ["solid", 30, 16, 14, 4], ["prop", 48, 20, 6, 4], ["spawn", 8, 22], ["spawn", 36, 10], ["spawn", 54, 24]],
	[["floor", 0, 31, 60], ["solid", 4, 20, 6, 11], ["solid", 26, 26, 12, 5], ["solid", 50, 22, 6, 9], ["oneway", 12, 16, 12, 1], ["spawn", 18, 26], ["spawn", 32, 20], ["spawn", 44, 12]],
	[["floor", 0, 30, 30], ["floor", 30, 27, 30], ["oneway", 8, 20, 14, 1], ["prop", 36, 19, 6, 4], ["spawn", 14, 14], ["spawn", 40, 24], ["spawn", 54, 16]],
	[["floor", 0, 29, 60], ["solid", 20, 12, 3, 17], ["solid", 38, 12, 3, 17], ["oneway", 24, 18, 13, 1], ["spawn", 10, 24], ["spawn", 30, 10], ["spawn", 50, 24]],
	[["floor", 0, 30, 60], ["solid", 0, 18, 8, 12], ["solid", 52, 18, 8, 12], ["prop", 26, 20, 8, 5], ["spawn", 16, 26], ["spawn", 30, 12], ["spawn", 44, 26]],
	[["floor", 0, 30, 60], ["solid", 10, 26, 40, 4], ["solid", 20, 22, 20, 4], ["oneway", 2, 18, 10, 1], ["oneway", 48, 18, 10, 1], ["spawn", 30, 16], ["spawn", 6, 26], ["spawn", 54, 12]],
]

const LEADFALL: Array = [
	[["floor", 0, 30, 60], ["solid", 10, 26, 6, 4], ["solid", 40, 24, 8, 6], ["solid", 24, 6, 12, 3], ["spawn", 20, 26], ["spawn", 32, 20], ["spawn", 52, 20]],
	[["floor", 0, 28, 60], ["solid", 0, 22, 8, 6], ["solid", 30, 20, 4, 8], ["solid", 50, 22, 10, 6], ["spawn", 16, 24], ["spawn", 40, 22], ["spawn", 24, 14]],
	[["floor", 0, 31, 60], ["solid", 18, 25, 24, 6], ["solid", 26, 21, 8, 4], ["prop", 6, 25, 6, 4], ["spawn", 10, 20], ["spawn", 30, 16], ["spawn", 50, 26]],
	[["floor", 0, 30, 60], ["solid", 6, 10, 10, 2], ["solid", 44, 10, 10, 2], ["solid", 28, 24, 4, 6], ["spawn", 12, 26], ["spawn", 40, 26], ["spawn", 30, 14]],
	[["floor", 0, 29, 20], ["floor", 20, 31, 20], ["floor", 40, 29, 20], ["solid", 26, 18, 8, 2], ["spawn", 10, 24], ["spawn", 30, 26], ["spawn", 50, 22]],
	[["floor", 0, 30, 60], ["solid", 0, 24, 14, 6], ["solid", 46, 24, 14, 6], ["prop", 26, 22, 8, 5], ["spawn", 20, 26], ["spawn", 40, 26], ["spawn", 30, 12]],
	[["floor", 0, 30, 60], ["solid", 12, 20, 4, 10], ["solid", 30, 14, 4, 16], ["solid", 48, 20, 4, 10], ["spawn", 22, 24], ["spawn", 40, 24], ["spawn", 6, 18]],
	[["floor", 0, 27, 60], ["solid", 20, 23, 20, 4], ["solid", 4, 14, 8, 2], ["solid", 48, 14, 8, 2], ["spawn", 10, 22], ["spawn", 30, 18], ["spawn", 52, 22]],
]

const SKYREACH: Array = [
	[["oneway", 6, 26, 12, 1], ["oneway", 30, 18, 10, 1], ["oneway", 44, 28, 12, 1], ["spawn", 12, 10], ["spawn", 36, 24], ["spawn", 54, 14]],
	[["oneway", 2, 14, 10, 1], ["oneway", 22, 24, 16, 1], ["oneway", 46, 12, 10, 1], ["spawn", 30, 10], ["spawn", 8, 28], ["spawn", 50, 26]],
	[["oneway", 14, 20, 8, 1], ["oneway", 36, 20, 8, 1], ["oneway", 24, 30, 12, 1], ["spawn", 6, 10], ["spawn", 30, 12], ["spawn", 54, 22]],
	[["oneway", 0, 30, 14, 1], ["oneway", 40, 8, 14, 1], ["oneway", 22, 16, 10, 1], ["spawn", 20, 26], ["spawn", 46, 20], ["spawn", 8, 10]],
	[["oneway", 10, 10, 6, 1], ["oneway", 26, 22, 18, 1], ["oneway", 50, 30, 8, 1], ["prop", 32, 18, 6, 4], ["spawn", 14, 24], ["spawn", 40, 10], ["spawn", 54, 16]],
	[["oneway", 4, 22, 12, 1], ["oneway", 20, 12, 8, 1], ["oneway", 36, 26, 10, 1], ["oneway", 52, 16, 6, 1], ["spawn", 28, 26], ["spawn", 44, 10], ["spawn", 10, 8]],
	[["oneway", 18, 28, 24, 1], ["oneway", 6, 14, 8, 1], ["oneway", 46, 14, 8, 1], ["spawn", 30, 12], ["spawn", 10, 24], ["spawn", 50, 26]],
	[["oneway", 28, 6, 6, 1], ["oneway", 12, 18, 10, 1], ["oneway", 40, 22, 12, 1], ["spawn", 20, 28], ["spawn", 34, 14], ["spawn", 54, 8]],
]

const LAIR: Array = [
	[["floor", 0, 30, 60], ["solid", 0, 0, 2, 30], ["solid", 58, 0, 2, 30], ["oneway", 8, 20, 10, 1], ["oneway", 42, 20, 10, 1], ["oneway", 24, 13, 12, 1], ["spawn", 30, 20]],
]

const CORRIDOR: Array = [
	[["spawn", 30, 10], ["spawn", 30, 24]],
]

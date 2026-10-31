class_name PowerCurve
extends RefCounted

static func floor_at(p: ProgressionDef, life_fraction: float) -> float:
	return 1.0 + p.floor_gain * pow(clampf(life_fraction, 0.0, 1.0), p.floor_exp)

static func band_factor(p: ProgressionDef, dim_band: int, player_band: int) -> float:
	if dim_band < player_band - 1:
		return p.factor_below
	if dim_band > player_band:
		return p.factor_above
	if dim_band == player_band - 1:
		return 0.5
	return p.factor_equal

static func player_band(p: ProgressionDef, xp: float) -> int:
	var level: int = int(floor(xp / p.xp_per_level))
	return 1 + int(floor(float(level) / float(p.levels_per_band)))

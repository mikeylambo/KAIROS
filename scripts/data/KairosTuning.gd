class_name KairosTuning
extends Resource
## Every tunable from GDD §5/§7/§8/Combat/Ki/Camera. Units: u (1 u = 32 px), frames @60.

@export_group("clock")
@export var clock_start: float = 1800.0
@export var cost_light: float = 2.0
@export var cost_heavy: float = 5.0
@export var cost_boss: float = 8.0
@export var cost_warp: float = 5.0
@export var threshold_marks: PackedFloat32Array = PackedFloat32Array([600.0, 1200.0, 1680.0])
@export var overflow_at: float = 1680.0
@export var fade_fight_len: float = 60.0
@export var map_time_scale: float = 0.15

@export_group("movement")
@export var run_speed: float = 18.0
@export var run_accel: float = 60.0
@export var run_decel: float = 50.0
@export var jump_impulse: float = 24.0
@export var jump_cut: float = 0.5
@export var gravity: float = 48.0
@export var terminal: float = 42.0
@export var coyote_f: int = 7
@export var jump_buffer_f: int = 7
@export var air_control: float = 0.7
@export var fly_speed: float = 28.0
@export var fly_accel: float = 42.0
@export var fly_decel: float = 26.0
@export var fly_turn: float = 12.0
@export var fly_bank_deg: float = 25.0
@export var burst_speed: float = 65.0
@export var burst_f: int = 11
@export var burst_cd_f: int = 21
@export var transmit_range: float = 40.0
@export var transmit_behind: float = 2.8
@export var transmit_recovery_f: int = 15
@export var arrival_iframes_f: int = 6

@export_group("combat")
@export var input_buffer_f: int = 8
@export var light_startup: PackedInt32Array = PackedInt32Array([4, 4, 5])
@export var light_active: int = 3
@export var light_recovery: PackedInt32Array = PackedInt32Array([10, 10, 16])
@export var light_damage: PackedFloat32Array = PackedFloat32Array([25.0, 35.0, 55.0])
@export var light_reset_f: int = 51
@export var light_step: float = 6.0
@export var light_hitstop_f: int = 4
@export var light_hitstun_f: int = 18
@export var heavy_startup: int = 9
@export var heavy_active: int = 4
@export var heavy_recovery: int = 20
@export var heavy_damage: float = 85.0
@export var heavy_hitstop_f: int = 10
@export var launch_speed: float = 55.0
@export var chase_window_f: int = 75
@export var guard_perfect_f: int = 6
@export var guard_whiff_recovery_f: int = 21
@export var perfect_freeze_f: int = 6
@export var stagger_f: int = 8
@export var volley_startup: int = 3
@export var volley_recovery: int = 6
@export var volley_damage: float = 18.0
@export var volley_speed: float = 48.0
@export var beam_charge_max_f: int = 90
@export var beam_sustain_f: int = 60
@export var beam_recovery_f: int = 24
@export var beam_dps: float = 240.0
@export var beam_steer: float = 3.5
@export var beam_hitstop_f: int = 16
@export var field_startup: int = 8
@export var field_active: int = 6
@export var field_recovery: int = 18
@export var field_damage: float = 75.0
@export var field_radius: float = 10.0
@export var armor_hits: int = 3

@export_group("ki")
@export var ki_max: float = 100.0
@export var ki_per_hit: float = 16.0
@export var ki_per_perfect: float = 10.0
@export var ki_volley: float = 8.0
@export var ki_beam: float = 40.0
@export var ki_field: float = 30.0

@export_group("camera")
@export var cam_lookahead: float = 4.0
@export var cam_smoothing: float = 8.0
@export var cam_chase_zoom_min: float = 0.8
@export var cam_beam_zoom: float = 0.9
@export var cam_threshold_zoom: float = 1.15
@export var cam_overflow_zoom: float = 0.9
@export var cam_fade_zoom: float = 1.3

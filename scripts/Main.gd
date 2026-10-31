extends Node
## Boot → Title → (Run Setup) → Run → Legacy state machine.

enum St { BOOT, TITLE, SETUP, RUN, LEGACY, CODEX, SETTINGS }

const TITLE := preload("res://scenes/ui/title.tscn")
const SETUP := preload("res://scenes/ui/run_setup.tscn")
const RUN := preload("res://scenes/run/run.tscn")
const LEGACY := preload("res://scenes/ui/legacy.tscn")
const CODEX := preload("res://scenes/ui/codex.tscn")
const SETTINGS := preload("res://scenes/ui/settings.tscn")

var state: St = St.BOOT
var current: Node = null
var last_config: Dictionary = {}
var last_summary: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Settings.apply_all()
	goto(St.TITLE)

func goto(s: St, arg: Variant = null) -> void:
	if current:
		current.queue_free()
		current = null
	state = s
	match s:
		St.TITLE:
			current = TITLE.instantiate()
			current.proceed.connect(_on_title_proceed)
		St.SETUP:
			current = SETUP.instantiate()
			current.start.connect(func(cfg: Dictionary) -> void: start_run(cfg))
			current.back.connect(func() -> void: goto(St.TITLE))
		St.RUN:
			current = RUN.instantiate()
			current.config = arg
			current.finished.connect(_on_run_finished)
			current.quit_to_title.connect(func() -> void: goto(St.TITLE))
			current.restart_requested.connect(func(c: Dictionary) -> void: call_deferred("start_run", c))
		St.LEGACY:
			current = LEGACY.instantiate()
			current.summary = last_summary
			current.retry.connect(func() -> void: start_run(_retry_config()))
			current.codex.connect(func() -> void: goto(St.CODEX))
			current.title.connect(func() -> void: goto(St.TITLE))
		St.CODEX:
			current = CODEX.instantiate()
			current.back.connect(func() -> void: goto(St.LEGACY if not last_summary.is_empty() else St.TITLE))
		St.SETTINGS:
			current = SETTINGS.instantiate()
			current.back.connect(func() -> void: goto(St.TITLE))
	add_child(current)

func _on_title_proceed(choice: String) -> void:
	match choice:
		"first":
			start_run({"seed": int(Time.get_unix_time_from_system()) % 1000000, "clock": Tuning.t.clock_start, "tutorial": true})
		"setup":
			goto(St.SETUP)
		"codex":
			goto(St.CODEX)
		"settings":
			goto(St.SETTINGS)
		"quit":
			Platform.quit(get_tree())

func start_run(cfg: Dictionary) -> void:
	last_config = cfg
	goto(St.RUN, cfg)

func _retry_config() -> Dictionary:
	var c: Dictionary = last_config.duplicate()
	c.erase("tutorial")
	if not c.get("daily", false):
		c["seed"] = int(Time.get_unix_time_from_system()) % 1000000
	return c

func _on_run_finished(summary: Dictionary) -> void:
	last_summary = summary
	goto(St.LEGACY)

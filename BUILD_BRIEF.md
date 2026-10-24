# KAIROS — Claude Code Build Brief (Godot 4.5)

Read `GDD.md` fully before writing code. This brief says how, in what order, and how each step is proven. It is one continuous build: do not stop for approval between steps.

## 0. Ground rules

- Build the experience, not the feature list. "Done" means proven in a running build, by you, with evidence.
- No stubs, no fake UI, no silent substitutions. A threshold option that does nothing is a bug, not progress. (The previous web attempt shipped `apply: () => {}` for every upgrade; do not repeat that.)
- Never report unverified success. If a proof fails, say so.
- Typed GDScript everywhere (`var x: float`, typed arrays, `class_name`). Small files (< 300 lines). Commit after every proven step with a message naming the proof.
- The `web-slice-archive` branch is a rules reference only. Do not port its code.
- Michael playtests only when the build looks nearly finished. Do not ask him to test intermediate states.

## 1. Foundation

- Godot **4.5.x stable**. Project already scaffolded at repo root: `project.godot`, input map, autoload slots, folders, `tools/check.sh`.
- Install GUT 9.x into `addons/gut` (vendor the files; commit them).
- **One check command:** `./tools/check.sh` → (1) `godot --headless --import` (2) GDScript parse of every script with zero errors/warnings (3) GUT tests (4) headless boot of `main.tscn` for 300 frames with zero errors (5) bot playthrough (from step 4 of the build order on). Exit non-zero on any failure.
- Exports: `export_presets.cfg` for macOS (universal) and Windows; `tools/export.sh` builds both into `build/`.
- Platform-specific code (window, save path, achievements later) lives only in `scripts/platform/Platform.gd`.

## 2. Architecture

```
project.godot
scenes/
  main.tscn            # Boot → Title → Run → Legacy state machine
  run/run.tscn         # World container, Camera, HUD, Map overlay
  actors/zenith.tscn
  actors/enemies/*.tscn
  dimensions/<id>/chunks/*.tscn
  ui/*.tscn            # title, map, threshold_choice, pause, settings, legacy, codex
scripts/
  autoload/            # Run.gd, Multiverse.gd, Profile.gd, Events.gd, Tuning.gd, Dev.gd
  run/                 # RunClock.gd, PowerCurve.gd, ThresholdPool.gd, Insights.gd, InputLog.gd
  actors/zenith/       # Zenith.gd + states/*.gd (state machine), Hitbox/Hurtbox
  actors/enemies/      # EnemyBase.gd, per-type behaviors, AttackTokens.gd
  dimensions/          # Dimension.gd, ChunkAssembler.gd, rules/*.gd
  fx/                  # ImpactPlayer.gd, recipes, shaders/
  ui/
  platform/Platform.gd
data/                  # every tunable and content table (see §3)
assets/                # final art/audio drop-in folders (manifest-keyed)
tests/                 # GUT
tools/                 # check.sh, export.sh, capture.gd, bot.gd
```

Principles:
- **Fixed-step sim.** All gameplay in `_physics_process` at 60 Hz. Presentation (VFX, camera, HUD) reacts to `Events` signals; it never mutates gameplay state.
- **One owner per piece of state** (GDD §15 table). Other nodes read through the owner or listen to signals.
- **Determinism.** `Run.rng` (seeded) is the only randomness in gameplay. `InputLog` records per-tick actions; replaying a log on the same seed reproduces the run (test it).
- **Hitstop** is a global sim pause counter in `Run` (frames), not `Engine.time_scale`, so it stays deterministic.
- **Data-driven.** Rules, adaptations, techniques, threshold options, insights, enemies, threats are `Resource` types in `data/`. Adding a dimension = new resource + chunks, no code branches on dimension id.
- **Pools** for projectiles, sparks, afterimages, enemies (60+ live).
- **Dev hooks:** autoload `Dev` (enabled in debug builds) exposes: `set_clock(seconds)`, `grant_adaptation(id)`, `warp(dimension_id)`, `trigger_threshold(i)`, `spawn(enemy_id, n)`, `trigger_fade()`, `god_mode`, `time_scale`. In-game dev panel on F1. Same API drives the bot and screenshot capture.

## 3. Data files

| GDD table | Data file | Resource type |
|---|---|---|
| §5 clock costs, §7 movement, §8/Combat frame data, Ki | `data/tuning.tres` | `KairosTuning` (sections: clock, movement, combat, ki, camera) |
| Dimensions & rules | `data/dimensions/{threshold,leadfall,skyreach,corridor}.tres` | `DimensionDef` (band, rule list, adaptation id, palette, music key, chunk pool, enemy table) |
| Adaptations | `data/adaptations/{weight,lift}.tres` | `AdaptationDef` (effects, costs, mark interactions) |
| Threshold options | `data/threshold_options/*.tres` | `ThresholdOptionDef` (category, effect list) |
| Insights | `data/insights/*.tres` | `InsightDef` (context predicate id, count, granted variation) |
| Enemies | `data/enemies/*.tres` | `EnemyDef` (HP, armor, attacks, windups, XP) |
| Threat | `data/threats/bloom.tres` | `ThreatDef` (spread interval, lair time, phases) |
| Power curve, bands | `data/progression.tres` | `ProgressionDef` |
| Fade lines | `data/fade_lines.tres` | `StringList` |
| FX recipes | `data/fx_recipes.tres` | `FxRecipe` dictionary (SLU FX Lab field names) |
| Asset manifest | `data/asset_manifest.tres` | key → path |
| Audio manifest | `data/audio_manifest.tres` | key → path |

Effects in option/adaptation defs are composed from a small typed effect vocabulary (`stat_mul`, `stat_add`, `flag`, `on_event_spawn`), applied through one `BuildModifiers` aggregator that systems query. No per-option code paths.

## 4. Build order (continuous; each step ends with a Proof you run)

1. **Foundation.** GUT installed, autoloads created, `check.sh` green, main state machine boots Title → Run → Legacy with placeholders.
   *Proof:* `./tools/check.sh` passes; headless boot 300 frames, 0 errors.

2. **Feel gate — movement + launch-and-chase.** Zenith (procedural placeholder that already looks intentional: `Polygon2D` body, `Line2D` ribbons with fray shader, rim glow) in a Threshold test chunk. Run, jump, flight, burst, light string, heavy 8-dir launch, chase transmit, perfect guard, hitstop, inversion flash, shake, speed lines, afterimages. Tune against GDD §7/§8 until every row of the Feel Bible holds.
   *Proof:* GUT tests for movement numbers (top speeds, coyote/buffer windows, burst duration/i-frames), string → launch → chase lands the 4th hit in the air; frame data matches §Combat; capture `screens/feel_gate_*.png` at launch, mid-chase, arrival, beam. Record observations in `TUNING_LOG.md`.

3. **First 60 Seconds.** Script §9 exactly: title, push-in, line, drones, glyph teaches, billboard break, beam wave, map pulse.
   *Proof:* bot plays §9 and asserts each beat fires in order within ±3 s of its timestamp; screenshots of each beat.

4. **Core loop end-to-end.** RunClock (drain, hit costs, stagger, thresholds with real options, overflow at 28:00, Fade Fight, fade, early hunt path), power floor, XP/bands, Multiverse map (warp −5 s, Corridor flight), Threshold → Leadfall → Skyreach with exposure → adaptation, Weight→Skyreach mark, The Bloom (spread, signs, lair, 3 phases, beam clash), Legacy screen, Profile save.
   *Proof:* `tools/bot.gd` completes (a) a full run on a 2:00 clock preset that adapts Weight, marks Skyreach, ends the threat in the Fade Fight, reaches Legacy; (b) an early-hunt run; (c) a run where the fade wins. Invariant tests: clock never increases; thresholds fire once each in order; overflow only after 28:00 (scaled); every threshold option measurably changes its target value; same seed + input log → identical Legacy stats; profile save round-trips.

5. **Depth systems.** All threshold options, both slice insights, Codex screen, restraints (no transmit / half time) on Run Setup, daily seed.
   *Proof:* GUT test per option and insight; Codex persists across two simulated runs.

6. **Content per matrix (§14).** 8 chunks each for Threshold, Leadfall, Skyreach; all 6 enemies with telegraphs and attack tokens; Corridor encounters.
   *Proof:* chunk assembler builds 20 seeds per dimension with no unreachable areas (flood-fill test) and no enemy spawned inside terrain; screenshot every chunk.

7. **Presentation pass.** Diegetic clock (ribbons shorten, cracks widen, chest light final 2:00), dimension parallax art (procedural or provided), overflow post-FX (chromatic split, dimension cracks), fade dissolve, all VFX families, synthesized SFX for every category, music cue system with placeholder stems, HUD per §10, all UI screens styled.
   *Proof:* screenshots of Zenith at 30:00 / 20:00 / 10:00 / 1:30 side by side (`screens/clock_read.png`); every screen captured at 1920×1080 and 1280×800 (Steam Deck); perf sample with 60 enemies + overflow: report avg/p99 frame time.

8. **Polish to shelf quality.** Pad + KBM remapping UI, accessibility options (§Accessibility), pause/focus/disconnect edge cases, settings persistence, macOS + Windows exports.
   *Proof:* `./tools/export.sh` produces both builds; check.sh green; edge-case tests (focus loss pauses, disconnect pauses).

## 5. Runnable verification (must exist by end of step 4, extended after)

- `godot --headless --import` then headless boot: zero errors/warnings.
- `tools/bot.gd`: scripted input driver using the `Dev` API + `InputLog` playback; runs win, early-hunt, and loss scenarios on short clock presets.
- `tools/capture.gd`: loads each scene/state via `Dev`, waits N frames, saves PNG to `screens/` (run with a display or `xvfb-run` in CI).
- Invariant tests listed in step 4.
- Perf sampler: `Dev.perf_report(seconds)` prints avg/p99 frame time, node count, draw calls.

## 6. Assets

Follow GDD §13. Procedural VFX and UI are final. Everything else loads through `data/asset_manifest.tres`; absent file → procedural stand-in. Generate `ASSET_DELIVERY.md` listing each asset: key, source (Meshy image-to-3D / text-to-3D / AI 2D / hand), prompt or reference, export spec, status. Include a Blender script `tools/blender/render_sprites.py` that renders a rigged model's actions to sprite sheets per the export spec (ortho side camera, 256 px, outline pass, naming convention), so Michael's pipeline is: Meshy → Mixamo/Blender rig → run script → drop PNGs into `assets/sprites/<key>/`.

## 7. Audio

Full audio system to spec: buses (Master, Music, SFX, Voice), ducking during beam, pitch-rise within strings, music intensity layers and cue transitions per GDD §11. Synthesized placeholders (generate with a small `tools/synth_sfx.gd` or `AudioStreamGenerator`) behind `data/audio_manifest.tres`. Generate `AUDIO_DELIVERY.md` (key, description, length, loop?, mix notes).

## 8. When to stop and ask

Only if a player-facing spec contradiction blocks progress, or the performance target is unmeetable. Everything else: decide, log in `DECISIONS.md`, continue. Tuning changes go in `TUNING_LOG.md` with before/after and why.

## 9. Final report

Build paths + commit hash · `check.sh` output · screenshots of every scene, each First-60 beat, the clock read, Weight→Skyreach mark, overflow, beam clash, fade, Legacy · perf numbers · Definition of Done checklist with status · each Definition of Great test with evidence or "needs human playtest" · links to DECISIONS/TUNING_LOG/ASSET_DELIVERY/AUDIO_DELIVERY · an honest list of shortfalls.

## 10. After ship

Extract the genre-agnostic Godot foundation (main state machine, Events/Dev/Profile autoloads, InputLog determinism, pools, ImpactPlayer + FX recipes, audio bus/manifest system, check/bot/capture tools) into a `slu-godot-kit` repo so the next SLU Godot game forks the kit and specifies only its game layer.

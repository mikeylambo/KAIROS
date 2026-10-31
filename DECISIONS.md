# DECISIONS

Log meaningful decisions and assumptions here: date · decision · why · reversible?

| Date | Decision | Why | Reversible |
|---|---|---|---|
| 2026-10-23 | Engine moves from web (`@slu/web-shell` + three.js) to **Godot 4.5** | Michael's call; the web slice was rules-complete but shallow (threshold options did nothing) and in the wrong engine | Web slice preserved on `web-slice-archive` |
| 2026-10-23 | **2D** gameplay and rendering (supersedes the source GDD's 2.5D cel-shaded 3D) | Faster to reach "looks finished," Godot 2D is a strength, flight + launch-chase read cleanly on one plane | Yes, before content production |
| 2026-10-23 | Characters are **pre-rendered 3D → 2D sprites** (Dead Cells method) | Keeps the 2.5D GDD's reason (no hand-drawn animation bottleneck) while rendering in 2D; fits the Meshy pipeline | Yes |
| 2026-10-23 | Procedural Zenith/enemy placeholders must look intentional | Michael playtests only near-finished builds | — |
| 2026-10-23 | Units: 1 u = 32 px; timing in frames @60 fps | One convention across GDD, brief, and tuning | No (set before code) |
| 2026-10-23 | Tuning numbers harvested from the web slice's `Tuning.ts` as provisional | They were tested in a running build; better start than invented numbers | Yes, via TUNING_LOG |
| 2026-10-23 | No juggle decay; enemies balanced by armor/HP | Limitless pillar | Yes |
| 2026-10-23 | Hitstop as a sim pause counter, not `Engine.time_scale` | Determinism for seeds/replays | No |
| 2026-10-23 | GUT for tests | Standard, headless-capable | Yes |
| 2026-10-31 | Custom tile-grid kinematics (`TerrainGrid`) instead of `CharacterBody2D`/physics server | Exact frame-for-frame determinism for seeds/replays and headless tests; GDD §15 already asks for custom kinematic movement | Yes |
| 2026-10-31 | Sim/presentation split: gameplay nodes are invisible; views draw in an unwrapped camera space | Seamless horizontal (and Skyreach vertical) wrap; presentation can never mutate gameplay | Yes |
| 2026-10-31 | Chunks authored as compact feature lists in `ChunkLibrary.gd`, not `.tscn` | Readable diffs, seeded assembly + flood-fill tests without scene instancing; 8 per slice dimension | Yes (convert to TileMap scenes when real tilesets land) |
| 2026-10-31 | Zenith combat states are an enum inside `ZenithCombat` (+ `ZenithMelee/Transmit/Ki`) rather than `states/*.gd` nodes | One deterministic update order; each file < 300 lines | Yes |
| 2026-10-31 | Press frame counts as startup frame 1 | Matches fighting-game frame-data convention: Light 1 (4f startup) is active on the 5th frame | No |
| 2026-10-31 | Air press near the ground buffers a jump; otherwise it starts flight | Resolves the GDD's 7f jump buffer vs. "second press in air → flight" overlap | Yes |
| 2026-10-31 | Heavy's 8-dir launch reads the stick at press time if neutral at execution | Buffered heavies (cancel from a light) keep the player's intent | No |
| 2026-10-31 | "Power" scales Zenith's damage: `power_floor × (1 + option/adaptation bonuses)`; enemy HP scales with life fraction and band | GDD says the floor multiplies technique effects; damage is the effect every technique shares. Keeps "the time floor roughly keeps pace" | Yes, via TUNING_LOG |
| 2026-10-31 | Short clock presets scale thresholds, overflow, lair/spread timers, power curve, Bloom HP (≥8%) and the fade (min 10 s) by clock/30:00 | 2:00 bot runs traverse the whole run structure | Yes |
| 2026-10-31 | Warp/hit costs advance "life spent"; thresholds key on life spent, so a cost can carry life past a mark (fires that tick) | A life is time spent, not wall time | No |
| 2026-10-31 | First-60 billboard is placed at max(first chase, 0:23) in front of the current target | Newcomers hit the beat at their pace, experts don't hit it 6 s early; §9 beat stays near 0:25 | Yes |
| 2026-10-31 | Launched bodies chain into other enemies (40% heavy damage + knock) and break billboards | "Chaining enemies into one another" (§1) and "world reacts" (§9) | Yes |
| 2026-10-31 | Normal-guarded heavy/boss hits cost 50%; guarded lights cost nothing | GDD specifies light only; half cost keeps guard from trivialising heavies while preserving "chip" | Yes |
| 2026-10-31 | Bloom phase 3 clash: Ki or Light presses push, hold Ki for slow push (accessibility hold option) | GDD "mash/hold to win" | Yes |
| 2026-10-31 | Tools run through `tools/runner.tscn` instead of `godot -s` | `-s` scripts compile before autoloads exist; the runner instantiates tools after boot | No |
| 2026-10-31 | Renderer in CI captures is `gl_compatibility` under Xvfb (no Vulkan in container); shipping target stays Forward+ | Only way to capture real frames headlessly here | — |

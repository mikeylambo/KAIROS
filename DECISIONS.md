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

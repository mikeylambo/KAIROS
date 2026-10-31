# KAIROS

> Zenith, a warrior of limitless power, exists for exactly 30 minutes.

2D action-RPG roguelite in **Godot 4.5**. Launch-and-chase combat, open-dimension powerleveling, and a life clock that is also your health.

## Play
- Open in Godot 4.5.x, or `godot --path .`
- Builds: `./tools/export.sh` → `build/macos/KAIROS.zip` (universal, ad-hoc signed) and `build/windows/KAIROS.exe`

| Verb | KBM | Pad |
|---|---|---|
| Move / fly direction | A D (W S) | L-stick |
| Jump / Fly (second press or hold) | Space | A |
| Burst | Shift | RB |
| Light / Heavy (+dir = 8-way launch) | J / K | X / Y |
| Transmit / Chase | L | B |
| Guard (perfect = first 6f) | I | LB |
| Ki volley (tap) / Beam (hold) | U | RT |
| Burst field | O | LT |
| Multiverse map | M | Back |
| Pause | Esc | Start |
| Dev panel API (debug) | F1 | — |

All remappable in Settings, along with hold/toggle guard and beam, numeric clock, shake, flash, game speed, subtitles.

## Verify
- `./tools/check.sh` — import · parse every script · GUT tests · 300-frame headless boot · bot playthroughs (First 60, win via Fade Fight, early hunt, fade wins)
- Screenshots: `xvfb-run -a -s "-screen 0 1920x1080x24" godot --rendering-driver opengl3 --fixed-fps 60 res://tools/runner.tscn -- --tool=res://tools/capture.gd`
- `tools/perf.gd` (sim budget at 60 enemies + overflow), `tools/chunk_sheet.gd` (every authored chunk)

## Docs
`GDD.md` · `BUILD_BRIEF.md` · `DECISIONS.md` · `TUNING_LOG.md` · `ASSET_DELIVERY.md` · `AUDIO_DELIVERY.md` · `REPORT.md`

# KAIROS — Build Report (Godot 4.5.1)

Branch `claude/eloquent-noether-ybrugs`. Builds: `build/macos/KAIROS.zip` (universal, ad-hoc signed), `build/windows/KAIROS.exe` — produced by `./tools/export.sh` (not committed, `build/` is ignored).

## check.sh
```
== 1/5 import            clean
== 2/5 parse all scripts parse_all: 0 bad
== 3/5 GUT tests         Passing Tests 56, Failing 0
== 4/5 headless boot     boot: clean (300 frames, 0 errors/warnings)
== 5/5 bot playthrough   first60 PASS · win PASS · early PASS · fade PASS
check: OK
```

## Proofs by build step
| Step | Proof | Status |
|---|---|---|
| 1 Foundation | GUT vendored, autoloads, Boot→Title→Run→Legacy, check.sh | ✔ |
| 2 Feel gate | GUT: run 18 u/s, accel/decel, jump 24 + cut, terminal 42, gravity ×2, coyote 7f, buffer 7f, burst 11f/65 u/s/i-frames/21f CD, flight 28 (×0.7 Weight); frame data L 4/4/5, H 9; string→launch→chase lands the 4th hit in the air; perfect guard; stagger; armor. Screens: `docs/screens/feel_gate_*` | ✔ (feel itself needs hands) |
| 3 First 60 | Bot: beats in order, each within ±3 s (4.0/7.0/15.0/16.0/24.6/35.0/50.0 s) | ✔ |
| 4 Core loop | Bot on a 2:00 clock: Weight adapted → Skyreach marked → Bloom ended in the Fade Fight → Legacy; early hunt; fade wins. Invariants: clock never increases, thresholds once each in order, overflow only after 28:00 (scaled), every option measurably changes its target, same seed + input log → identical Legacy stats, profile round-trip + corrupt-file backup | ✔ |
| 5 Depth | All 7 options + both insights tested, Codex persists across two runs, restraints, daily seed | ✔ |
| 6 Content | 8 chunks × 3 dimensions; 20 seeds each flood-fill fully reachable, no spawn in terrain; 6 enemies + Bloom with telegraphs (shape + colour) and attack tokens (≤ 2, tested); Corridor encounters. `docs/screens/chunks_*` | ✔ |
| 7 Presentation | Diegetic clock (`clock_read.png`), parallax, overflow chroma/cracks, fade dissolve, all VFX families, synthesized SFX for every category + music cue/intensity/ducking, HUD, styled screens | ✔ (1280×800 captures not yet taken) |
| 8 Polish | KBM + pad remapping UI, accessibility set, pause/focus/disconnect tests, settings persist, both exports build | ✔ |

## Performance
- Sim at 60 live enemies + overflow: avg 0.75 ms, p99 1.40 ms per tick (`tools/perf.gd`).
- Render frame time on the target MacBook GPU: **not measured** — this container only has software GL. Use F1 → "Perf report 5 s" on hardware.

## Definition of Great (all need human playtest)
1. First chase < 30 s without text — bot chases at 0:16 with glyph prompts; human unverified.
2. "About 18 minutes" from the body — ribbons in 5-min-proportional length + crack growth + chest light; human unverified.
3. Weight→Skyreach described unprompted — mark card, shatter, iron streaks on map, flyers fall; human unverified.
4. Second 10-min run differs — seeded chunks + 3-of-7 option draws; human unverified.
5. Final 60 s worth posting — needs a real-GPU recording.

## Honest shortfalls
- No human has played it; tuning (Bloom HP, launch distance, chase lead, enemy damage) is bot-validated only.
- Characters are procedural stand-ins (intentional-looking, but simple); sprite pipeline + manifest are ready (`ASSET_DELIVERY.md`).
- Music/SFX are synthesized placeholders; one real voice line (ElevenLabs). 
- Captures use the GL Compatibility renderer under Xvfb, so HDR glow is weaker than on Forward+.
- Not built: 1280×800 capture pass, Steam Deck verification, `slu-godot-kit` extraction (BUILD_BRIEF §10, post-ship).

Links: DECISIONS.md · TUNING_LOG.md · ASSET_DELIVERY.md · AUDIO_DELIVERY.md

# TUNING LOG

Before → after, and why. Numbers start from GDD §5/§7/§8 and the web slice's `Tuning.ts`.

| Date | Param | Before | After | Why / evidence |
|---|---|---|---|---|
| 2026-10-31 | Camera base zoom | 1.0 (60 tiles visible) | 1.5 (40 tiles) | GDD: a chunk (60 tiles) ≈ 1.5 screens. At 1.0 Zenith was ~60 px tall at 1080p and lost his read (`screens/run_threshold.png` before/after) |
| 2026-10-31 | Background layer colours | palette[i] → grey | haze-to-deep atmospheric ramp, −25% sat | Background towers out-valued the gameplay terrain; readability inverted |
| 2026-10-31 | Terrain fill | palette[1] | palette[0] darkened, bright rim on exposed tops | Gameplay plane must be the sharpest, highest-contrast layer |
| 2026-10-31 | Coyote counter | reset to 7 | reset to 8 (decremented before check) | Test showed only 6 usable air frames; GDD 7f |
| 2026-10-31 | Bloom HP | phase 1: 1400, cores 520 | phase 1: 8 400, cores 3×2 600 (×clock scale ≥ 8%) | GDD TTK targets: early hunt @10:00 ≈ 4 min, Fade Fight at full power ≈ 45 s. Bot: early hunt killed it in 28 s on a 2:00 clock (≈ 7 min at full scale, with expert-bot uptime); Fade Fight inside 16 s scaled fade. Needs human playtest |
| 2026-10-31 | Tutorial brute HP | 220 | 900 (tutorial only) | It must survive long enough for launch → chase → air string → billboard at ~0:25 |
| 2026-10-31 | First-60 chase beat target | 0:15 | 0:19 | §9 lists the heavy drone at 0:15; the chase follows it. Bot chases at 0:16 |

## Feel Gate observations (bot + captures, not a human playtest)
- String → launch → chase → 4th hit in the air: lands reliably (GUT `test_string_launch_chase_lands_4th_hit_in_air`).
- Heavy 10f hitstop + 1-frame inversion + 6 px shake + speed lines + afterimages all fire on launch (`screens/feel_gate_launch.png`).
- Chase arrival: afterimage at origin, contracting cyan ring + magenta burst at arrival (`feel_gate_arrival.png`).
- Camera frames Zenith + launched target during the chase window (zoom ≥ 0.8 of base).
- Needs human hands: whether 55 u/s launch + 9-frame lead on chase arrival feels "already there" rather than "teleported next to".

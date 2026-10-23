# KAIROS

> *“Zenith, a warrior of limitless power, exists for exactly 30 minutes. Each run is one life: you choose where in the multiverse to spend it, what to learn, what to fight, and how you go out.”*

A continuous, playable vertical slice of **KAIROS** — a 2.5D action-RPG roguelite featuring speed traversal, open-dimension powerleveling, launch-and-chase aerial combat, and a diegetic 30-minute life clock.

---

## The Four Gates Proved in This Slice

1. **Launch-and-Chase Combat:** Combos travel across physical space. Launch enemies in any of 8 directions, then instantly transmit directly into their flight path to continue the combo mid-air.
2. **The 30-Minute Clock as Health:** No arbitrary health bar. Enemy strikes deduct seconds from Zenith's life and stagger him. Power scales as a floor multiplier with elapsed time; 28:00 unlocks the dimensional overflow; clock expiration at 30:00 triggers the 60-second dissolve Fade Fight.
3. **The Dimension System (Rule &rarr; Adapt &rarr; Carry &rarr; Mark):**
   - **The Threshold** (Band 1): Crisis city skyline teaching fundamentals.
   - **Leadfall** (Band 2): Heavy gravity foundry. Fighting fills the exposure meter to earn **Weight** (crushing attacks, heavy flight).
   - **Skyreach** (Band 2): Endless open sky with floating platforms.
   - **Signature Multiverse Mark:** Entering Skyreach carrying Weight subjects flyers to gravity near Zenith, grounding them and permanently marking Skyreach on the Multiverse Node Map for the remainder of the run.
4. **The Fade Ending:** Whether through an early hunt or surviving the dissolve fight, Zenith dissolves at peak power with his signature spoken line, transitioning into the comprehensive Legacy Screen.

---

## Technical Foundation & Shell Integration

### Base Shell
- Built on **`@slu/web-shell` v1.1.0** from `main` of `mikeylambo/web-game-shell-v1.02` pinned to commit **`6f08d17c2f1012b19e6e26c87c640762354eb0ec`** (Sep 11, 2026).
- Systems utilized:
  - `DeterministicRNG` for seeded generation and replay verification
  - Input system schema and action bindings
  - Audio contract and lifecycle conventions
  - Performance budgets and telemetry standards
  - Data-driven content architectures

### Ported Shell Modules (`src/ported/`)
Maintained cleanly in `src/ported/` with upstream compatibility preserved:
- **`feat/high-mobility-combat-frame`** (`60ba5020208dad929b23a82de9434dfdf9e465b4`):
  - `src/frames/highMobilityCombat.ts`
  - `src/modules/highMobility/*` (`BoostMotion`, `TargetCombat`, `CombatAI`, `BossPhases`, `TuningStore`, `WorldStreaming`, `RuntimePrimitives`)
- **`feat/slu-impact-motion-adapter`** (`200db8f889ba6d7cf1cb3fdcdef7150f8da6aa6b`):
  - `src/impact/*` (`ImpactLibrary`, `ImpactPlayer`, `Variation`, `CallbackImpactAdapter`)
  - `src/adapters/three/ThreeMotionImpactAdapter.ts`
  - Authored effect data recipes played through the renderer-neutral SLU impact pipeline
- **`arrowfall-survivor`** (`d5bdb4ae2ac09109088a5f0e524badd60996ee3b`):
  - Latched browser input via `taps` set in `BrowserInputSource.ts`, ensuring key presses are never dropped between 60 Hz simulation ticks.

### AIRTIME Momentum Controller Principles
- Custom 2.5D kinematic physics with no heavy physics engine needed.
- Ground running acceleration and braking curves.
- Snappy variable-height jump arcs.
- Free 8-directional flight with velocity carrying, curve banking, and burst cancels.

---

## Controls

| Key | Action |
| --- | --- |
| **A / D** or **&larr; / &rarr;** | Move / Run Left & Right |
| **W** or **Space** or **&uarr;** | Jump |
| **W / A / S / D** (in air) | Free 8-Directional Flight (Momentum & Banking) |
| **Shift** | **Burst Dash** (cancels attack recovery, i-frames) |
| **Space** | **Instant Transmission** / **Aerial Chase** |
| **J** | **Light Melee String** (3 hits, advances forward) |
| **K** (+ direction) | **Heavy Launcher** (8 directional angles) |
| **L** | **Afterimage Evade / Guard** (6-frame perfect guard window) |
| **U** | **Ki Volley** (rapid-fire projectile barrage) |
| **I** (hold/release) | **Steerable Charge Beam** (aim up/down with W/S) |
| **O** | **Burst Field** (radial energy explosion) |
| **M** | **Multiverse Node Map** (Instant warp vs free corridor flight) |
| **Tab** or **`** | **Live Tuning & Debug Panel** |

---

## Live Tuning Panel

Toggle anytime with `Tab` or `~`:
- **Live Sliders:** Run speed, flight speed, burst speed, heavy launch speed, chase window, light/heavy hit cost seconds.
- **Quick Buttons:** Grant Weight, Grant Lift, Spawn Threat Boss, 28:00 Overflow, Trigger Fade Ending, Trigger Threshold Choice.
- **Jump Dimension:** Instant teleport to Threshold, Leadfall, Skyreach, Corridor, or Threat Node.
- **Clock Presets:** 30:00 (Full), 6:00 (Short), 2:00 (Quick test).
- **Toggles:** Numeric timer HUD, Slow motion (0.25x), Deterministic run replay.

---

## Development & Verification

```bash
# Install dependencies
npm install

# Run 60 Hz deterministic verification tests
npm test

# Run local dev server with hot reload
npm run dev

# Run production build
npm run build
```

---

## Deployment (Vercel)

This repository includes a native `vercel.json` and builds to `dist/` via Vite:

```bash
vercel --prod
```

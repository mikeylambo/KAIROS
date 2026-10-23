# Ported Shell Modules

These modules were ported into KAIROS from unmerged development branches of `mikeylambo/web-game-shell-v1.02`. They are maintained in this directory with their original structure and contracts so they can be merged back into `@slu/web-shell` in a future release.

## Source Manifest

1. **`highMobility` (`src/ported/highMobility/*`)**
   - **Source Branch:** `feat/high-mobility-combat-frame`
   - **Source Commit:** `60ba5020208dad929b23a82de9434dfdf9e465b4`
   - **Modules:**
     - `BoostMotion.ts`: 3D boost and momentum vector kinematics
     - `TargetCombat.ts`: Soft-lock targeting, angle weights, and break/impact counters
     - `CombatAI.ts`: 9-state combat AI state machine and enemy archetypes
     - `BossPhases.ts`: Phased boss health/armor progression
     - `TuningStore.ts`: Dynamic runtime tuning parameters
     - `WorldStreaming.ts`: Velocity-biased streamed spatial grid
     - `RuntimePrimitives.ts`: Spatial hash, object pool, height field, performance sampler
     - `highMobilityCombat.ts`: GenreFrame definition for high mobility combat

2. **`impact` & `ThreeMotionImpactAdapter` (`src/ported/impact/*`, `src/ported/adapters/three/*`, `src/ported/motion/*`)**
   - **Source Branch:** `feat/slu-impact-motion-adapter`
   - **Source Commit:** `200db8f889ba6d7cf1cb3fdcdef7150f8da6aa6b`
   - **Modules:**
     - `ImpactLibrary.ts`: Registration and query of authored SLU FX impact recipes
     - `ImpactPlayer.ts`: Timed cue dispatch across VFX, audio, camera, and gameplay channels
     - `Variation.ts`: Seeded pitch, rotation, and intensity variations
     - `ThreeMotionImpactAdapter.ts`: Adapter connecting Three.js scene/camera/actors to impact cues and animation clips
     - `MotionImpactBridge.ts`, `MotionPlayer.ts`, `types.ts`: Supporting motion playback and impact triggering

3. **`input` (`src/ported/input/BrowserInputSource.ts`)**
   - **Source Branch:** `arrowfall-survivor`
   - **Source Commit:** `d5bdb4ae2ac09109088a5f0e524badd60996ee3b`
   - **Enhancement:** Latched browser input via `taps` set, preventing dropped keypresses between simulation ticks.

# KAIROS — Game Design Document

| | |
|---|---|
| Version | 1.0 (Godot) |
| Status | Production-Ready |
| Date | 2026-10-23 |
| Platform | Desktop (macOS / Windows / Linux), keyboard + gamepad; Steam Deck verified target |
| Engine | Godot 4.5, GDScript, 2D renderer (Forward+) |
| Source docs | "KAIROS — GDD" (Claude doc, 2026-10-10) is the design source; this file supersedes its Presentation and Technical Foundation sections |

---

## 1. Executive summary

**Pitch.** A 2D action-RPG roguelite where Zenith, a warrior of limitless power, spends exactly one 30-minute life powerleveling across a multiverse of rule-bending dimensions, distinguished by launch-and-chase combat that travels across the whole screen and a life clock that is also his health.

**Player fantasy.** You are the strongest being in existence and nothing can kill you. Only time can. You are unhurried, playful, untouchable, and every second you burn brighter until you fade at your peak.

**The game is about three things.**
1. Launch-and-chase: hit, send, teleport into the flight path, keep going.
2. Spending a life: every choice costs seconds that never come back.
3. Reading the multiverse: knowing which dimension pays right now, and leaving the moment it stops.

**Most of the time the player is** flying and running through a dimension chaining enemies into one another, watching the exposure meter fill, then deciding where to go next.

| Target experience | |
|---|---|
| Session | One run = 30:00 of life (≈ 31–33 min wall clock incl. threshold choices) |
| Players | 1 |
| Perspective | 2D side view, single gameplay plane, parallax backgrounds |
| Audience | Action/roguelite players; DBZ-spectacle fans; speedrun/score chasers |
| Complexity | Easy to fight, deep to master (execution + build space) |
| Primary input | Gamepad (KBM fully supported) |

## 2. Pillars & anti-pillars

| Pillar | Meaning | Player consequence | Rejects |
|---|---|---|---|
| **Limitless** | No caps on power, combos, technique stacking, score | Combos never forcibly end; peak power has no max | Combo limits, damage caps, slot caps |
| **A 30-minute life** | Every choice spends time; time is never refunded | Getting hit, warping, dawdling all cost seconds | Health pickups, time refills, revives |
| **Discovery** | Depth is found, not explained | Insights, hidden bosses, signs of the threat appear without tutorials | Quest logs, waypoint arrows to secrets, unlock menus |

**Anti-pillars — KAIROS must never become:**
- A health-bar brawler (no HP bars on Zenith, ever).
- A grind (meta progression widens options, never raw stats).
- A menu game (no inventory, no gear, no currencies beyond what's here).
- A visual soup (Zenith's silhouette must read at peak overflow density).

## 3. Reference DNA

| Reference | Take | Do not take |
|---|---|---|
| Dragon Ball Z (Gogeta vs Broly) | Launch-chase spectacle, teleport rhythm, beam clashes | Characters, costumes, spiky hair, vest/sash signatures |
| Sonic (2D, Super forms) | Speed flow through authored terrain | Ring-health, bottomless-pit deaths |
| MapleStory private servers | Level bands, hop-when-it-stops-paying instinct | Grind, gear, gacha |
| Dead Cells | Pre-rendered 3D→2D sprite pipeline, responsive melee, run structure | Biome door lists, cells currency |
| Hades | Run-start fairness, meta that widens the menu | Dialogue volume |
| Devil May Cry | Style-through-variety rewarded (mastery XP for variation) | Style rank letters |

Weighting: DBZ spectacle 30%, Dead Cells feel/pipeline 20%, MapleStory structure 15%, original 35%.

## 4. Core loop

**Moment-to-moment (5–30 s):** spot target → transmit/fly in → light string → heavy launcher (8-dir) → chase transmit → air string → relaunch or beam finisher → hitstop → next target.

**Dimension loop (1–6 min):** arrive → read the rule → fight → exposure fills → **adapt** (carry the rule) → leave (warp = costs time, or fly the Corridor = free, slow).

**Run loop (30 min):** Threshold → hop dimensions by band → thresholds at 10/20/28 (spectacle + one choice) → overflow at 28:00 → Fade Fight at 30:00 (or hunt the threat earlier) → fade line → Legacy screen.

**Session loop:** Codex fills, new options unlock, a new threat rotates in → "one more life."

## 5. Rules

- **Win:** there is no "survive." A run is *successful* if the threat is ended (early hunt or Fade Fight). Every run ends in the fade.
- **Loss:** the fade completes before the threat is ended. Still ends with the fade line and Legacy screen (tone: bittersweet, never "GAME OVER").
- **Clock:** starts 30:00. Drains 1 s/s × dimension clock rate. Enemy hits subtract time. Reaching 0:00 → Fade Fight (60 s dissolve timer). Fade timer 0 → fade.
- **Early threat kill:** remaining minutes are free time; at 0:00 Zenith fades with no fight (fade line + Legacy).
- **Score (Peak Power):** uncapped. `peak_power = max over run of (power_floor × (1 + techniques_bonus + adaptations_bonus))`. Legacy also shows: threat result + time, dimensions marked, longest chain, insights found.

| Clock costs (provisional) | Seconds |
|---|---|
| Enemy light hit | −2.0 |
| Enemy heavy hit | −5.0 |
| Boss/threat hit | −8.0 |
| Instant transmission to a dimension (map warp) | −5.0 |
| Combat transmission | 0 |
| Glasshour dilation | clock ×2.0 while inside |

## 6. Verbs & controls

| Verb | KBM | Pad | Function | Commitment | Key interaction |
|---|---|---|---|---|---|
| Move | A/D | L-stick | Run; in air, 8-dir flight input | None | Momentum carries into burst |
| Jump / Fly | Space | A | Jump; hold/second press in air → flight | Low | Coyote 7f, buffer 7f |
| Burst | Shift | RB | 11f dash, i-frames, cancels recovery | 21f cooldown | Cancels any attack recovery |
| Light | J | X | 3-hit string, steps forward | Low | Ends in heavy for launch |
| Heavy | K (+dir) | Y (+dir) | Launcher in 8 directions | Medium | Starts chase window |
| Transmit / Chase | L | B | Teleport behind nearest target; during chase window, to the launched enemy's landing point | 15f recovery, canceled by hit | The identity verb |
| Guard / Afterimage | I | LB | Hold guard; 6f perfect window → afterimage takes hit, Zenith repositions | 21f recovery on whiff | Perfect guard refunds ki |
| Ki volley | U | RT tap | Rapid bolts | 8 ki each | Builds insight contexts |
| Charge beam | U hold | RT hold | Charge ≤ 90f, steer with stick | 40 ki | Beam clashes on bosses |
| Burst field | O | LT | Radial blast | 30 ki | Clears crowds, breaks guards |
| Multiverse map | M | Back/Select | Opens map (game keeps running at 0.15× time; clock still drains at 0.15×) | — | Warp vs Corridor |
| Pause | Esc | Start | True pause (clock stops) | — | — |

**Input philosophy.** 8-frame buffer on all attack/burst/transmit inputs. Simultaneous Light+Heavy within 3f = Heavy. Remapping for every action (KBM + pad). Stick deadzone 0.2 radial, 8-dir snap at 22.5° sectors for launch/flight intent. Inputs during hitstop are buffered, not dropped. Inputs during scene transitions are discarded. Pad disconnect → auto-pause with reconnect prompt.

## 7. Movement spec

Units: **1 u = 32 px**. Speeds in u/s, timing in frames @60 fps.

| Param | Value | Notes |
|---|---|---|
| Run top speed | 18 u/s | |
| Run accel / decel | 60 / 50 u/s² | Reversal uses decel then accel (no instant flip) |
| Jump impulse | 24 u/s | Variable height: release → vy × 0.5 |
| Gravity / terminal | 48 u/s² / 42 u/s | ×2.0 in Leadfall |
| Coyote / jump buffer | 7f (117 ms) / 7f | |
| Air control (falling, not flying) | 70% of run accel | |
| Flight top speed | 28 u/s | ×0.70 with Weight |
| Flight accel / decel | 42 / 26 u/s² | Momentum carries; turn rate 12 rad/s |
| Flight bank | up to 25° visual tilt | |
| Burst | 65 u/s for 11f (183 ms), 21f cooldown, i-frames full duration | Direction = stick, else facing |
| Combat transmit | range 40 u, lands 2.8 u behind target, 15f recovery | |

**Feels like:** a hovering martial artist, effortless, weightless until he chooses weight. **Must not feel like:** a floaty jetpack, or a platformer where falling is danger. Ledges: no grabs, flight makes them moot. Slopes up to 45° keep run speed. No fall damage, no pits (falling off the bottom of a dimension wraps to the top in open dimensions, or is bounded in grounded ones). Enemy bodies do not block Zenith; he passes through, hitboxes resolve.

## 8. Game Feel Bible

| Action | Fantasy | Startup | Active | Impact | Recovery | Success feels | Failure feels | Must never feel |
|---|---|---|---|---|---|---|---|---|
| Light 1/2/3 | Casual, toying | 4/4/5f | 3f | 4f hitstop, small spark, 2px shake, tick SFX pitch-up per hit | 10/10/16f | Rhythmic, crisp | Whiff is short, no punish | Sticky or slow |
| Heavy launcher | Sending them across the sky | 9f | 4f | 10f hitstop, 1-frame inverted impact flash, 6px shake, deep thump, speed lines along launch vector | 20f (canceled by Chase) | The world tilts toward the launch | Clear whiff swoosh | Weak or delayed launch |
| Chase transmit | Already there | 0f (instant) | — | Afterimage at origin, arrival ring, whoosh-crack; enemy arrives into him | 15f, canceled by landing a hit | "He beat physics" | Lands slightly late; still safe | Disorienting; camera losing him |
| Perfect guard | Bored dodge | 0f | 6f window | Afterimage takes hit, 6f time freeze, glass-chime, +10 ki | 0f on success, 21f on whiff | Untouchable | Normal guard chip (no time cost on guarded light hits) | Unclear whether it worked |
| Charge beam | Ending things | 0f charge start | Up to 90f charge, then sustained | Screen-wide light, 16f hitstop on finisher, background darkens 40%, rumble | 24f | Overwhelming | Low-charge beam still useful | Static or skinny |
| Burst | Flicker | 0f | 11f | Afterimage trail ×3, air-cut SFX | 21f cooldown | Instant | — | Laggy |
| Taking a hit | Mild annoyance | — | — | 8f stagger, cracks flash, clock digits (if numeric HUD on) tick red, low "time shard" SFX | — | — | Readable cost | Losing control > 8f |

## 9. First 60 Seconds

1. **0:00 boot →** title: Zenith floating over The Threshold skyline, ribbons drifting. "Press any button." (no menus first time).
2. **0:04** Camera pushes in. One line from Zenith: *"Thirty minutes. Plenty."* Clock begins (body ribbons full).
3. **0:07** Three crisis drones ahead. Prompt glyph only (X / J) above first drone. Player hits → first hitstop. Combo string lands.
4. **0:15** A heavy drone. Glyph Y (K). Launch → it flies across the city. Glyph B (L) pulses on the flying drone. Chase → arrives behind it mid-air. *This is the first win.*
5. **0:25** Air string, enemy crashes through a billboard (world reacts).
6. **0:35** Small wave of 8 drones; no prompts. Ki fills; RT glyph pulses once when ki ≥ 40. Beam clears the street.
7. **0:50** Exposure meter appears for the first time (Threshold has none: it shows "—"). The map glyph pulses; two dimension nodes glow on the horizon. Player is free.

No text walls; every teach is demonstrate → attempt → reinforce. Glyphs never reappear after success.

## 10. UX flow & HUD

**Flow:** Boot → Title (any button) → [first run: straight in] / [later: Run Setup: seed (random/daily), restraints] → Run → Threshold choices (modal, game frozen) → Fade Fight → Fade cinematic + line → Legacy screen → Retry / Codex / Title.

**Edge cases:** pause freezes clock; window focus loss = pause; pad disconnect = pause; quit mid-run asks confirm and records the run as abandoned (no Codex loss); restart from pause with confirm; failed save write → keep running, toast "Codex not saved", retry at next checkpoint.

**HUD hierarchy:**
| Priority | Element | Form |
|---|---|---|
| 1 | Life clock | Diegetic on Zenith: ribbon length, crack width, chest light (final 2 min). Optional numeric timer (settings, off by default) |
| 2 | Ki | Thin arc under Zenith's feet, 3 segments (volley / field / beam thresholds) |
| 3 | Chase window | Launched enemy glows; ring contracts over the chase window |
| 4 | Exposure | Small rule glyph + fill ring, top-left; flashes on adaptation |
| 5 | Combo / chain | Top-right, appears only at chain ≥ 5, fades 1.5 s after break |
| 6 | Threat signs | No HUD; shown in world and on the map |

UI style: thin-line glyphs, tri-color (cyan / magenta / white) accents on near-black glass panels, monospaced numerals, inversion flash on any state change.

## 11. Presentation direction

**Visual thesis.** Reality strains around a being too bright for it. Painterly, desaturated worlds; one sharp, high-contrast figure; every big hit inverts the screen for a frame.

**SLU identity rules:** color inversion on impact frames, afterimages on every fast action, tri-color glow (cyan `#3FF6FF`, magenta `#FF3FD8`, white `#FFFFFF`) reserved for Zenith and his power. Enemies use each dimension's palette plus one warning hue (orange `#FF8A1F`).

**Zenith (LOCKED):** black sleeveless high-neck top, black sash, black wrapped forearms and shins, loose black trousers, bare feet, porcelain skin with hairline light cracks, smooth swept-back hair dissolving into motes, two light ribbons from the shoulder blades with cyan/magenta frayed ends. Constant thin cyan/magenta rim light. Silhouette stays intact until the fade.

**Rendering:** Godot 2D. Characters are pre-rendered sprites (§13). Backgrounds: 3–5 parallax layers per dimension, lower contrast/saturation than the gameplay plane. Post: `WorldEnvironment` glow + a full-screen canvas shader for inversion flashes, chromatic split during overflow, and dimension-break cracks.

**Anti-targets:** muddy dark-on-dark; particle storms hiding Zenith; anime-filter look; DBZ costume echoes.

**Animation set (Zenith, ≥ 12 fps sprites, 24 fps for attacks):** idle-hover, run, jump, fall, fly (8 dirs via rotation + 3 poses), burst, light 1/2/3, heavy (up/side/down variants rotated for diagonals), transmit out/in, guard, perfect-guard pose, volley, beam charge/fire, field, hit stagger, threshold pose, fade (dissolve).

**VFX families:** hit sparks (3 sizes), launch speed lines, afterimage trail, transmit ring, beam (charge orb + body + impact), burst field shockwave, crack decals (world), dimension-break shatter (overflow), fade dissolve. Recipes authored as data (`data/fx_recipes.tres`) mirroring SLU FX Lab recipe fields so they port to the catalog.

**Audio thesis.** Calm voice, violent world. Zenith's sounds are clean and high (glass, air, chimes); impacts are low and physical; time costs are a reversed crystal "shard."

| SFX category | Identity |
|---|---|
| Zenith movement | Air cuts, soft ribbon flutter |
| Hits | Layered thump + crack, pitch rises within a string |
| Transmit | Vacuum pop → arrival crack |
| Beam | Rising tone → sustained roar → glass shatter on finish |
| Time loss | Reversed crystal shard |
| Threshold | Choir swell + bell |

| Music cue | Trigger |
|---|---|
| Dimension theme (per dimension) | On arrival; intensity layer 2 when enemies ≥ 6 on screen |
| Corridor | Sparse pads |
| Threshold | Stinger, then music returns +1 intensity |
| Overflow (28:00) | All dimension themes collapse into one driving cue |
| Fade Fight | Final cue; drums drop out as fade progresses |
| Fade | Silence → single sustained note under the fade line |

Mix: voice > time-loss SFX > hits > music. Duck music −6 dB during beam fire.

## 12. Foundation & Reuse Map

| System | Source | Path / repo | Notes |
|---|---|---|---|
| Engine project, input map, autoloads | New | `KAIROS` repo root (Godot) | Scaffolded in this commit |
| Movement controller | New (port of rules) | `scripts/actors/zenith/` | Values from §7; AIRTIME momentum principles (accel/decel curves, carry) re-implemented in GDScript |
| Run clock, thresholds, overflow, fade | New (port of rules) | `scripts/run/` | Web slice `RunClock.ts` used only as a rule reference; its threshold options were non-functional |
| Tuning numbers | Harvest | `web-slice-archive` branch, `src/sim/Tuning.ts` | Copied into `data/tuning.tres` as provisional |
| Acceptance tests | Harvest (intent) | `web-slice-archive`, `tests/kairos.test.mjs` | Re-written as GUT tests |
| Test framework | Reuse | GUT 9.x (Godot Unit Test) | Vendored in `addons/gut` |
| FX recipe schema | Reuse (schema only) | SLU FX Lab | Godot Resource mirrors recipe fields |

Godot has no existing SLU kit; on ship, extract the foundation into `slu-godot-kit` (see BUILD_BRIEF §10).

## 13. Asset pipeline

| Asset class | Source | Cleanup | Export spec | Placeholder |
|---|---|---|---|---|
| Zenith | Concept (locked) → Meshy image-to-3D → Mixamo/Blender rig + anims | Blender: decimate ≤ 20k tris, toon material (2-tone + rim), ribbons as separate bone chains | **Pre-rendered** to sprite sheets: orthographic side camera, 256×256 frames, transparent PNG, 3 px outline pass, naming `zenith_<anim>_<frame>.png` packed per anim into `SpriteFrames` | Procedural Zenith: `Polygon2D` body + `Line2D` ribbons (fray shader) + `GPUParticles2D` motes. Must already look intentional |
| Enemies (per dimension, 3 types) | Meshy text-to-3D → same render rig | Same | 128×128 or 192×192 frames | Procedural silhouettes per dimension palette |
| Threat (The Bloom) | Meshy + Blender | Same | 512×512 frames | Procedural layered shapes |
| Backgrounds | AI 2D painterly (per dimension, 5 layers) | Upscale, palette-match, desaturate 25% | 3840×2160 PNG per layer, tileable horizontally | Gradient + procedural silhouettes |
| Tiles / terrain | Hand-authored TileSet, 32 px | — | `TileSet` resource per dimension | Flat-color tiles with rim lines |
| VFX | Procedural (shaders + particles) — **final** | — | — | n/a |
| UI | Procedural (StyleBox + glyph font) — **final** | — | — | n/a |
| Audio | Synthesized placeholders → final SFX/music | Normalize −14 LUFS music, −1 dBTP | OGG | Generated tones per category |

**Swap contract.** Every visual/audio asset is referenced by key in `data/asset_manifest.tres` (key → path). Loaders fall back to the procedural stand-in when the key's file is absent. Dropping `assets/sprites/zenith/*.png` with matching names replaces the placeholder with no code change. Non-humanoid rigs (The Bloom, flyers) are flagged for Blender rigging.

## 14. Content matrix (vertical slice + launch)

| Content | Slice? | Visual | Anims | FX | Audio | UI |
|---|---|---|---|---|---|---|
| Zenith | ✔ | ✔ | full set | all families | full | diegetic clock, ki arc |
| The Threshold (band 1) | ✔ | 5 bg layers, tileset | — | — | theme | node |
| Leadfall (band 2, heavy gravity) | ✔ | 5 layers, tileset | — | iron rain | theme | node |
| Skyreach (band 2, open sky) | ✔ | 5 layers, cloud platforms | — | wind | theme | node |
| The Corridor | ✔ | starfield layers | — | streaks | pads | — |
| Umbra Deep, Glasshour, Mirrormere, Faultline | Launch | per GDD | — | per rule | themes | nodes |
| Threshold drone (light) | ✔ | ✔ | idle/move/attack/hit/die | spark | ✔ | — |
| Threshold brute (heavy) | ✔ | ✔ | same + windup | ✔ | ✔ | — |
| Leadfall slammer (armored) | ✔ | ✔ | same + slam | dust | ✔ | — |
| Leadfall gunner | ✔ | ✔ | same + shot | bolt | ✔ | — |
| Skyreach flyer | ✔ | ✔ | flap/dive/hit/fall | feathers of light | ✔ | — |
| Skyreach lancer | ✔ | ✔ | charge | ✔ | ✔ | — |
| The Bloom (threat, 3 phases) | ✔ | ✔ | per phase | ✔ | ✔ | name card |
| Screens: Title, Map, Threshold choice, Pause, Settings, Legacy, Codex | ✔ | ✔ | ✔ | — | ✔ | ✔ |

## 15. Tech & source of truth

- Godot 4.5 stable, GDScript (typed), 2D, Forward+; physics: `CharacterBody2D` for actors, `Area2D` hit/hurtboxes, custom kinematic movement (no rigid bodies).
- **Fixed step:** physics tick 60 Hz; all gameplay in `_physics_process`. Seeded `RandomNumberGenerator` owned by `RunState` (one seed per run). Same seed + same input log → same run (required for daily seeds and replays).
- Units: 1 u = 32 px; timing in frames @60 fps.

| Data | Owner |
|---|---|
| Clock, phase, thresholds, overflow | `RunClock` (autoload `Run`) |
| Power floor, peak power, score | `Run` |
| Adaptations, techniques, insights (this run) | `Run.build` |
| Zenith kinematics, ki, combat state | `Zenith` node |
| Current dimension, marks, map state | `Multiverse` autoload |
| Codex, unlocks, settings | `Profile` autoload (persisted) |
| Tuning | `data/tuning.tres` (single file, sections per §7/§8/§5) |

All numbers provisional unless marked LOCKED. Performance: 60 fps locked on a 2019 MacBook Pro i9 (Intel UHD 630 / Radeon 5300M) at 1080p with 60 enemies + overflow effects; frame time ≤ 16.6 ms p99; boot to title ≤ 3 s; memory ≤ 1.5 GB.

## Combat model

**States:** Neutral (move ✔ act ✔ vulnerable ✔) · Attacking (move ✖ act: cancel into next string/burst/transmit · vulnerable ✔) · Bursting (✔ / ✖ / i-frames) · Guarding (slow move / ✖ / guarded) · Staggered (8f ✖ ✖ ✔, no further time loss during stagger) · Transmit recovery (✖ / cancel on hit / ✔).

| Move | Startup | Active | Recovery | Damage | Notes |
|---|---|---|---|---|---|
| Light 1 / 2 / 3 | 4 / 4 / 5 | 3 | 10 / 10 / 16 | 25 / 35 / 55 | Reset after 51f without input; step 6 u/s |
| Heavy launcher | 9 | 4 | 20 | 85 | Launch 55 u/s, 8 dirs; chase window 75f |
| Volley bolt | 3 | proj | 6 | 18 | 48 u/s, 8 ki |
| Beam | charge ≤ 90 | sustain ≤ 60 | 24 | 240/s × charge | 40 ki, steer 3.5 rad/s |
| Burst field | 8 | 6 | 18 | 75 | r = 10 u, 30 ki |

**Hit resolution:** hurtboxes per sprite pose; Zenith attacks beat enemy startup on trade; i-frames on burst/transmit arrival (6f); armored enemies take damage without flinch until armor (3 hits) breaks; launched enemies are invulnerable to other enemies, collide with terrain (bounce, crater decal); each hit has its own hitstun (light 18f, heavy = launch). **No juggle decay** (Limitless) — enemies are balanced by armor and HP, not combo caps.

**Ki:** 0–100 (150 with Vessel Expansion). +16 per landed hit, +10 per perfect guard. No passive regen. Decision it creates: spend small and often (volley) or bank for beam.

## Enemies & bosses

| Enemy | Dimension | HP | Behavior | Lesson |
|---|---|---|---|---|
| Drone | Threshold | 60 | Hovers, telegraphed dash (30f windup) | Strings |
| Brute | Threshold | 220 | Ground slam (40f windup, orange flash) | Launch & chase |
| Slammer | Leadfall | 320, armor 3 | Crushing leaps | Weight / armor break |
| Gunner | Leadfall | 140 | Heavy bolts, keeps distance | Transmit to close |
| Flyer | Skyreach | 90 | Swoops in flocks of 5 | Flight combat; falls under carried Weight |
| Lancer | Skyreach | 180 | Long charge across screen | Perfect guard |

Enemy HP scales with dimension band × elapsed-time curve so the time floor "roughly keeps pace" (§Progression).

**The Bloom (first-run threat):** spreads one node per 4:00 if unchecked (consumed nodes: XP ×2, enemies +1 band). Lair appears on the map at 6:00 (signs: magenta vines on node). TTK targets: early hunt at 10:00 ≈ 4 min; Fade Fight at full power ≈ 45 s of the 60 s fade. Phases: (1) vine walls + spore volleys, 60f telegraphs; (2) splits into 3 cores you chase between; (3) beam clash set piece (mash/hold to win; win → finisher).

## AI

Enemies should commit, telegraph, and get bodied; they should not dodge-spam, snipe off-screen, or stunlock. States: Idle → Approach → Windup (telegraph) → Attack → Recover → (Hit / Launched / Down). Max 2 enemies in Windup against Zenith at once (attack tokens). Difficulty levers: windup length, token count, HP band. No cheating.

## Camera

`Camera2D` with look-ahead in velocity direction (up to 4 u), smoothing 8. Priority: Zenith > launched target in chase window (camera frames both, zoom out to 0.8 max) > boss. Special states: beam fire (zoom 0.9, slight shake), threshold (zoom 1.15 on Zenith, background freeze), overflow (permanent 0.9 zoom + micro-shake), fade (slow push-in to 1.3).

## Levels / dimensions

Dimensions are **authored chunks** (1 chunk = 60×34 tiles ≈ one screen ×1.5) assembled per run from a pool of 8 per dimension by seed. Grounded dimensions: 6 chunks wide, wrap horizontally. Skyreach: 6×3 chunk grid of open sky with cloud platforms, wraps both axes.

| Dimension | Rule (data) | Adaptation (exposure 100) | Cost |
|---|---|---|---|
| Threshold | none | none | — |
| Leadfall | gravity ×2 for all actors | **Weight**: hits pin (60f), crush ×1.55 | flight speed ×0.7 |
| Skyreach | no ground; all enemies fly | **Lift**: full-speed hover combat | Zenith knockback ×1.45 |

**Signature interaction (slice):** entering Skyreach with Weight → flyers within 12 u fall (gravity 35 u/s²), Skyreach is **marked** on the map for the rest of the run (visual: iron-grey streaks on its node; flyers spawn grounded-capable).

Exposure: +1 per hit landed in that dimension, +5 per kill; adaptation at 100. Rules are data (`data/dimensions/*.tres`) so every rule can attach to technique forms later.

## Progression & economy

- **Power floor:** `floor(t) = 1 + 2.5 × (t / 1800)^1.4` (t = elapsed seconds). Multiplies technique/adaptation effects (not flat stats).
- **Level bands:** XP per kill = base × band_factor, where band_factor = 0.1 if dimension band < player band − 1, 1.0 if equal, 3.0 if one above (enemies hit 1.5× harder, HP ×2). Player band = 1 + floor(xp_level / 5).
- **Thresholds (10:00 / 20:00 / 28:00):** spectacle moment + pick 1 of 3 from the option pool. Every option must change play immediately:

| Option | Category | Effect |
|---|---|---|
| Resonant Beam | technique | Beam charge 40% faster, +50% width |
| Omni-Burst Field | technique | Field radius +60%, reflects bolts |
| Martial Fluency | passive | +50% ki on hit; transmit recovery 0f |
| Phantom Echo | passive | Perfect guard leaves 2 detonating afterimages |
| Vessel Expansion | ki | Max ki 150 |
| Split Beam | technique | Beam splits into 3 on impact |
| Chase Mastery | passive | Chase window +40f; chase arrival deals 40 dmg |

- **Insight (slice: 2 insights):** beam fired within 20f after a transmit ×3 → "Transmission Beam" (fire beam directly out of transmit); heavy launch while bursting ×3 → "Burst Launcher." Recorded in Codex.
- **Meta:** Codex entries persist; unlocks widen threshold pool and dimension list. No stat upgrades.

## Save & persistence

`user://profile.json`: Codex, unlocks, settings, best scores, run history (last 50). Written at run end and on settings change; atomic write (temp + rename); corrupt file → backup `profile.bak.json`, else fresh profile + toast. `version` field with migration function per bump. Runs are not resumable (a life is a life).

## Accessibility

Full remapping; hold/toggle for guard and beam; numeric clock option; screen shake 0–100%; flash/inversion intensity 0–100% (0 = replace inversion with brightness pulse); colorblind-safe enemy warning (shape + color); subtitles for all lines; game speed 70/85/100% (disables leaderboards).

## Telemetry & playtest

Local-only session log (`user://telemetry/`): time-to-first-chase, chases per minute, time per dimension, threshold picks, clock lost to hits per minute, run result. Playtest questions: Did you understand the clock is your health? When did you first chase? Why did you leave each dimension? Did Zenith ever get lost on screen?

## 16. Definition of Done

- **Gameplay:** full run from Title to Legacy on the prototype route with thresholds, overflow, Fade Fight, early-hunt path, and the Weight→Skyreach mark all working.
- **Content:** every slice row in §14 present at placeholder-final quality (procedural art that looks intentional).
- **Presentation:** diegetic clock reads in all three ways; impact stack (hitstop, inversion, shake, lines, afterimages) on every defining action; all music cues and SFX categories present.
- **UX:** every screen in §10 navigable by pad and KBM, edge cases handled.
- **Stability:** zero errors/warnings on headless boot; bot playthrough passes; 60 fps at target density.
- **Release:** exports for macOS + Windows build cleanly; Legacy screen screenshot shareable.

## 17. Definition of Great

1. A new player performs their first chase within 30 seconds without reading text.
2. A player can say "I'm at about 18 minutes" from Zenith's body alone, ±2 minutes.
3. Playtesters describe the Weight-into-Skyreach moment unprompted.
4. On a 10-minute clock preset, a tester's second run is meaningfully different from the first (route or threshold picks).
5. Recorded footage of the final 60 seconds is something a tester would post.

## 18. Autonomous decision rules

Preserve pillars → fantasy → readability → responsiveness. Choose the simplest solution that serves the experience. Never add mechanics, currencies, screens, or systems to fill gaps. Never remove intentional friction (time costs) because smoother is easier. Never change LOCKED values without logging why. Reversible and minor → choose and continue. Log meaningful assumptions in `DECISIONS.md`.

## 19. Open questions

| Question | Importance | Current lean | Blocks build? |
|---|---|---|---|
| Fade lines: how many, exact text | High (signature moment) | 5 lines; placeholder set in `data/fade_lines.tres` | No |
| Full threat roster beyond The Bloom | Medium | Silence + Ascendant next | No |
| Chunk layouts per dimension | Medium | Builder authors 8 per slice dimension | No |
| Final time costs | Medium | §5 table, tune via playtest | No |
| Trademark/store search for KAIROS | Low (pre-ship) | Run before Steam page | No |

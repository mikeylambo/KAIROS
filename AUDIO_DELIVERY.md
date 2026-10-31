# AUDIO DELIVERY

All audio loads by key through `data/audio_manifest.tres` (`res://assets/audio/sfx/<key>.ogg`, `res://assets/audio/music/<key>.ogg`). Missing file → deterministic synthesized placeholder (`scripts/audio/Synth.gd`). Buses: Master → Music / SFX / Voice. Mix: voice > time-loss > hits > music; music ducks −6 dB during beam fire. Normalize music −14 LUFS, −1 dBTP. OGG.

| Key | Description | Length | Loop | Mix notes |
|---|---|---|---|---|
| hit_light | Layered thump + crack; engine pitch-rises +5%/hit within a chain (cap +60%) | 0.1 s | no | short transient |
| hit_heavy | Deep thump + crack (launch, collisions, terrain impact at lower pitch) | 0.3 s | no | sits under voice |
| transmit | Vacuum pop → arrival crack | 0.2 s | no | |
| beam_charge | Rising tone | 1.5 s | no | |
| beam_fire | Sustained roar | 1.2 s | no | music ducks −6 dB while active |
| beam_end | Glass shatter (finisher) | 0.9 s | no | |
| time_loss | Reversed crystal shard | 0.3 s | no | **above hits** (+2 dB) |
| threshold | Choir swell + bell | 2.2 s | no | |
| perfect | Glass chime | 0.6 s | no | |
| burst | Air cut | 0.15 s | no | |
| field | Low boom + whoosh | 0.45 s | no | |
| whiff | Swoosh (also volley at higher pitch) | 0.12 s | no | |
| jump | Soft air puff | 0.1 s | no | −8 dB |
| crack | World break / billboard | 0.25 s | no | |
| bloom_roar | Bloom phase change | 1.6 s | no | |
| note | Single sustained note under the fade line | 6 s | no | after music cuts to silence |
| ui_move / ui_select | UI tick / confirm | 0.05 / 0.18 s | no | |
| music_title | Title pad | 8 s+ | yes | |
| music_threshold / leadfall / skyreach | Dimension theme. Two stems: pad (always) + pulse (intensity 2 when ≥ 6 enemies on screen) | 8 s+ | yes | crossfade 1.5 s on arrival |
| music_corridor | Sparse pads | 8 s+ | yes | |
| music_overflow | All themes collapse into one driving cue (28:00) | 8 s+ | yes | |
| music_fade_fight | Final cue; the pulse stem fades out as the fade progresses | 8 s+ | yes | |
| voice_zenith_line | "Thirty minutes. Plenty." — calm, unhurried, slightly amused | ~2 s | no | Voice bus; subtitles always available |

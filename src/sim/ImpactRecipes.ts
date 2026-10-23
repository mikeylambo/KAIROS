import type { ImpactRecipe } from "../ported/impact/types.js";

export const IMPACT_RECIPES: Record<string, ImpactRecipe> = {
  "kairos.hit.light": {
    id: "kairos.hit.light",
    duration: 0.15,
    tags: ["combat", "light", "melee"],
    cues: [
      {
        id: "light-hitstop",
        at: 0.0,
        channel: "gameplay",
        payload: { type: "hitstop", frames: 4 }
      },
      {
        id: "light-shake",
        at: 0.0,
        channel: "camera",
        payload: { type: "shake", intensity: 0.25, duration: 0.12 }
      },
      {
        id: "light-vfx-spark",
        at: 0.0,
        channel: "vfx",
        payload: { type: "spark-burst", count: 8, color: "#ffe680", scale: 1.0 }
      },
      {
        id: "light-sfx",
        at: 0.0,
        channel: "audio",
        payload: { sound: "hit-light", volume: 0.75, pitch: 1.1 }
      }
    ]
  },

  "kairos.hit.heavy": {
    id: "kairos.hit.heavy",
    duration: 0.35,
    tags: ["combat", "heavy", "melee"],
    cues: [
      {
        id: "heavy-hitstop",
        at: 0.0,
        channel: "gameplay",
        payload: { type: "hitstop", frames: 10 }
      },
      {
        id: "heavy-impact-frame",
        at: 0.0,
        channel: "ui",
        payload: { type: "impact-frame", frames: 2, inversion: "tri-color" }
      },
      {
        id: "heavy-shake",
        at: 0.0,
        channel: "camera",
        payload: { type: "shake", intensity: 0.85, duration: 0.28 }
      },
      {
        id: "heavy-vfx-flash",
        at: 0.0,
        channel: "vfx",
        payload: { type: "impact-shockwave", radius: 3.5, color: "#00f0ff" }
      },
      {
        id: "heavy-sfx",
        at: 0.0,
        channel: "audio",
        payload: { sound: "hit-heavy", volume: 1.0, pitch: 0.95 }
      }
    ]
  },

  "kairos.launch.directional": {
    id: "kairos.launch.directional",
    duration: 0.45,
    tags: ["combat", "launcher"],
    cues: [
      {
        id: "launch-hitstop",
        at: 0.0,
        channel: "gameplay",
        payload: { type: "hitstop", frames: 12 }
      },
      {
        id: "launch-impact-frame",
        at: 0.0,
        channel: "ui",
        payload: { type: "impact-frame", frames: 2, inversion: "invert" }
      },
      {
        id: "launch-camera-punch",
        at: 0.02,
        channel: "camera",
        payload: { type: "punch-zoom", zoom: 1.25, duration: 0.25 }
      },
      {
        id: "launch-speed-lines",
        at: 0.02,
        channel: "vfx",
        payload: { type: "speed-lines", duration: 0.4, intensity: 1.0 }
      },
      {
        id: "launch-sfx",
        at: 0.0,
        channel: "audio",
        payload: { sound: "launch-boom", volume: 1.0 }
      }
    ]
  },

  "kairos.chase.impact": {
    id: "kairos.chase.impact",
    duration: 0.3,
    tags: ["combat", "chase"],
    cues: [
      {
        id: "chase-hitstop",
        at: 0.0,
        channel: "gameplay",
        payload: { type: "hitstop", frames: 8 }
      },
      {
        id: "chase-warp-flash",
        at: 0.0,
        channel: "vfx",
        payload: { type: "afterimage-burst", count: 4, color: "#ff007f" }
      },
      {
        id: "chase-camera-shake",
        at: 0.0,
        channel: "camera",
        payload: { type: "shake", intensity: 0.65, duration: 0.2 }
      },
      {
        id: "chase-sfx",
        at: 0.0,
        channel: "audio",
        payload: { sound: "chase-intercept", volume: 0.9 }
      }
    ]
  },

  "kairos.guard.perfect": {
    id: "kairos.guard.perfect",
    duration: 0.4,
    tags: ["combat", "defense", "counter"],
    cues: [
      {
        id: "perfect-hitstop",
        at: 0.0,
        channel: "gameplay",
        payload: { type: "hitstop", frames: 14 }
      },
      {
        id: "perfect-impact-frame",
        at: 0.0,
        channel: "ui",
        payload: { type: "impact-frame", frames: 3, inversion: "tri-color" }
      },
      {
        id: "perfect-afterimage-shatter",
        at: 0.0,
        channel: "vfx",
        payload: { type: "glass-shatter", color: "#e0f7fa" }
      },
      {
        id: "perfect-camera-slow",
        at: 0.0,
        channel: "camera",
        payload: { type: "slowmo", factor: 0.15, duration: 0.35 }
      },
      {
        id: "perfect-sfx",
        at: 0.0,
        channel: "audio",
        payload: { sound: "afterimage-shatter", volume: 1.0 }
      }
    ]
  },

  "kairos.transmission.warp": {
    id: "kairos.transmission.warp",
    duration: 0.25,
    tags: ["movement", "transmission"],
    cues: [
      {
        id: "warp-afterimage",
        at: 0.0,
        channel: "vfx",
        payload: { type: "trailing-afterimage", duration: 0.3, alpha: 0.85 }
      },
      {
        id: "warp-sfx",
        at: 0.0,
        channel: "audio",
        payload: { sound: "instant-transmission", volume: 0.85, pitch: 1.2 }
      }
    ]
  },

  "kairos.beam.fire": {
    id: "kairos.beam.fire",
    duration: 1.2,
    tags: ["combat", "ki", "beam"],
    cues: [
      {
        id: "beam-recoil-shake",
        at: 0.0,
        channel: "camera",
        payload: { type: "continuous-shake", intensity: 0.7, duration: 1.0 }
      },
      {
        id: "beam-scorch-vfx",
        at: 0.05,
        channel: "vfx",
        payload: { type: "terrain-scorch", width: 2.0 }
      },
      {
        id: "beam-fire-sfx",
        at: 0.0,
        channel: "audio",
        payload: { sound: "beam-loop", volume: 1.0, loopDuration: 1.0 }
      }
    ]
  },

  "kairos.burst.dash": {
    id: "kairos.burst.dash",
    duration: 0.2,
    tags: ["movement", "burst"],
    cues: [
      {
        id: "burst-lines",
        at: 0.0,
        channel: "vfx",
        payload: { type: "dash-ribbon", color: "#00f0ff" }
      },
      {
        id: "burst-sfx",
        at: 0.0,
        channel: "audio",
        payload: { sound: "burst-dash", volume: 0.8 }
      }
    ]
  },

  "kairos.overflow.crack": {
    id: "kairos.overflow.crack",
    duration: 0.5,
    tags: ["overflow", "spectacle"],
    cues: [
      {
        id: "crack-shake",
        at: 0.0,
        channel: "camera",
        payload: { type: "shake", intensity: 1.2, duration: 0.4 }
      },
      {
        id: "crack-vfx-fracture",
        at: 0.0,
        channel: "vfx",
        payload: { type: "screen-crack", shards: 12, glow: "#ff007f" }
      },
      {
        id: "crack-sfx",
        at: 0.0,
        channel: "audio",
        payload: { sound: "dimension-crack", volume: 1.0 }
      }
    ]
  },

  "kairos.fade.dissolve": {
    id: "kairos.fade.dissolve",
    duration: 3.5,
    tags: ["ending", "fade"],
    cues: [
      {
        id: "fade-slowmo",
        at: 0.0,
        channel: "camera",
        payload: { type: "cinematic-zoom", duration: 3.0, targetZoom: 1.4 }
      },
      {
        id: "fade-particles",
        at: 0.2,
        channel: "vfx",
        payload: { type: "gold-mote-dissolve", count: 120, color: "#fff3a8" }
      },
      {
        id: "fade-soundscape",
        at: 0.0,
        channel: "audio",
        payload: { sound: "fade-resonance", volume: 1.0 }
      }
    ]
  },

  "kairos.ground.crush": {
    id: "kairos.ground.crush",
    duration: 0.35,
    tags: ["combat", "weight", "slam"],
    cues: [
      {
        id: "crush-hitstop",
        at: 0.0,
        channel: "gameplay",
        payload: { type: "hitstop", frames: 8 }
      },
      {
        id: "crush-shake",
        at: 0.0,
        channel: "camera",
        payload: { type: "shake", intensity: 0.75, duration: 0.22 }
      },
      {
        id: "crush-ground-shockwave",
        at: 0.0,
        channel: "vfx",
        payload: { type: "ground-shockwave", radius: 5.0, color: "#d97706" }
      },
      {
        id: "crush-sfx",
        at: 0.0,
        channel: "audio",
        payload: { sound: "ground-slam", volume: 0.95 }
      }
    ]
  }
};

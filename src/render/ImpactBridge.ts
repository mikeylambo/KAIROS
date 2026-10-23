import { ImpactPlayer } from "../ported/impact/ImpactPlayer.js";
import type { ImpactCue, ImpactRecipe, ImpactSpawnContext } from "../ported/impact/types.js";
import { IMPACT_RECIPES } from "../sim/ImpactRecipes.js";

export class KairosImpactBridge {
  public player: ImpactPlayer;
  public activeImpactFrames: number = 0;
  public impactFrameType: "invert" | "tri-color" = "invert";
  public screenShake: number = 0;
  public cameraPunchZoom: number = 1.0;
  public slowmoFactor: number = 1.0;
  public slowmoDuration: number = 0;
  public speedLinesIntensity: number = 0;

  // Web Audio Context for zero-asset dynamic sound effects
  private audioCtx?: AudioContext;

  constructor() {
    this.player = new ImpactPlayer({
      onCue: (id, recipe, cue, context) => this.handleCue(cue, context),
      onComplete: (id, recipe) => {}
    });
  }

  ensureAudio(): void {
    if (!this.audioCtx && typeof window !== "undefined") {
      const AudioCtx = window.AudioContext || (window as unknown as { webkitAudioContext: typeof AudioContext }).webkitAudioContext;
      if (AudioCtx) {
        this.audioCtx = new AudioCtx();
      }
    }
    if (this.audioCtx?.state === "suspended") {
      this.audioCtx.resume();
    }
  }

  triggerRecipe(recipeId: string, context: ImpactSpawnContext = {}): void {
    const recipe = IMPACT_RECIPES[recipeId];
    if (recipe) {
      this.player.play(recipe, context);
    }
  }

  update(dt: number): void {
    this.player.update(dt);

    // Decay screenshake
    if (this.screenShake > 0) {
      this.screenShake = Math.max(0, this.screenShake - dt * 4.0);
    }

    // Decay camera punch zoom
    if (this.cameraPunchZoom > 1.0) {
      this.cameraPunchZoom = Math.max(1.0, this.cameraPunchZoom - dt * 2.0);
    }

    // Decay speed lines
    if (this.speedLinesIntensity > 0) {
      this.speedLinesIntensity = Math.max(0, this.speedLinesIntensity - dt * 3.0);
    }

    // Decay slowmo
    if (this.slowmoDuration > 0) {
      this.slowmoDuration -= dt;
      if (this.slowmoDuration <= 0) {
        this.slowmoFactor = 1.0;
      }
    }
  }

  private handleCue(cue: ImpactCue, context: ImpactSpawnContext): void {
    const p = cue.payload ?? {};

    switch (cue.channel) {
      case "ui":
        if (p.type === "impact-frame") {
          this.activeImpactFrames = Number(p.frames ?? 2);
          this.impactFrameType = (p.inversion as "invert" | "tri-color") ?? "invert";
        }
        break;

      case "camera":
        if (p.type === "shake" || p.type === "continuous-shake") {
          this.screenShake = Math.max(this.screenShake, Number(p.intensity ?? 0.5));
        } else if (p.type === "punch-zoom") {
          this.cameraPunchZoom = Number(p.zoom ?? 1.25);
        } else if (p.type === "slowmo") {
          this.slowmoFactor = Number(p.factor ?? 0.2);
          this.slowmoDuration = Number(p.duration ?? 0.3);
        }
        break;

      case "vfx":
        if (p.type === "speed-lines") {
          this.speedLinesIntensity = Number(p.intensity ?? 1.0);
        }
        break;

      case "audio":
        this.playSyntheticAudio(String(p.sound ?? "hit"), Number(p.volume ?? 1.0), Number(p.pitch ?? 1.0));
        break;
    }
  }

  /**
   * High-quality procedural sound synthesizer: creates crisp, punchy audio without external assets.
   */
  private playSyntheticAudio(sound: string, volume: number = 1.0, pitch: number = 1.0): void {
    if (!this.audioCtx) return;
    const ctx = this.audioCtx;
    const now = ctx.currentTime;

    switch (sound) {
      case "hit-light": {
        const osc = ctx.createOscillator();
        const gain = ctx.createGain();
        osc.type = "triangle";
        osc.frequency.setValueAtTime(420 * pitch, now);
        osc.frequency.exponentialRampToValueAtTime(80, now + 0.12);
        gain.gain.setValueAtTime(0.3 * volume, now);
        gain.gain.exponentialRampToValueAtTime(0.01, now + 0.12);
        osc.connect(gain);
        gain.connect(ctx.destination);
        osc.start(now);
        osc.stop(now + 0.12);
        break;
      }

      case "hit-heavy":
      case "launch-boom": {
        // Deep bass sub + noise punch
        const osc = ctx.createOscillator();
        const gain = ctx.createGain();
        osc.type = "sawtooth";
        osc.frequency.setValueAtTime(260 * pitch, now);
        osc.frequency.exponentialRampToValueAtTime(35, now + 0.28);
        gain.gain.setValueAtTime(0.6 * volume, now);
        gain.gain.exponentialRampToValueAtTime(0.001, now + 0.3);
        osc.connect(gain);
        gain.connect(ctx.destination);
        osc.start(now);
        osc.stop(now + 0.3);
        break;
      }

      case "instant-transmission": {
        const osc = ctx.createOscillator();
        const gain = ctx.createGain();
        osc.type = "sine";
        osc.frequency.setValueAtTime(1400 * pitch, now);
        osc.frequency.exponentialRampToValueAtTime(280, now + 0.18);
        gain.gain.setValueAtTime(0.4 * volume, now);
        gain.gain.exponentialRampToValueAtTime(0.01, now + 0.18);
        osc.connect(gain);
        gain.connect(ctx.destination);
        osc.start(now);
        osc.stop(now + 0.18);
        break;
      }

      case "afterimage-shatter": {
        // Crystal ring
        const osc = ctx.createOscillator();
        const gain = ctx.createGain();
        osc.type = "sine";
        osc.frequency.setValueAtTime(1850 * pitch, now);
        osc.frequency.linearRampToValueAtTime(2400, now + 0.3);
        gain.gain.setValueAtTime(0.5 * volume, now);
        gain.gain.exponentialRampToValueAtTime(0.005, now + 0.35);
        osc.connect(gain);
        gain.connect(ctx.destination);
        osc.start(now);
        osc.stop(now + 0.35);
        break;
      }

      case "burst-dash": {
        const osc = ctx.createOscillator();
        const gain = ctx.createGain();
        osc.type = "sine";
        osc.frequency.setValueAtTime(220, now);
        osc.frequency.linearRampToValueAtTime(650, now + 0.15);
        gain.gain.setValueAtTime(0.35 * volume, now);
        gain.gain.exponentialRampToValueAtTime(0.01, now + 0.16);
        osc.connect(gain);
        gain.connect(ctx.destination);
        osc.start(now);
        osc.stop(now + 0.16);
        break;
      }

      case "beam-loop": {
        const osc = ctx.createOscillator();
        const gain = ctx.createGain();
        osc.type = "sawtooth";
        osc.frequency.setValueAtTime(160 * pitch, now);
        osc.frequency.linearRampToValueAtTime(240, now + 0.6);
        gain.gain.setValueAtTime(0.4 * volume, now);
        gain.gain.exponentialRampToValueAtTime(0.01, now + 0.6);
        osc.connect(gain);
        gain.connect(ctx.destination);
        osc.start(now);
        osc.stop(now + 0.6);
        break;
      }

      case "dimension-crack": {
        const osc = ctx.createOscillator();
        const gain = ctx.createGain();
        osc.type = "triangle";
        osc.frequency.setValueAtTime(900, now);
        osc.frequency.exponentialRampToValueAtTime(45, now + 0.4);
        gain.gain.setValueAtTime(0.7 * volume, now);
        gain.gain.exponentialRampToValueAtTime(0.001, now + 0.45);
        osc.connect(gain);
        gain.connect(ctx.destination);
        osc.start(now);
        osc.stop(now + 0.45);
        break;
      }
    }
  }
}

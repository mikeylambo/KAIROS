import type { PlayerInput } from "./types.js";

export interface ReplayFrame {
  tick: number;
  input: PlayerInput;
}

export interface ReplayData {
  version: 1;
  seed: number;
  runDurationSeconds: number;
  frames: ReplayFrame[];
}

export class ReplayRecorder {
  private frames: ReplayFrame[] = [];
  private seed: number;
  private duration: number;

  constructor(seed: number, duration: number) {
    this.seed = seed;
    this.duration = duration;
  }

  reset(seed: number, duration: number): void {
    this.seed = seed;
    this.duration = duration;
    this.frames = [];
  }

  recordTick(tick: number, input: PlayerInput): void {
    // Record clone of input
    this.frames.push({
      tick,
      input: { ...input }
    });
  }

  exportData(): ReplayData {
    return {
      version: 1,
      seed: this.seed,
      runDurationSeconds: this.duration,
      frames: [...this.frames]
    };
  }

  getFrameCount(): number {
    return this.frames.length;
  }
}

export class ReplayPlayer {
  private frames: ReplayFrame[] = [];
  private index: number = 0;
  public active: boolean = false;
  public seed: number = 42;
  public duration: number = 1800;

  load(data: ReplayData): void {
    this.seed = data.seed;
    this.duration = data.runDurationSeconds;
    this.frames = [...data.frames];
    this.index = 0;
    this.active = true;
  }

  sampleTick(tick: number): PlayerInput | null {
    if (!this.active || this.index >= this.frames.length) {
      this.active = false;
      return null;
    }

    const frame = this.frames[this.index];
    if (frame && frame.tick <= tick) {
      this.index++;
      return frame.input;
    }

    return null;
  }

  stop(): void {
    this.active = false;
    this.index = 0;
  }

  getProgress(): number {
    return this.frames.length > 0 ? this.index / this.frames.length : 0;
  }
}

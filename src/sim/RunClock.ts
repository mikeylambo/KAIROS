import { TUNING } from "./Tuning.js";
import type { ThresholdOption } from "./types.js";

export type RunPhase =
  | "running"
  | "threshold-choice"
  | "fade-fight"
  | "fade-dissolve"
  | "ended";

export interface ClockState {
  totalDurationSeconds: number;
  remainingSeconds: number;
  elapsedSeconds: number;
  phase: RunPhase;
  thresholdReached: [boolean, boolean, boolean]; // 10m, 20m, 28m
  inOverflow: boolean;
  fadeDissolveRemainingSeconds: number;
  continuousPowerMultiplier: number;
  staggerRemainingSeconds: number;
  diegeticFrayProgress: number; // 0 (pristine) -> 1 (completely frayed)
  diegeticCrackProgress: number; // 0 (hairline) -> 1 (wide open glowing)
  diegeticAfterimageLag: number; // in seconds of delayed trail
}

export class RunClock {
  public state: ClockState;
  public onThresholdTriggered?: (thresholdIndex: number, options: ThresholdOption[]) => void;
  public onOverflowEntered?: () => void;
  public onFadeFightStarted?: () => void;
  public onRunEnded?: (fadeLine: string) => void;

  private availableUpgrades: ThresholdOption[] = [
    {
      id: "opt-beam-power",
      title: "Resonant Beam",
      description: "Charge beam fires 40% faster and deals +50% wider pierce damage.",
      category: "technique",
      apply: () => {}
    },
    {
      id: "opt-burst-field-range",
      title: "Omni-Burst Field",
      description: "Burst Field expands 60% larger and reflects all incoming enemy bolts.",
      category: "technique",
      apply: () => {}
    },
    {
      id: "opt-flow-efficiency",
      title: "Martial Fluency",
      description: "Landing hits grants +50% Ki; combat instant transmission recovers instantly.",
      category: "passive",
      apply: () => {}
    },
    {
      id: "opt-afterimage-echo",
      title: "Phantom Echo",
      description: "Perfect guards leave two afterimages that detonate on contact.",
      category: "passive",
      apply: () => {}
    },
    {
      id: "opt-ki-capacity",
      title: "Vessel Expansion",
      description: "Maximum Ki raised to 150; heavy launchers cost 0 Ki.",
      category: "ki",
      apply: () => {}
    }
  ];

  constructor(durationSeconds?: number) {
    const total = durationSeconds ?? TUNING.get().clock.defaultRunDurationSeconds;
    this.state = {
      totalDurationSeconds: total,
      remainingSeconds: total,
      elapsedSeconds: 0,
      phase: "running",
      thresholdReached: [false, false, false],
      inOverflow: false,
      fadeDissolveRemainingSeconds: TUNING.get().clock.fadeDissolveDurationSeconds,
      continuousPowerMultiplier: 1.0,
      staggerRemainingSeconds: 0,
      diegeticFrayProgress: 0,
      diegeticCrackProgress: 0,
      diegeticAfterimageLag: 0.05
    };
  }

  reset(newDurationSeconds?: number): void {
    const total = newDurationSeconds ?? TUNING.get().clock.defaultRunDurationSeconds;
    this.state.totalDurationSeconds = total;
    this.state.remainingSeconds = total;
    this.state.elapsedSeconds = 0;
    this.state.phase = "running";
    this.state.thresholdReached = [false, false, false];
    this.state.inOverflow = false;
    this.state.fadeDissolveRemainingSeconds = TUNING.get().clock.fadeDissolveDurationSeconds;
    this.state.continuousPowerMultiplier = 1.0;
    this.state.staggerRemainingSeconds = 0;
    this.state.diegeticFrayProgress = 0;
    this.state.diegeticCrackProgress = 0;
    this.state.diegeticAfterimageLag = 0.05;
  }

  deductTime(seconds: number): void {
    if (this.state.phase !== "running" && this.state.phase !== "fade-fight") return;
    this.state.remainingSeconds = Math.max(0, this.state.remainingSeconds - seconds);
    this.state.staggerRemainingSeconds = Math.min(0.4, seconds * 0.08);
  }

  tick(dt: number, threatDefeated: boolean): void {
    if (this.state.phase === "ended" || this.state.phase === "threshold-choice") return;

    if (this.state.phase === "fade-dissolve") {
      this.state.fadeDissolveRemainingSeconds -= dt;
      if (this.state.fadeDissolveRemainingSeconds <= 0) {
        this.endRun("Thirty minutes was more than enough.");
      }
      return;
    }

    if (this.state.phase === "fade-fight") {
      this.state.fadeDissolveRemainingSeconds -= dt;
      this.state.elapsedSeconds += dt;
      this.updateDiegeticVisuals();

      if (threatDefeated) {
        // Defeated threat during the fade fight!
        this.triggerFadeDissolve();
      } else if (this.state.fadeDissolveRemainingSeconds <= 0) {
        // Dissolve completed before defeating threat!
        this.endRun("The container breaks, but the fire never goes out.");
      }
      return;
    }

    // Normal running phase
    this.state.elapsedSeconds += dt;
    this.state.remainingSeconds = Math.max(0, this.state.remainingSeconds - dt);

    if (this.state.staggerRemainingSeconds > 0) {
      this.state.staggerRemainingSeconds = Math.max(0, this.state.staggerRemainingSeconds - dt);
    }

    const tuning = TUNING.get().clock;
    // Continuous power growth multiplier
    const progress = Math.min(1.0, this.state.elapsedSeconds / this.state.totalDurationSeconds);
    this.state.continuousPowerMultiplier = tuning.basePowerMultiplier + progress * tuning.floorGrowthRate;

    // Check thresholds: 10m, 20m, 28m
    const scale = this.state.totalDurationSeconds / 1800;
    const t1 = tuning.threshold1Seconds;
    const t2 = tuning.threshold2Seconds;
    const t3 = tuning.threshold3Seconds;

    if (!this.state.thresholdReached[0] && this.state.elapsedSeconds >= t1) {
      this.state.thresholdReached[0] = true;
      this.triggerThreshold(0);
    } else if (!this.state.thresholdReached[1] && this.state.elapsedSeconds >= t2) {
      this.state.thresholdReached[1] = true;
      this.triggerThreshold(1);
    } else if (!this.state.thresholdReached[2] && this.state.elapsedSeconds >= t3) {
      this.state.thresholdReached[2] = true;
      this.state.inOverflow = true;
      this.onOverflowEntered?.();
      this.triggerThreshold(2);
    }

    if (this.state.elapsedSeconds >= tuning.overflowStartSeconds) {
      this.state.inOverflow = true;
    }

    this.updateDiegeticVisuals();

    // Reached 30:00 (clock empty)
    if (this.state.remainingSeconds <= 0) {
      if (threatDefeated) {
        this.triggerFadeDissolve();
      } else {
        // Threat not defeated: starts 60-second fade fight!
        this.state.phase = "fade-fight";
        this.state.inOverflow = true;
        this.state.fadeDissolveRemainingSeconds = tuning.fadeDissolveDurationSeconds;
        this.onFadeFightStarted?.();
      }
    }
  }

  private triggerThreshold(index: number): void {
    // Pick 3 options for the player
    const pool = [...this.availableUpgrades];
    // Simple deterministic rotation based on threshold
    const selected = [pool[index % pool.length], pool[(index + 1) % pool.length], pool[(index + 2) % pool.length]];
    this.onThresholdTriggered?.(index, selected);
  }

  triggerFadeDissolve(): void {
    this.state.phase = "fade-dissolve";
    this.state.fadeDissolveRemainingSeconds = 3.5;
  }

  endRun(line: string): void {
    this.state.phase = "ended";
    this.onRunEnded?.(line);
  }

  private updateDiegeticVisuals(): void {
    const elapsedRatio = Math.min(1.0, this.state.elapsedSeconds / this.state.totalDurationSeconds);
    const timeRemainingRatio = this.state.remainingSeconds / this.state.totalDurationSeconds;

    // Fraying ribbon cloth: frays as time remaining drains
    this.state.diegeticFrayProgress = 1.0 - timeRemainingRatio;

    // Kintsugi cracks: hairline initially, glowing by 15:00 (50%), wide open by 28:00 (93%)
    if (elapsedRatio < 0.5) {
      this.state.diegeticCrackProgress = elapsedRatio * 0.4;
    } else if (elapsedRatio < 0.93) {
      this.state.diegeticCrackProgress = 0.2 + (elapsedRatio - 0.5) / 0.43 * 0.6;
    } else {
      this.state.diegeticCrackProgress = 0.8 + (elapsedRatio - 0.93) / 0.07 * 0.2;
    }

    // Afterimage lag distance increases as time runs low (0.05s up to 0.25s)
    this.state.diegeticAfterimageLag = 0.05 + this.state.diegeticFrayProgress * 0.20;
  }
}

export interface KairosTuning {
  // ── Clock & Vessel ────────────────────────────────────────────────────────
  clock: {
    defaultRunDurationSeconds: number; // 1800 (30m)
    lightHitCostSeconds: number; // 2.0s
    heavyHitCostSeconds: number; // 5.0s
    threshold1Seconds: number; // 600 (10:00)
    threshold2Seconds: number; // 1200 (20:00)
    threshold3Seconds: number; // 1680 (28:00)
    overflowStartSeconds: number; // 1680 (28:00)
    fadeDissolveDurationSeconds: number; // 60s
    teleportDimensionCostSeconds: number; // 5s
    basePowerMultiplier: number; // 1.0
    floorGrowthRate: number; // Max floor growth multiplier addition
  };

  // ── Zenith Movement ───────────────────────────────────────────────────────
  movement: {
    runSpeed: number; // 18
    runAcceleration: number; // 60
    runDeceleration: number; // 50
    jumpImpulse: number; // 22
    jumpCutMultiplier: number; // 0.5
    gravity: number; // -45
    terminalVelocity: number; // -40
    coyoteTimeSeconds: number; // 0.12
    jumpBufferSeconds: number; // 0.12

    // Free 8-Directional Flight
    flightSpeed: number; // 28
    flightAcceleration: number; // 40
    flightDeceleration: number; // 25
    flightTurnRate: number; // 12
    bankAngleMaxDegrees: number; // 25

    // Burst Dash
    burstSpeed: number; // 65
    burstDurationSeconds: number; // 0.18
    burstCooldownSeconds: number; // 0.35
    burstInvulnerableSeconds: number; // 0.18

    // Combat Instant Transmission
    transmissionRange: number; // 35
    transmissionRecoverySeconds: number; // 0.25
    transmissionBlindSpotOffset: number; // 2.8 behind enemy
  };

  // ── Zenith Combat ─────────────────────────────────────────────────────────
  combat: {
    // Light Combo
    light1Damage: number; // 25
    light2Damage: number; // 35
    light3Damage: number; // 55
    lightComboResetSeconds: number; // 0.85
    lightStepImpulse: number; // 6.0

    // Heavy Launcher
    heavyDamage: number; // 85
    heavyLaunchSpeed: number; // 55
    chaseWindowSeconds: number; // 1.25

    // Afterimage Evade / Perfect Guard
    perfectGuardWindowSeconds: number; // 0.10 (~6 frames)
    guardRecoverySeconds: number; // 0.35
    afterimageRepositionOffset: number; // 3.2

    // Ki System
    maxKi: number; // 100
    kiGainPerHit: number; // 15
    kiVolleyCost: number; // 8
    kiVolleyBoltSpeed: number; // 45
    kiVolleyBoltDamage: number; // 18
    beamCost: number; // 40
    beamMaxChargeSeconds: number; // 1.5
    beamBaseDamagePerSecond: number; // 220
    beamSteerSpeed: number; // 3.5
    burstFieldCost: number; // 30
    burstFieldDamage: number; // 70
    burstFieldRadius: number; // 10

    // Hitstop & Impact
    lightHitstopFrames: number; // 4
    heavyHitstopFrames: number; // 10
    finisherHitstopFrames: number; // 16
    screenShakeIntensityLight: number; // 0.25
    screenShakeIntensityHeavy: number; // 0.85
  };

  // ── Dimension Rules & Adaptations ─────────────────────────────────────────
  dimensions: {
    exposureMaxThreshold: number; // 100 combat XP to adapt
    leadfallGravityMultiplier: number; // 2.0
    leadfallZenithFlightSpeedPenalty: number; // 0.70 (30% slower)
    skyreachZenithKnockbackPenalty: number; // 1.45 (45% more knockback)
    carriedWeightFlyerGravity: number; // -35 pull down on flyers
    carriedWeightCrushDamageMultiplier: number; // 1.55
  };
}

export const DEFAULT_TUNING: KairosTuning = {
  clock: {
    defaultRunDurationSeconds: 1800,
    lightHitCostSeconds: 2.0,
    heavyHitCostSeconds: 5.0,
    threshold1Seconds: 600,
    threshold2Seconds: 1200,
    threshold3Seconds: 1680,
    overflowStartSeconds: 1680,
    fadeDissolveDurationSeconds: 60,
    teleportDimensionCostSeconds: 5,
    basePowerMultiplier: 1.0,
    floorGrowthRate: 2.5
  },
  movement: {
    runSpeed: 18,
    runAcceleration: 60,
    runDeceleration: 50,
    jumpImpulse: 24,
    jumpCutMultiplier: 0.5,
    gravity: -48,
    terminalVelocity: -42,
    coyoteTimeSeconds: 0.12,
    jumpBufferSeconds: 0.12,

    flightSpeed: 28,
    flightAcceleration: 42,
    flightDeceleration: 26,
    flightTurnRate: 12,
    bankAngleMaxDegrees: 25,

    burstSpeed: 65,
    burstDurationSeconds: 0.18,
    burstCooldownSeconds: 0.35,
    burstInvulnerableSeconds: 0.18,

    transmissionRange: 40,
    transmissionRecoverySeconds: 0.25,
    transmissionBlindSpotOffset: 2.8
  },
  combat: {
    light1Damage: 25,
    light2Damage: 35,
    light3Damage: 55,
    lightComboResetSeconds: 0.85,
    lightStepImpulse: 6.0,

    heavyDamage: 85,
    heavyLaunchSpeed: 55,
    chaseWindowSeconds: 1.25,

    perfectGuardWindowSeconds: 0.10,
    guardRecoverySeconds: 0.35,
    afterimageRepositionOffset: 3.2,

    maxKi: 100,
    kiGainPerHit: 16,
    kiVolleyCost: 8,
    kiVolleyBoltSpeed: 48,
    kiVolleyBoltDamage: 18,
    beamCost: 40,
    beamMaxChargeSeconds: 1.5,
    beamBaseDamagePerSecond: 240,
    beamSteerSpeed: 3.5,
    burstFieldCost: 30,
    burstFieldDamage: 75,
    burstFieldRadius: 10,

    lightHitstopFrames: 4,
    heavyHitstopFrames: 10,
    finisherHitstopFrames: 16,
    screenShakeIntensityLight: 0.3,
    screenShakeIntensityHeavy: 0.9
  },
  dimensions: {
    exposureMaxThreshold: 100,
    leadfallGravityMultiplier: 2.0,
    leadfallZenithFlightSpeedPenalty: 0.70,
    skyreachZenithKnockbackPenalty: 1.45,
    carriedWeightFlyerGravity: -35,
    carriedWeightCrushDamageMultiplier: 1.55
  }
};

class TuningManager {
  private current: KairosTuning = structuredClone(DEFAULT_TUNING);
  private listeners: Array<(tuning: KairosTuning) => void> = [];

  get(): KairosTuning {
    return this.current;
  }

  update(mutator: (t: KairosTuning) => void): void {
    mutator(this.current);
    this.notify();
  }

  setRunDuration(seconds: number): void {
    const scale = seconds / 1800;
    this.current.clock.defaultRunDurationSeconds = seconds;
    this.current.clock.threshold1Seconds = 600 * scale;
    this.current.clock.threshold2Seconds = 1200 * scale;
    this.current.clock.threshold3Seconds = 1680 * scale;
    this.current.clock.overflowStartSeconds = 1680 * scale;
    this.notify();
  }

  reset(): void {
    this.current = structuredClone(DEFAULT_TUNING);
    this.notify();
  }

  subscribe(callback: (tuning: KairosTuning) => void): () => void {
    this.listeners.push(callback);
    callback(this.current);
    return () => {
      this.listeners = this.listeners.filter((l) => l !== callback);
    };
  }

  private notify(): void {
    for (const listener of this.listeners) {
      listener(this.current);
    }
  }
}

export const TUNING = new TuningManager();

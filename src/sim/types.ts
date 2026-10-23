export type DimensionId = "threshold" | "leadfall" | "skyreach" | "corridor" | "threat-node";

export type DimensionRule = "none" | "heavy-gravity" | "open-sky";

export type AdaptationId = "weight" | "lift";

export type TechniqueId = "beam" | "burst-field" | "warp-beam";

export interface Vec2 {
  x: number;
  y: number;
}

export interface Vec3 {
  x: number;
  y: number;
  z: number;
}

export interface AABB {
  minX: number;
  minY: number;
  maxX: number;
  maxY: number;
}

export interface TerrainPlatform {
  id: string;
  aabb: AABB;
  type: "solid" | "one-way" | "breakable";
  health?: number;
  maxHealth?: number;
  dented?: boolean;
}

export interface PlayerInput {
  moveX: number;
  moveY: number;
  jump: boolean;
  burst: boolean;
  instantTransmission: boolean;
  lightAttack: boolean;
  heavyAttack: boolean;
  guard: boolean;
  kiVolley: boolean;
  chargeBeam: boolean;
  releaseBeam: boolean;
  burstField: boolean;
}

export interface CombatHit {
  attackerId: string;
  targetId: string;
  damage: number;
  timeCostSeconds: number;
  knockback: Vec2;
  hitstopFrames: number;
  isLauncher: boolean;
  launchDirection?: Vec2;
  isPerfectGuard?: boolean;
  verb: "light" | "launcher" | "chase" | "volley" | "beam" | "burst-field" | "counter";
  position: Vec2;
}

export type EnemyType =
  | "swarm-fodder"
  | "ranged-blaster"
  | "armored-brute"
  | "fast-flyer"
  | "heavy-flyer"
  | "the-threat";

export interface EnemyState {
  id: string;
  type: EnemyType;
  position: Vec2;
  velocity: Vec2;
  facing: number; // 1 or -1
  health: number;
  maxHealth: number;
  poise: number;
  maxPoise: number;
  grounded: boolean;
  staggerTimer: number;
  launchedTimer: number;
  launchVelocity: Vec2;
  attackCooldown: number;
  stateTimer: number;
  aiState: "idle" | "patrol" | "chase" | "windup" | "attack" | "recovery" | "stagger" | "launched";
  phase?: number;
  radius: number;
  height: number;
  // Mark / carried rule reaction
  isGroundedByWeight?: boolean;
}

export interface Projectile {
  id: string;
  ownerId: string;
  type: "ki-bolt" | "enemy-bolt" | "beam-segment" | "burst-wave";
  position: Vec2;
  velocity: Vec2;
  radius: number;
  damage: number;
  timeCostSeconds: number;
  lifetime: number;
  piercing?: boolean;
  dragsDownward?: boolean;
}

export interface Afterimage {
  id: string;
  position: Vec2;
  facing: number;
  alpha: number;
  lifetime: number;
  color: string;
}

export interface DimensionMark {
  dimensionId: DimensionId;
  adaptationId: AdaptationId;
  description: string;
  appliedAtClock: number;
}

export interface ThresholdOption {
  id: string;
  title: string;
  description: string;
  category: "technique" | "passive" | "ki";
  apply: () => void;
}

export interface LegacyRunSummary {
  seed: number;
  totalRunTimeSeconds: number;
  elapsedSeconds: number;
  finalClockSeconds: number;
  peakPowerMultiplier: number;
  threatDefeated: boolean;
  threatDefeatedAtSeconds?: number;
  fadeTriggered: boolean;
  dimensionsMarked: DimensionMark[];
  insightsLearned: string[];
  maxCombo: number;
  enemiesDefeated: number;
  fadeLineSpoken: string;
}

/**
 * Vendored @slu/web-shell contracts used by KAIROS.
 *
 * Source: mikeylambo/web-game-shell-v1.02 @ 6f08d17c2f1012b19e6e26c87c640762354eb0ec
 *   - src/frames/types.ts   (FrameId, FlowPhase, FlowStep, GenreFrame, flow)
 *   - src/game/Modes.ts     (ModeDefinition)
 *   - src/game/Difficulty.ts (DifficultyProfile)
 *   - src/input/InputTypes.ts (InputAction, InputBinding)
 *
 * Vendored so KAIROS builds without access to the private shell repo
 * (Vercel/CI). Keep in sync with the shell when merging ported modules back.
 */

export type FrameId =
  | "arcade"
  | "character-action"
  | "arena-combat"
  | "vehicle"
  | "fps"
  | "puzzle"
  | "rpg"
  | "strategy"
  | "platformer"
  | "party-multiplayer"
  | "companion-adventure";

export type FlowPhase = "boot" | "front" | "setup" | "play" | "post" | "utility";

export interface FlowStep {
  id: string;
  phase: FlowPhase;
  order?: number;
}

export interface ModeDefinition {
  id: string;
  label: string;
  description?: string;
  rules?: Record<string, unknown>;
  winCondition?: string;
  lossCondition?: string;
  timeLimitSeconds?: number;
  playerCount?: { min: number; max: number };
  leaderboardKey?: string;
  rewardsTable?: string;
}

export interface DifficultyProfile {
  id: string;
  label: string;
  description?: string;
  multipliers?: {
    playerDamage?: number;
    enemyDamage?: number;
    enemyHealth?: number;
    enemySpeed?: number;
    score?: number;
    resources?: number;
  };
  rules?: Record<string, number | boolean | string>;
  enemyCompositionTag?: string;
  prerequisiteUnlock?: string;
}

export interface GenreFrame {
  id: FrameId;
  label: string;
  menuFlow: FlowStep[];
  modes: ModeDefinition[];
  difficulties?: DifficultyProfile[];
  statKeys: string[];
  challengeCategories: string[];
  recommendedModules: string[];
  settings?: Record<string, unknown>;
}

export const flow = (phase: FlowPhase, ...ids: string[]): FlowStep[] =>
  ids.map((id, order) => ({ id, phase, order }));

export type InputAction = string;

export interface InputBinding {
  action: InputAction;
  keyboard?: string[];
  mouseButtons?: number[];
  gamepadButtons?: number[];
  gamepadAxes?: Array<{ axis: number; direction: -1 | 1; threshold?: number }>;
}

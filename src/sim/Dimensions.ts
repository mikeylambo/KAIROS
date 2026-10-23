import type {
  AdaptationId,
  DimensionId,
  DimensionMark,
  DimensionRule,
  TerrainPlatform,
  Vec2
} from "./types.js";
import { TUNING } from "./Tuning.js";

export interface DimensionDefinition {
  id: DimensionId;
  name: string;
  band: number;
  rule: DimensionRule;
  theme: "dusk-city" | "rust-iron" | "pale-sky" | "void-corridor";
  adaptationId?: AdaptationId;
  description: string;
  ruleDescription: string;
}

export interface DimensionInstance {
  definition: DimensionDefinition;
  platforms: TerrainPlatform[];
  spawnPoints: Vec2[];
  playerSpawn: Vec2;
  exposureMeter: number;
  exposureMax: number;
  adapted: boolean;
  marked: boolean;
  markDescription?: string;
}

export const DIMENSIONS: Record<DimensionId, DimensionDefinition> = {
  threshold: {
    id: "threshold",
    name: "The Threshold",
    band: 1,
    rule: "none",
    theme: "dusk-city",
    description: "A skyline city mid-crisis; every run begins here.",
    ruleDescription: "Standard physics. Teaches launch-and-chase fundamentals."
  },
  leadfall: {
    id: "leadfall",
    name: "Leadfall",
    band: 2,
    rule: "heavy-gravity",
    theme: "rust-iron",
    adaptationId: "weight",
    description: "A collapsed planet-core foundry under iron rain.",
    ruleDescription: "Heavy gravity: everything falls hard; ground slams shake the foundry."
  },
  skyreach: {
    id: "skyreach",
    name: "Skyreach",
    band: 2,
    rule: "open-sky",
    theme: "pale-sky",
    adaptationId: "lift",
    description: "Endless open sky with no ground; all enemies fly.",
    ruleDescription: "Open sky: pure vertical combat across floating platforms."
  },
  corridor: {
    id: "corridor",
    name: "In-Between Corridor",
    band: 1,
    rule: "none",
    theme: "void-corridor",
    description: "The hyperspace rift connecting dimensions.",
    ruleDescription: "Free flight corridor with light encounters."
  },
  "threat-node": {
    id: "threat-node",
    name: "Threat Rupture",
    band: 3,
    rule: "none",
    theme: "void-corridor",
    description: "The source node of the Multiverse Threat.",
    ruleDescription: "Direct combat against The Threat."
  }
};

export class DimensionManager {
  public currentDimensionId: DimensionId = "threshold";
  public instances: Map<DimensionId, DimensionInstance> = new Map();
  public marks: DimensionMark[] = [];

  public onAdaptationUnlocked?: (adaptation: AdaptationId, name: string) => void;
  public onDimensionMarked?: (mark: DimensionMark) => void;

  constructor(seed: number = 42) {
    this.buildDimensions(seed);
  }

  buildDimensions(seed: number): void {
    this.instances.clear();
    this.marks = [];

    for (const [id, def] of Object.entries(DIMENSIONS) as [DimensionId, DimensionDefinition][]) {
      const { platforms, spawnPoints, playerSpawn } = this.generateHandcraftedChunks(id, seed);
      this.instances.set(id, {
        definition: def,
        platforms,
        spawnPoints,
        playerSpawn,
        exposureMeter: 0,
        exposureMax: TUNING.get().dimensions.exposureMaxThreshold,
        adapted: false,
        marked: false
      });
    }
  }

  getCurrent(): DimensionInstance {
    return this.instances.get(this.currentDimensionId)!;
  }

  setCurrent(id: DimensionId): DimensionInstance {
    this.currentDimensionId = id;
    return this.getCurrent();
  }

  addExposure(amount: number): { adapted: boolean; adaptationId?: AdaptationId } {
    const current = this.getCurrent();
    if (current.adapted || !current.definition.adaptationId) {
      return { adapted: false };
    }

    current.exposureMeter += amount;
    if (current.exposureMeter >= current.exposureMax) {
      current.exposureMeter = current.exposureMax;
      current.adapted = true;
      const adaptation = current.definition.adaptationId;
      this.onAdaptationUnlocked?.(adaptation, current.definition.name);
      return { adapted: true, adaptationId: adaptation };
    }

    return { adapted: false };
  }

  checkMarkOnEntry(hasWeightAdaptation: boolean, clockSeconds: number): boolean {
    const current = this.getCurrent();
    // Entering Skyreach with Weight: permanently marks Skyreach!
    if (current.definition.id === "skyreach" && hasWeightAdaptation && !current.marked) {
      current.marked = true;
      current.markDescription = "Weight Grounding: Flyers subject to gravity; fly lower and land on ledges.";
      const mark: DimensionMark = {
        dimensionId: "skyreach",
        adaptationId: "weight",
        description: current.markDescription,
        appliedAtClock: clockSeconds
      };
      this.marks.push(mark);
      this.onDimensionMarked?.(mark);
      return true;
    }
    return false;
  }

  /**
   * Builds the 2 handcrafted chunks per dimension as specified in the brief.
   */
  private generateHandcraftedChunks(
    id: DimensionId,
    seed: number
  ): { platforms: TerrainPlatform[]; spawnPoints: Vec2[]; playerSpawn: Vec2 } {
    const platforms: TerrainPlatform[] = [];
    const spawnPoints: Vec2[] = [];
    let playerSpawn: Vec2 = { x: -25, y: 1.5 };

    switch (id) {
      case "threshold": {
        // Chunk A: Dusk Skyline Rooftops & Bridges
        platforms.push(
          { id: "th-ground", aabb: { minX: -50, maxX: 50, minY: -3, maxY: 0 }, type: "solid" },
          { id: "th-wall-l", aabb: { minX: -52, maxX: -50, minY: 0, maxY: 30 }, type: "solid" },
          { id: "th-wall-r", aabb: { minX: 50, maxX: 52, minY: 0, maxY: 30 }, type: "solid" },
          // Rooftop ledges
          { id: "th-roof-1", aabb: { minX: -20, maxX: -5, minY: 6, maxY: 7 }, type: "one-way" },
          { id: "th-roof-2", aabb: { minX: 5, maxX: 22, minY: 8, maxY: 9 }, type: "one-way" },
          { id: "th-bridge", aabb: { minX: -8, maxX: 8, minY: 14, maxY: 15 }, type: "one-way" },
          // Breakable billboard / obstacle
          { id: "th-break-1", aabb: { minX: -2, maxX: 2, minY: 0, maxY: 5 }, type: "breakable", health: 100, maxHealth: 100 }
        );
        spawnPoints.push(
          { x: -10, y: 1.5 },
          { x: 12, y: 1.5 },
          { x: -12, y: 8.5 },
          { x: 14, y: 10.5 },
          { x: 0, y: 16.5 }
        );
        playerSpawn = { x: -35, y: 1.5 };
        break;
      }

      case "leadfall": {
        // Chunk B: Collapsed Planet Foundry (Heavy industrial platforms and massive iron anvils)
        platforms.push(
          { id: "lf-ground", aabb: { minX: -60, maxX: 60, minY: -4, maxY: 0 }, type: "solid" },
          { id: "lf-wall-l", aabb: { minX: -62, maxX: -60, minY: 0, maxY: 35 }, type: "solid" },
          { id: "lf-wall-r", aabb: { minX: 60, maxX: 62, minY: 0, maxY: 35 }, type: "solid" },
          // Heavy stepped iron tiers
          { id: "lf-anvil-1", aabb: { minX: -32, maxX: -16, minY: 5, maxY: 7 }, type: "solid" },
          { id: "lf-anvil-2", aabb: { minX: 16, maxX: 32, minY: 5, maxY: 7 }, type: "solid" },
          { id: "lf-foundry-beam", aabb: { minX: -12, maxX: 12, minY: 12, maxY: 13.5 }, type: "solid" },
          { id: "lf-upper-catwalk", aabb: { minX: -25, maxX: 25, minY: 20, maxY: 21 }, type: "one-way" },
          // Destructible smelting pillars
          { id: "lf-pillar-1", aabb: { minX: -20, maxX: -17, minY: 7, maxY: 15 }, type: "breakable", health: 150, maxHealth: 150 },
          { id: "lf-pillar-2", aabb: { minX: 17, maxX: 20, minY: 7, maxY: 15 }, type: "breakable", health: 150, maxHealth: 150 }
        );
        spawnPoints.push(
          { x: -24, y: 8.5 },
          { x: 24, y: 8.5 },
          { x: 0, y: 15.0 },
          { x: -10, y: 1.5 },
          { x: 10, y: 1.5 }
        );
        playerSpawn = { x: -45, y: 1.5 };
        break;
      }

      case "skyreach": {
        // Chunk C: Endless Open Sky (NO ground floor! Floating sky monoliths)
        platforms.push(
          { id: "sk-wall-l", aabb: { minX: -65, maxX: -63, minY: -20, maxY: 40 }, type: "solid" },
          { id: "sk-wall-r", aabb: { minX: 63, maxX: 65, minY: -20, maxY: 40 }, type: "solid" },
          // Floating monoliths
          { id: "sk-island-1", aabb: { minX: -35, maxX: -20, minY: 0, maxY: 2 }, type: "one-way" },
          { id: "sk-island-2", aabb: { minX: -10, maxX: 10, minY: 8, maxY: 10 }, type: "one-way" },
          { id: "sk-island-3", aabb: { minX: 20, maxX: 35, minY: 2, maxY: 4 }, type: "one-way" },
          { id: "sk-high-perch", aabb: { minX: -18, maxX: 18, minY: 18, maxY: 20 }, type: "one-way" },
          { id: "sk-zenith-ledge", aabb: { minX: -50, maxX: -40, minY: -2, maxY: 0 }, type: "solid" }
        );
        spawnPoints.push(
          { x: -28, y: 12.0 },
          { x: 0, y: 14.0 },
          { x: 28, y: 12.0 },
          { x: 0, y: 24.0 },
          { x: -15, y: 4.0 },
          { x: 15, y: 4.0 }
        );
        playerSpawn = { x: -45, y: 2.0 };
        break;
      }

      case "corridor": {
        // In-between travel corridor (wide straight run for flight)
        platforms.push(
          { id: "cor-floor", aabb: { minX: -100, maxX: 100, minY: -5, maxY: 0 }, type: "solid" },
          { id: "cor-ceil", aabb: { minX: -100, maxX: 100, minY: 25, maxY: 30 }, type: "solid" },
          { id: "cor-wall-l", aabb: { minX: -102, maxX: -100, minY: 0, maxY: 25 }, type: "solid" },
          { id: "cor-wall-r", aabb: { minX: 100, maxX: 102, minY: 0, maxY: 25 }, type: "solid" }
        );
        spawnPoints.push(
          { x: -30, y: 5 },
          { x: 0, y: 8 },
          { x: 30, y: 6 }
        );
        playerSpawn = { x: -80, y: 2.0 };
        break;
      }

      case "threat-node": {
        // Threat Boss Arena
        platforms.push(
          { id: "th-arena-floor", aabb: { minX: -45, maxX: 45, minY: -4, maxY: 0 }, type: "solid" },
          { id: "th-arena-wall-l", aabb: { minX: -47, maxX: -45, minY: 0, maxY: 30 }, type: "solid" },
          { id: "th-arena-wall-r", aabb: { minX: 45, maxX: 47, minY: 0, maxY: 30 }, type: "solid" },
          { id: "th-arena-p1", aabb: { minX: -22, maxX: -8, minY: 8, maxY: 9.5 }, type: "one-way" },
          { id: "th-arena-p2", aabb: { minX: 8, maxX: 22, minY: 8, maxY: 9.5 }, type: "one-way" }
        );
        spawnPoints.push({ x: 18, y: 2.0 });
        playerSpawn = { x: -25, y: 2.0 };
        break;
      }
    }

    return { platforms, spawnPoints, playerSpawn };
  }
}

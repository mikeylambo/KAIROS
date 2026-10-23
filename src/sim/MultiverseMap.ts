import type { DimensionId, DimensionMark } from "./types.js";
import { DIMENSIONS } from "./Dimensions.js";

export interface MapNode {
  id: DimensionId;
  name: string;
  band: number;
  ruleName: string;
  x: number; // Node position in map UI (normalized coordinates -1 to 1)
  y: number;
  corrupted: boolean;
  marked: boolean;
  markDescription?: string;
  unlocked: boolean;
  connections: DimensionId[];
}

export class MultiverseMap {
  public nodes: Map<DimensionId, MapNode> = new Map();
  public threatNodeUnlocked: boolean = false;
  public corruptionLevel: number = 0; // 0 to 1

  constructor() {
    this.initMap();
  }

  initMap(): void {
    this.nodes.clear();
    this.nodes.set("threshold", {
      id: "threshold",
      name: "The Threshold",
      band: 1,
      ruleName: "Standard",
      x: -0.5,
      y: 0.1,
      corrupted: false,
      marked: false,
      unlocked: true,
      connections: ["leadfall", "skyreach"]
    });

    this.nodes.set("leadfall", {
      id: "leadfall",
      name: "Leadfall",
      band: 2,
      ruleName: "Heavy Gravity",
      x: 0.2,
      y: -0.4,
      corrupted: false,
      marked: false,
      unlocked: true,
      connections: ["threshold", "skyreach"]
    });

    this.nodes.set("skyreach", {
      id: "skyreach",
      name: "Skyreach",
      band: 2,
      ruleName: "Open Sky",
      x: 0.3,
      y: 0.45,
      corrupted: false,
      marked: false,
      unlocked: true,
      connections: ["threshold", "leadfall"]
    });

    this.nodes.set("threat-node", {
      id: "threat-node",
      name: "The Threat",
      band: 3,
      ruleName: "Void Apex",
      x: 0.8,
      y: 0.0,
      corrupted: true,
      marked: false,
      unlocked: false,
      connections: ["leadfall", "skyreach"]
    });
  }

  updateCorruptionAndThreat(elapsedSeconds: number, totalDuration: number, marks: DimensionMark[]): void {
    const scale = totalDuration / 1800;
    const corruptionStart = 600 * scale; // 10:00
    const earlyHuntStart = 1200 * scale; // 20:00

    if (elapsedSeconds >= corruptionStart) {
      this.corruptionLevel = Math.min(1.0, (elapsedSeconds - corruptionStart) / (totalDuration - corruptionStart));
      // Corruption spreads across nodes
      if (this.corruptionLevel > 0.3) {
        this.nodes.get("leadfall")!.corrupted = true;
      }
      if (this.corruptionLevel > 0.6) {
        this.nodes.get("skyreach")!.corrupted = true;
      }
      if (this.corruptionLevel > 0.85) {
        this.nodes.get("threshold")!.corrupted = true;
      }
    }

    if (elapsedSeconds >= earlyHuntStart) {
      this.threatNodeUnlocked = true;
      this.nodes.get("threat-node")!.unlocked = true;
    }

    // Sync marks
    for (const mark of marks) {
      const node = this.nodes.get(mark.dimensionId);
      if (node) {
        node.marked = true;
        node.markDescription = mark.description;
      }
    }
  }
}

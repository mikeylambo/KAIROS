import type { AABB, TerrainPlatform, Vec2 } from "./types.js";

export class CollisionWorld {
  public platforms: TerrainPlatform[] = [];
  public dentedPlatforms = new Set<string>();

  setPlatforms(platforms: TerrainPlatform[]): void {
    this.platforms = platforms;
    this.dentedPlatforms.clear();
  }

  addPlatform(platform: TerrainPlatform): void {
    this.platforms.push(platform);
  }

  aabbOverlap(a: AABB, b: AABB): boolean {
    return (
      a.minX < b.maxX &&
      a.maxX > b.minX &&
      a.minY < b.maxY &&
      a.maxY > b.minY
    );
  }

  pointInAABB(p: Vec2, box: AABB): boolean {
    return p.x >= box.minX && p.x <= box.maxX && p.y >= box.minY && p.y <= box.maxY;
  }

  /**
   * Sweeps a bounding box from current position by (dx, dy).
   * Resolves collisions with solid and one-way platforms.
   */
  moveAndSlide(
    boxHalfWidth: number,
    boxHalfHeight: number,
    pos: Vec2,
    vel: Vec2,
    dt: number
  ): { pos: Vec2; vel: Vec2; grounded: boolean; hitCeiling: boolean; hitWall: boolean } {
    let grounded = false;
    let hitCeiling = false;
    let hitWall = false;

    let targetX = pos.x + vel.x * dt;
    let targetY = pos.y + vel.y * dt;

    // Horizontal movement and resolution
    const hBox: AABB = {
      minX: targetX - boxHalfWidth,
      maxX: targetX + boxHalfWidth,
      minY: pos.y - boxHalfHeight + 0.05,
      maxY: pos.y + boxHalfHeight - 0.05
    };

    for (const plat of this.platforms) {
      if (plat.type === "one-way") continue;
      if (plat.health !== undefined && plat.health <= 0) continue;

      if (this.aabbOverlap(hBox, plat.aabb)) {
        hitWall = true;
        if (vel.x > 0) {
          targetX = plat.aabb.minX - boxHalfWidth;
        } else if (vel.x < 0) {
          targetX = plat.aabb.maxX + boxHalfWidth;
        }
        vel.x = 0;
        break;
      }
    }

    // Vertical movement and resolution
    const vBox: AABB = {
      minX: targetX - boxHalfWidth + 0.05,
      maxX: targetX + boxHalfWidth - 0.05,
      minY: targetY - boxHalfHeight,
      maxY: targetY + boxHalfHeight
    };

    for (const plat of this.platforms) {
      if (plat.health !== undefined && plat.health <= 0) continue;

      if (plat.type === "one-way") {
        // One-way: pass through from below, land from above
        const prevBottom = pos.y - boxHalfHeight;
        const newBottom = targetY - boxHalfHeight;
        if (vel.y <= 0 && prevBottom >= plat.aabb.maxY - 0.15 && newBottom <= plat.aabb.maxY) {
          if (targetX + boxHalfWidth > plat.aabb.minX && targetX - boxHalfWidth < plat.aabb.maxX) {
            targetY = plat.aabb.maxY + boxHalfHeight;
            vel.y = 0;
            grounded = true;
          }
        }
        continue;
      }

      if (this.aabbOverlap(vBox, plat.aabb)) {
        if (vel.y <= 0) {
          // Landing on floor
          targetY = plat.aabb.maxY + boxHalfHeight;
          vel.y = 0;
          grounded = true;
        } else {
          // Hitting ceiling
          targetY = plat.aabb.minY - boxHalfHeight;
          vel.y = 0;
          hitCeiling = true;
        }
      }
    }

    return {
      pos: { x: targetX, y: targetY },
      vel: { x: vel.x, y: vel.y },
      grounded,
      hitCeiling,
      hitWall
    };
  }

  damageTerrainAt(point: Vec2, radius: number, damage: number): boolean {
    let affected = false;
    for (const plat of this.platforms) {
      if (
        point.x >= plat.aabb.minX - radius &&
        point.x <= plat.aabb.maxX + radius &&
        point.y >= plat.aabb.minY - radius &&
        point.y <= plat.aabb.maxY + radius
      ) {
        plat.dented = true;
        this.dentedPlatforms.add(plat.id);
        if (plat.health !== undefined) {
          plat.health -= damage;
        }
        affected = true;
      }
    }
    return affected;
  }
}

import type { CollisionWorld } from "./Collision.js";
import { TUNING } from "./Tuning.js";
import type { CombatHit, EnemyState, EnemyType, Projectile, Vec2 } from "./types.js";

export class EnemyManager {
  public enemies: EnemyState[] = [];
  public nextId = 1;

  public onEnemyKilled?: (enemy: EnemyState) => void;
  public onEnemyProjectileSpawned?: (proj: Projectile) => void;

  spawn(type: EnemyType, pos: Vec2): EnemyState {
    let health = 100;
    let poise = 50;
    let radius = 0.7;
    let height = 1.6;

    switch (type) {
      case "swarm-fodder":
        health = 60;
        poise = 20;
        radius = 0.55;
        height = 1.3;
        break;
      case "ranged-blaster":
        health = 80;
        poise = 30;
        radius = 0.6;
        height = 1.5;
        break;
      case "armored-brute":
        health = 240;
        poise = 140;
        radius = 0.95;
        height = 2.2;
        break;
      case "fast-flyer":
        health = 90;
        poise = 35;
        radius = 0.6;
        height = 1.2;
        break;
      case "heavy-flyer":
        health = 260;
        poise = 110;
        radius = 1.1;
        height = 1.8;
        break;
      case "the-threat":
        health = 800;
        poise = 300;
        radius = 1.2;
        height = 2.4;
        break;
    }

    const enemy: EnemyState = {
      id: `enemy-${this.nextId++}`,
      type,
      position: { ...pos },
      velocity: { x: 0, y: 0 },
      facing: -1,
      health,
      maxHealth: health,
      poise,
      maxPoise: poise,
      grounded: false,
      staggerTimer: 0,
      launchedTimer: 0,
      launchVelocity: { x: 0, y: 0 },
      attackCooldown: 1.0 + Math.random() * 0.8,
      stateTimer: 0,
      aiState: "idle",
      phase: 1,
      radius,
      height
    };

    this.enemies.push(enemy);
    return enemy;
  }

  clear(): void {
    this.enemies = [];
  }

  update(
    dt: number,
    zenithPos: Vec2,
    hasWeightAdaptation: boolean,
    currentDimension: string,
    skyreachMarked: boolean,
    world: CollisionWorld
  ): { enemyHits: CombatHit[]; enemyProjectiles: Projectile[] } {
    const enemyHits: CombatHit[] = [];
    const enemyProjectiles: Projectile[] = [];
    const tuning = TUNING.get();

    for (let i = this.enemies.length - 1; i >= 0; i--) {
      const enemy = this.enemies[i];
      if (enemy.health <= 0) {
        this.enemies.splice(i, 1);
        this.onEnemyKilled?.(enemy);
        continue;
      }

      // Check Carried Weight vs Skyreach Flyers!
      // Signature interaction: flyers near Zenith (or in marked Skyreach) fall out of the sky!
      const isFlyer = enemy.type === "fast-flyer" || enemy.type === "heavy-flyer";
      if (isFlyer) {
        const dx = enemy.position.x - zenithPos.x;
        const dy = enemy.position.y - zenithPos.y;
        const distToZenith = Math.hypot(dx, dy);

        if (hasWeightAdaptation && (distToZenith < 28 || skyreachMarked)) {
          enemy.isGroundedByWeight = true;
          // Heavy gravity pulls flyer downward!
          enemy.velocity.y += tuning.dimensions.carriedWeightFlyerGravity * dt;
        } else {
          enemy.isGroundedByWeight = false;
        }
      }

      // Handle Stagger / Launched States
      if (enemy.launchedTimer > 0) {
        enemy.launchedTimer -= dt;
        enemy.velocity.x = enemy.launchVelocity.x;
        enemy.velocity.y = enemy.launchVelocity.y;
        // Gravity on launched enemy
        enemy.launchVelocity.y += tuning.movement.gravity * 0.6 * dt;

        this.applyKinematics(enemy, world, dt);
        continue;
      }

      if (enemy.staggerTimer > 0) {
        enemy.staggerTimer -= dt;
        enemy.velocity.x *= 0.85;
        this.applyKinematics(enemy, world, dt);
        continue;
      }

      // AI Decision Cycle
      const dx = zenithPos.x - enemy.position.x;
      const dy = zenithPos.y - enemy.position.y;
      const dist = Math.hypot(dx, dy);
      enemy.facing = dx >= 0 ? 1 : -1;

      if (enemy.attackCooldown > 0) {
        enemy.attackCooldown -= dt;
      }

      switch (enemy.type) {
        case "swarm-fodder":
          this.updateSwarmFodder(enemy, dx, dy, dist, dt, world, enemyHits);
          break;
        case "ranged-blaster":
          this.updateRangedBlaster(enemy, dx, dy, dist, dt, world, enemyProjectiles);
          break;
        case "armored-brute":
          this.updateArmoredBrute(enemy, dx, dy, dist, dt, world, enemyHits);
          break;
        case "fast-flyer":
          this.updateFastFlyer(enemy, dx, dy, dist, dt, world, enemyHits);
          break;
        case "heavy-flyer":
          this.updateHeavyFlyer(enemy, dx, dy, dist, dt, world, enemyProjectiles);
          break;
        case "the-threat":
          this.updateTheThreat(enemy, dx, dy, dist, dt, world, enemyHits, enemyProjectiles);
          break;
      }

      this.applyKinematics(enemy, world, dt);
    }

    return { enemyHits, enemyProjectiles };
  }

  private updateSwarmFodder(
    enemy: EnemyState,
    dx: number,
    dy: number,
    dist: number,
    dt: number,
    world: CollisionWorld,
    hits: CombatHit[]
  ): void {
    if (dist < 1.6 && enemy.attackCooldown <= 0) {
      // Swarm swipe
      enemy.attackCooldown = 1.4;
      hits.push({
        attackerId: enemy.id,
        targetId: "zenith",
        damage: 15,
        timeCostSeconds: TUNING.get().clock.lightHitCostSeconds,
        knockback: { x: enemy.facing * 8, y: 3 },
        hitstopFrames: 4,
        isLauncher: false,
        verb: "light",
        position: { ...enemy.position }
      });
    } else {
      // Advance toward Zenith
      const speed = 7.5;
      enemy.velocity.x = enemy.facing * speed;
      if (!enemy.grounded) {
        enemy.velocity.y += TUNING.get().movement.gravity * dt;
      }
    }
  }

  private updateRangedBlaster(
    enemy: EnemyState,
    dx: number,
    dy: number,
    dist: number,
    dt: number,
    world: CollisionWorld,
    projectiles: Projectile[]
  ): void {
    if (dist < 6.0) {
      // Back away from Zenith
      enemy.velocity.x = -enemy.facing * 5.0;
    } else if (dist > 18.0) {
      // Close distance
      enemy.velocity.x = enemy.facing * 5.0;
    } else {
      enemy.velocity.x *= 0.8;
      if (enemy.attackCooldown <= 0) {
        enemy.attackCooldown = 2.0;
        const speed = 26;
        const dirLen = Math.hypot(dx, dy) || 1;
        const bolt: Projectile = {
          id: `enemy-bolt-${Date.now()}-${Math.random()}`,
          ownerId: enemy.id,
          type: "enemy-bolt",
          position: { x: enemy.position.x + enemy.facing * 0.7, y: enemy.position.y + 0.3 },
          velocity: { x: (dx / dirLen) * speed, y: (dy / dirLen) * speed },
          radius: 0.45,
          damage: 20,
          timeCostSeconds: TUNING.get().clock.lightHitCostSeconds,
          lifetime: 2.0
        };
        projectiles.push(bolt);
        this.onEnemyProjectileSpawned?.(bolt);
      }
    }

    if (!enemy.grounded) {
      enemy.velocity.y += TUNING.get().movement.gravity * dt;
    }
  }

  private updateArmoredBrute(
    enemy: EnemyState,
    dx: number,
    dy: number,
    dist: number,
    dt: number,
    world: CollisionWorld,
    hits: CombatHit[]
  ): void {
    if (dist < 2.5 && enemy.attackCooldown <= 0) {
      // Heavy ground slam!
      enemy.attackCooldown = 2.5;
      hits.push({
        attackerId: enemy.id,
        targetId: "zenith",
        damage: 40,
        timeCostSeconds: TUNING.get().clock.heavyHitCostSeconds,
        knockback: { x: enemy.facing * 16, y: 7 },
        hitstopFrames: 10,
        isLauncher: true,
        verb: "launcher",
        position: { ...enemy.position }
      });
      // Ground slam damages terrain locally!
      world.damageTerrainAt(enemy.position, 4.0, 30);
    } else {
      // Heavy stomping pursuit
      enemy.velocity.x = enemy.facing * 4.5;
      if (!enemy.grounded) {
        // Heavy gravity on brute
        enemy.velocity.y += TUNING.get().movement.gravity * 1.5 * dt;
      }
    }
  }

  private updateFastFlyer(
    enemy: EnemyState,
    dx: number,
    dy: number,
    dist: number,
    dt: number,
    world: CollisionWorld,
    hits: CombatHit[]
  ): void {
    if (enemy.isGroundedByWeight) {
      // Dragged down to earth! Stumbles along ground
      enemy.velocity.x = enemy.facing * 3.0;
      if (!enemy.grounded) {
        enemy.velocity.y += TUNING.get().dimensions.carriedWeightFlyerGravity * dt;
      }
      return;
    }

    // Aerial swoop
    if (dist < 2.0 && enemy.attackCooldown <= 0) {
      enemy.attackCooldown = 1.8;
      hits.push({
        attackerId: enemy.id,
        targetId: "zenith",
        damage: 22,
        timeCostSeconds: TUNING.get().clock.lightHitCostSeconds,
        knockback: { x: enemy.facing * 10, y: 2 },
        hitstopFrames: 6,
        isLauncher: false,
        verb: "light",
        position: { ...enemy.position }
      });
    } else {
      const wishY = dy > 0 ? 6.0 : -6.0;
      enemy.velocity.x += (enemy.facing * 12.0 - enemy.velocity.x) * 4.0 * dt;
      enemy.velocity.y += (wishY - enemy.velocity.y) * 3.0 * dt;
    }
  }

  private updateHeavyFlyer(
    enemy: EnemyState,
    dx: number,
    dy: number,
    dist: number,
    dt: number,
    world: CollisionWorld,
    projectiles: Projectile[]
  ): void {
    if (enemy.isGroundedByWeight) {
      enemy.velocity.x = enemy.facing * 2.0;
      if (!enemy.grounded) {
        enemy.velocity.y += TUNING.get().dimensions.carriedWeightFlyerGravity * dt;
      }
      return;
    }

    // Hover above Zenith and drop heavy barrages
    const targetY = 7.0;
    const diffY = targetY - enemy.position.y;
    enemy.velocity.y += diffY * 2.0 * dt;
    enemy.velocity.x = (dx * 0.4 - enemy.velocity.x) * 2.0 * dt;

    if (enemy.attackCooldown <= 0) {
      enemy.attackCooldown = 2.8;
      for (let k = -1; k <= 1; k++) {
        const bolt: Projectile = {
          id: `heavy-bolt-${Date.now()}-${k}`,
          ownerId: enemy.id,
          type: "enemy-bolt",
          position: { x: enemy.position.x + k * 0.8, y: enemy.position.y - 0.5 },
          velocity: { x: k * 6.0, y: -20 },
          radius: 0.6,
          damage: 30,
          timeCostSeconds: TUNING.get().clock.heavyHitCostSeconds,
          lifetime: 2.5
        };
        projectiles.push(bolt);
        this.onEnemyProjectileSpawned?.(bolt);
      }
    }
  }

  private updateTheThreat(
    boss: EnemyState,
    dx: number,
    dy: number,
    dist: number,
    dt: number,
    world: CollisionWorld,
    hits: CombatHit[],
    projectiles: Projectile[]
  ): void {
    // Dynamic boss phase based on health
    const healthRatio = boss.health / boss.maxHealth;
    boss.phase = healthRatio < 0.35 ? 3 : healthRatio < 0.70 ? 2 : 1;

    if (dist < 3.2 && boss.attackCooldown <= 0) {
      // Phased boss cleave / dimensional blade
      boss.attackCooldown = boss.phase === 3 ? 1.2 : 2.0;
      const isHeavy = boss.phase >= 2;
      hits.push({
        attackerId: boss.id,
        targetId: "zenith",
        damage: isHeavy ? 60 : 35,
        timeCostSeconds: isHeavy ? TUNING.get().clock.heavyHitCostSeconds : TUNING.get().clock.lightHitCostSeconds,
        knockback: { x: boss.facing * (isHeavy ? 22 : 14), y: 6 },
        hitstopFrames: isHeavy ? 12 : 8,
        isLauncher: isHeavy,
        verb: isHeavy ? "launcher" : "light",
        position: { ...boss.position }
      });
      world.damageTerrainAt(boss.position, 5.0, 50);
    } else {
      // High-mobility boss dash / flight
      const speed = boss.phase === 3 ? 18.0 : 12.0;
      boss.velocity.x = boss.facing * speed;
      boss.velocity.y = (dy * 0.5 - boss.velocity.y) * 4.0 * dt;

      // In phase 2 & 3, fires dimensional waves
      if (boss.attackCooldown <= 0.6 && Math.random() < 0.05) {
        const wave: Projectile = {
          id: `threat-wave-${Date.now()}`,
          ownerId: boss.id,
          type: "enemy-bolt",
          position: { x: boss.position.x + boss.facing * 1.5, y: boss.position.y },
          velocity: { x: boss.facing * 35, y: 0 },
          radius: 1.2,
          damage: 40,
          timeCostSeconds: TUNING.get().clock.heavyHitCostSeconds,
          lifetime: 2.0
        };
        projectiles.push(wave);
        this.onEnemyProjectileSpawned?.(wave);
      }
    }
  }

  private applyKinematics(enemy: EnemyState, world: CollisionWorld, dt: number): void {
    const res = world.moveAndSlide(
      enemy.radius,
      enemy.height * 0.5,
      enemy.position,
      enemy.velocity,
      dt
    );
    enemy.position = res.pos;
    enemy.velocity = res.vel;
    enemy.grounded = res.grounded;
  }

  applyHitToEnemy(enemyId: string, hit: CombatHit): void {
    const enemy = this.enemies.find((e) => e.id === enemyId);
    if (!enemy) return;

    enemy.health = Math.max(0, enemy.health - hit.damage);
    enemy.poise -= hit.damage * 0.8;

    if (hit.isLauncher && hit.launchDirection) {
      enemy.launchedTimer = TUNING.get().combat.chaseWindowSeconds;
      enemy.launchVelocity = { ...hit.knockback };
      enemy.velocity = { ...hit.knockback };
      enemy.grounded = false;
    } else {
      enemy.staggerTimer = 0.25;
      enemy.velocity = { ...hit.knockback };
    }
  }
}

import { TUNING, type KairosTuning } from "./Tuning.js";
import type { CollisionWorld } from "./Collision.js";
import type {
  AdaptationId,
  Afterimage,
  CombatHit,
  EnemyState,
  PlayerInput,
  Projectile,
  TechniqueId,
  Vec2
} from "./types.js";

export type ZenithActionState =
  | "neutral"
  | "run"
  | "jump"
  | "flight"
  | "burst"
  | "light-1"
  | "light-2"
  | "light-3"
  | "heavy-launcher"
  | "transmission"
  | "guard"
  | "perfect-guard-counter"
  | "charging-beam"
  | "firing-beam"
  | "burst-field"
  | "stagger";

export class Zenith {
  public id = "zenith";
  public pos: Vec2 = { x: 0, y: 1.0 };
  public vel: Vec2 = { x: 0, y: 0 };
  public facing: number = 1; // 1 = right, -1 = left
  public actionState: ZenithActionState = "neutral";
  public actionTimer: number = 0;
  public grounded: boolean = false;
  public flying: boolean = false;
  public ki: number = 100;
  public maxKi: number = 100;

  // Combo tracking
  public comboCount: number = 0;
  public comboTimer: number = 0;
  public comboVerbs: Set<string> = new Set();
  public toyingBonusAwarded: boolean = false;

  // Chase target state
  public launchedEnemyId: string | null = null;
  public chaseTimer: number = 0;

  // Afterimage trail & perfect guard
  public afterimages: Afterimage[] = [];
  public afterimageTimer: number = 0;
  public invulnerableTimer: number = 0;

  // Burst & transmission cooldowns
  public burstCooldown: number = 0;
  public transmissionCooldown: number = 0;

  // Beam state
  public beamChargeTime: number = 0;
  public beamAngle: number = 0; // In radians (0 = horizontal forward)
  public beamDurationRemaining: number = 0;

  // Adaptations & Techniques
  public adaptations: Set<AdaptationId> = new Set();
  public learnedTechniques: Set<TechniqueId> = new Set(["beam", "burst-field"]);
  public warpBeamInsightCount: number = 0;
  public hasWarpBeam: boolean = false;

  // Bank angle for rendering (AIRTIME momentum feel)
  public bankAngle: number = 0;

  // Hitbox / half-extents
  public halfWidth: number = 0.6;
  public halfHeight: number = 1.0;

  // Callbacks
  public onHitLanded?: (hit: CombatHit) => void;
  public onProjectileSpawned?: (proj: Projectile) => void;
  public onInsightLearned?: (insightName: string) => void;

  constructor(startPos?: Vec2) {
    if (startPos) {
      this.pos = { ...startPos };
    }
  }

  reset(startPos: Vec2 = { x: 0, y: 1.0 }): void {
    this.pos = { ...startPos };
    this.vel = { x: 0, y: 0 };
    this.facing = 1;
    this.actionState = "neutral";
    this.actionTimer = 0;
    this.grounded = false;
    this.flying = false;
    this.ki = 100;
    this.comboCount = 0;
    this.comboTimer = 0;
    this.comboVerbs.clear();
    this.toyingBonusAwarded = false;
    this.launchedEnemyId = null;
    this.chaseTimer = 0;
    this.afterimages = [];
    this.burstCooldown = 0;
    this.transmissionCooldown = 0;
    this.invulnerableTimer = 0;
    this.beamChargeTime = 0;
    this.beamDurationRemaining = 0;
    this.adaptations.clear();
    this.hasWarpBeam = false;
    this.warpBeamInsightCount = 0;
  }

  grantAdaptation(adaptation: AdaptationId): void {
    this.adaptations.add(adaptation);
  }

  hasAdaptation(adaptation: AdaptationId): boolean {
    return this.adaptations.has(adaptation);
  }

  update(
    dt: number,
    input: PlayerInput,
    enemies: EnemyState[],
    world: CollisionWorld,
    staggerActive: boolean
  ): { hits: CombatHit[]; projectiles: Projectile[] } {
    const hits: CombatHit[] = [];
    const projectiles: Projectile[] = [];
    const tuning = TUNING.get();

    // Stagger check
    if (staggerActive) {
      this.actionState = "stagger";
      this.actionTimer = 0.2;
    }

    // Cooldown updates
    if (this.burstCooldown > 0) this.burstCooldown -= dt;
    if (this.transmissionCooldown > 0) this.transmissionCooldown -= dt;
    if (this.invulnerableTimer > 0) this.invulnerableTimer -= dt;

    // Combo timer
    if (this.comboTimer > 0) {
      this.comboTimer -= dt;
      if (this.comboTimer <= 0) {
        this.comboCount = 0;
        this.comboVerbs.clear();
        this.toyingBonusAwarded = false;
      }
    }

    // Chase window
    if (this.chaseTimer > 0) {
      this.chaseTimer -= dt;
      if (this.chaseTimer <= 0) {
        this.launchedEnemyId = null;
      }
    }

    // Afterimage lifetime update
    for (let i = this.afterimages.length - 1; i >= 0; i--) {
      const img = this.afterimages[i];
      img.lifetime -= dt;
      img.alpha = Math.max(0, img.lifetime / 0.35);
      if (img.lifetime <= 0) {
        this.afterimages.splice(i, 1);
      }
    }

    // Facing direction from move input
    if (Math.abs(input.moveX) > 0.1 && !this.isAttacking()) {
      this.facing = input.moveX > 0 ? 1 : -1;
    }

    // ─────────────────────────────────────────────────────────────────────────
    // 1. BURST (Cancels almost anything)
    // ─────────────────────────────────────────────────────────────────────────
    if (input.burst && this.burstCooldown <= 0) {
      let burstDir: Vec2 = { x: input.moveX, y: input.moveY };
      const len = Math.hypot(burstDir.x, burstDir.y);
      if (len > 0.1) {
        burstDir = { x: burstDir.x / len, y: burstDir.y / len };
      } else {
        burstDir = { x: this.facing, y: 0 };
      }

      this.actionState = "burst";
      this.actionTimer = tuning.movement.burstDurationSeconds;
      this.burstCooldown = tuning.movement.burstCooldownSeconds;
      this.invulnerableTimer = tuning.movement.burstInvulnerableSeconds;
      this.vel = {
        x: burstDir.x * tuning.movement.burstSpeed,
        y: burstDir.y * tuning.movement.burstSpeed
      };

      this.spawnAfterimage("#00f0ff", 0.3);
      return { hits, projectiles };
    }

    // ─────────────────────────────────────────────────────────────────────────
    // 2. COMBAT INSTANT TRANSMISSION & CHASE
    // ─────────────────────────────────────────────────────────────────────────
    if (input.instantTransmission && this.transmissionCooldown <= 0) {
      this.spawnAfterimage("#ffffff", 0.4);

      // Check if we are in a Chase window on a launched enemy
      let chasedEnemy: EnemyState | null = null;
      if (this.launchedEnemyId && this.chaseTimer > 0) {
        chasedEnemy = enemies.find((e) => e.id === this.launchedEnemyId && e.health > 0) ?? null;
      }

      if (chasedEnemy) {
        // CHASE: Teleport directly ahead of launched enemy along their flight path!
        const aheadOffset = chasedEnemy.velocity.x > 0 ? -1.8 : 1.8;
        this.pos = {
          x: chasedEnemy.position.x + aheadOffset,
          y: chasedEnemy.position.y
        };
        this.facing = aheadOffset < 0 ? 1 : -1;
        this.vel = { x: chasedEnemy.velocity.x * 0.4, y: chasedEnemy.velocity.y * 0.4 };
        this.flying = true;
        this.actionState = "neutral";
        this.transmissionCooldown = 0.05; // Immediate follow-up
        this.chaseTimer = 0;
        this.launchedEnemyId = null;

        this.spawnAfterimage("#ff007f", 0.4);

        // Immediate follow-up chase strike
        const chaseHit: CombatHit = {
          attackerId: this.id,
          targetId: chasedEnemy.id,
          damage: 45,
          timeCostSeconds: 0,
          knockback: { x: this.facing * 14, y: 4 },
          hitstopFrames: tuning.combat.heavyHitstopFrames,
          isLauncher: false,
          verb: "chase",
          position: { ...this.pos }
        };
        hits.push(chaseHit);
        this.registerHit(chaseHit);

        return { hits, projectiles };
      }

      // Normal Combat Instant Transmission: teleport to nearest enemy's blind side (behind them)
      const nearest = this.findNearestEnemy(enemies, tuning.movement.transmissionRange);
      if (nearest) {
        const blindSideX = nearest.facing > 0
          ? nearest.position.x - tuning.movement.transmissionBlindSpotOffset
          : nearest.position.x + tuning.movement.transmissionBlindSpotOffset;

        this.pos = {
          x: blindSideX,
          y: nearest.position.y
        };
        this.facing = nearest.facing;
        this.vel = { x: 0, y: 0 };
        this.actionState = "transmission";
        this.actionTimer = tuning.movement.transmissionRecoverySeconds;
        this.transmissionCooldown = 0.35;
        this.spawnAfterimage("#00f0ff", 0.4);

        // Check Warp Beam insight
        if (input.chargeBeam || input.releaseBeam) {
          this.warpBeamInsightCount++;
          if (this.warpBeamInsightCount >= 3 && !this.hasWarpBeam) {
            this.hasWarpBeam = true;
            this.onInsightLearned?.("Warp Beam: Instant beam from transmission arrival!");
          }
        }

        return { hits, projectiles };
      }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // 3. AFTERIMAGE EVADE / PERFECT GUARD
    // ─────────────────────────────────────────────────────────────────────────
    if (input.guard && (this.actionState === "neutral" || this.actionState === "guard")) {
      if (this.actionState !== "guard") {
        this.actionState = "guard";
        this.actionTimer = tuning.combat.perfectGuardWindowSeconds;
      }
    } else if (!input.guard && this.actionState === "guard") {
      this.actionState = "neutral";
    }

    // ─────────────────────────────────────────────────────────────────────────
    // 4. KI VOLLEY
    // ─────────────────────────────────────────────────────────────────────────
    if (input.kiVolley && this.ki >= tuning.combat.kiVolleyCost && !this.isAttacking()) {
      this.ki -= tuning.combat.kiVolleyCost;
      const bolt: Projectile = {
        id: `ki-bolt-${Date.now()}-${Math.random()}`,
        ownerId: this.id,
        type: "ki-bolt",
        position: { x: this.pos.x + this.facing * 0.8, y: this.pos.y + 0.2 },
        velocity: {
          x: this.facing * tuning.combat.kiVolleyBoltSpeed,
          y: (Math.random() - 0.5) * 6
        },
        radius: 0.45,
        damage: tuning.combat.kiVolleyBoltDamage,
        timeCostSeconds: 0,
        lifetime: 1.2
      };
      projectiles.push(bolt);
      this.onProjectileSpawned?.(bolt);
      this.registerVerb("volley");
    }

    // ─────────────────────────────────────────────────────────────────────────
    // 5. CHARGEABLE, STEERABLE BEAM & WARP BEAM
    // ─────────────────────────────────────────────────────────────────────────
    if (input.chargeBeam && (this.actionState === "neutral" || this.actionState === "charging-beam" || this.actionState === "transmission")) {
      if (this.hasWarpBeam && this.actionState === "transmission") {
        // INSTANT WARP BEAM!
        this.fireBeam(projectiles, tuning);
      } else {
        this.actionState = "charging-beam";
        this.beamChargeTime = Math.min(
          tuning.combat.beamMaxChargeSeconds,
          this.beamChargeTime + dt
        );
        // Steering up/down with movement stick
        this.beamAngle = input.moveY * 0.45;
        this.vel.x *= 0.8;
        this.vel.y *= 0.8;
      }
    } else if (this.actionState === "charging-beam" && (input.releaseBeam || !input.chargeBeam)) {
      if (this.ki >= tuning.combat.beamCost) {
        this.fireBeam(projectiles, tuning);
      } else {
        this.actionState = "neutral";
        this.beamChargeTime = 0;
      }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // 6. BURST FIELD
    // ─────────────────────────────────────────────────────────────────────────
    if (input.burstField && this.ki >= tuning.combat.burstFieldCost && !this.isAttacking()) {
      this.ki -= tuning.combat.burstFieldCost;
      this.actionState = "burst-field";
      this.actionTimer = 0.35;
      this.invulnerableTimer = 0.35;

      const wave: Projectile = {
        id: `burst-wave-${Date.now()}`,
        ownerId: this.id,
        type: "burst-wave",
        position: { ...this.pos },
        velocity: { x: 0, y: 0 },
        radius: tuning.combat.burstFieldRadius,
        damage: tuning.combat.burstFieldDamage,
        timeCostSeconds: 0,
        lifetime: 0.35,
        piercing: true
      };
      projectiles.push(wave);
      this.onProjectileSpawned?.(wave);
      this.registerVerb("burst-field");
    }

    // ─────────────────────────────────────────────────────────────────────────
    // 7. LIGHT ATTACK STRING (3 Hits)
    // ─────────────────────────────────────────────────────────────────────────
    if (input.lightAttack && this.canAttack()) {
      if (this.actionState === "neutral" || this.actionState === "run" || this.actionState === "jump" || this.actionState === "flight") {
        this.actionState = "light-1";
        this.actionTimer = 0.22;
        this.vel.x = this.facing * tuning.combat.lightStepImpulse;
        const hit = this.checkMeleeHit(enemies, 2.2, tuning.combat.light1Damage, false, "light");
        if (hit) hits.push(hit);
      } else if (this.actionState === "light-1" && this.actionTimer < 0.12) {
        this.actionState = "light-2";
        this.actionTimer = 0.24;
        this.vel.x = this.facing * (tuning.combat.lightStepImpulse * 1.2);
        const hit = this.checkMeleeHit(enemies, 2.4, tuning.combat.light2Damage, false, "light");
        if (hit) hits.push(hit);
      } else if (this.actionState === "light-2" && this.actionTimer < 0.12) {
        this.actionState = "light-3";
        this.actionTimer = 0.32;
        this.vel.x = this.facing * (tuning.combat.lightStepImpulse * 1.5);
        const hit = this.checkMeleeHit(enemies, 2.8, tuning.combat.light3Damage, false, "light");
        if (hit) hits.push(hit);
      }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // 8. HEAVY LAUNCHER (8 Directions)
    // ─────────────────────────────────────────────────────────────────────────
    if (input.heavyAttack && this.canAttack()) {
      this.actionState = "heavy-launcher";
      this.actionTimer = 0.38;

      let launchDir: Vec2 = { x: input.moveX, y: input.moveY };
      const len = Math.hypot(launchDir.x, launchDir.y);
      if (len > 0.2) {
        launchDir = { x: launchDir.x / len, y: launchDir.y / len };
      } else {
        // Default launch is Up-Forward
        launchDir = { x: this.facing * 0.707, y: 0.707 };
      }

      const hit = this.checkMeleeHit(
        enemies,
        3.0,
        tuning.combat.heavyDamage,
        true,
        "launcher",
        launchDir
      );

      if (hit) {
        hits.push(hit);
        this.launchedEnemyId = hit.targetId;
        this.chaseTimer = tuning.combat.chaseWindowSeconds;
      }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // 9. ACTION TIMER & STATE TRANSITIONS
    // ─────────────────────────────────────────────────────────────────────────
    if (this.actionTimer > 0) {
      this.actionTimer -= dt;
      if (this.actionTimer <= 0) {
        if (this.actionState !== "guard" && this.actionState !== "charging-beam" && this.actionState !== "firing-beam") {
          this.actionState = "neutral";
        }
      }
    }

    if (this.beamDurationRemaining > 0) {
      this.beamDurationRemaining -= dt;
      if (this.beamDurationRemaining <= 0) {
        this.actionState = "neutral";
      }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // 10. MOVEMENT & MOMENTUM PHYSICS (AIRTIME principles)
    // ─────────────────────────────────────────────────────────────────────────
    this.updateMovement(dt, input, world);

    return { hits, projectiles };
  }

  private updateMovement(dt: number, input: PlayerInput, world: CollisionWorld): void {
    const tuning = TUNING.get();

    // Toggle/enter flight if moving vertically in the air
    if (!this.grounded && (Math.abs(input.moveY) > 0.2 || input.jump)) {
      this.flying = true;
    }
    if (this.grounded) {
      this.flying = false;
    }

    // Adaptation speed & gravity modifiers
    let gravityMult = 1.0;
    let flightSpeedMult = 1.0;
    if (this.hasAdaptation("weight")) {
      gravityMult *= 1.35;
      flightSpeedMult *= tuning.dimensions.leadfallZenithFlightSpeedPenalty; // 0.70
    }
    if (this.hasAdaptation("lift")) {
      flightSpeedMult *= 1.25; // Offsets weight penalty
    }

    if (this.actionState === "burst") {
      // Burst carries high velocity through collision
    } else if (this.flying) {
      // Free 8-Directional Flight with momentum
      const targetSpeed = tuning.movement.flightSpeed * flightSpeedMult;
      const wishX = input.moveX * targetSpeed;
      const wishY = input.moveY * targetSpeed;

      const accel = tuning.movement.flightAcceleration;
      this.vel.x += (wishX - this.vel.x) * Math.min(1.0, accel * dt);
      this.vel.y += (wishY - this.vel.y) * Math.min(1.0, accel * dt);

      // Banking into turns (AIRTIME visual feel)
      const targetBank = (-this.vel.x / targetSpeed) * (tuning.movement.bankAngleMaxDegrees * Math.PI / 180);
      this.bankAngle += (targetBank - this.bankAngle) * Math.min(1.0, tuning.movement.flightTurnRate * dt);
    } else {
      // Ground / Normal Jump Running
      const targetRunSpeed = input.moveX * tuning.movement.runSpeed;
      const accel = Math.abs(targetRunSpeed) > 0.1 ? tuning.movement.runAcceleration : tuning.movement.runDeceleration;
      this.vel.x += (targetRunSpeed - this.vel.x) * Math.min(1.0, accel * dt);

      // Jump
      if (input.jump && this.grounded) {
        this.vel.y = tuning.movement.jumpImpulse;
        this.grounded = false;
      }

      // Gravity
      if (!this.grounded) {
        const effectiveGravity = tuning.movement.gravity * gravityMult;
        this.vel.y += effectiveGravity * dt;
        if (this.vel.y < tuning.movement.terminalVelocity) {
          this.vel.y = tuning.movement.terminalVelocity;
        }
      }

      this.bankAngle *= 0.8;
    }

    // Kinematic Move and Slide
    const result = world.moveAndSlide(
      this.halfWidth,
      this.halfHeight,
      this.pos,
      this.vel,
      dt
    );

    this.pos = result.pos;
    this.vel = result.vel;
    this.grounded = result.grounded;

    if (this.grounded && this.flying) {
      this.flying = false;
    }
  }

  private fireBeam(projectiles: Projectile[], tuning: KairosTuning): void {
    this.ki -= tuning.combat.beamCost;
    this.actionState = "firing-beam";
    this.beamDurationRemaining = 0.6;
    const chargeMultiplier = 1.0 + (this.beamChargeTime / tuning.combat.beamMaxChargeSeconds) * 1.5;

    const angle = this.beamAngle;
    const cosA = Math.cos(angle) * this.facing;
    const sinA = Math.sin(angle);

    const beamProj: Projectile = {
      id: `beam-${Date.now()}`,
      ownerId: this.id,
      type: "beam-segment",
      position: { x: this.pos.x + this.facing * 1.2, y: this.pos.y + 0.3 },
      velocity: { x: cosA * 70, y: sinA * 70 },
      radius: 1.2 * chargeMultiplier,
      damage: (tuning.combat.beamBaseDamagePerSecond * 0.5) * chargeMultiplier,
      timeCostSeconds: 0,
      lifetime: 0.5,
      piercing: true,
      dragsDownward: this.hasAdaptation("weight")
    };

    projectiles.push(beamProj);
    this.onProjectileSpawned?.(beamProj);
    this.registerVerb("beam");
    this.beamChargeTime = 0;
  }

  private checkMeleeHit(
    enemies: EnemyState[],
    range: number,
    baseDamage: number,
    isLauncher: boolean,
    verb: CombatHit["verb"],
    launchDir?: Vec2
  ): CombatHit | null {
    const tuning = TUNING.get();
    for (const enemy of enemies) {
      if (enemy.health <= 0) continue;

      const dx = enemy.position.x - this.pos.x;
      const dy = enemy.position.y - this.pos.y;
      const dist = Math.hypot(dx, dy);

      // Check facing direction and range
      if (dist <= range && (dx * this.facing >= -0.5)) {
        let knockback: Vec2 = { x: this.facing * 8, y: 3 };
        let hitstop = tuning.combat.lightHitstopFrames;

        if (isLauncher && launchDir) {
          knockback = {
            x: launchDir.x * tuning.combat.heavyLaunchSpeed,
            y: launchDir.y * tuning.combat.heavyLaunchSpeed
          };
          hitstop = tuning.combat.heavyHitstopFrames;
        }

        // Carried Weight adaptation applies crushing floor damage!
        let damage = baseDamage;
        if (this.hasAdaptation("weight") && enemy.grounded) {
          damage *= tuning.dimensions.carriedWeightCrushDamageMultiplier;
        }

        const hit: CombatHit = {
          attackerId: this.id,
          targetId: enemy.id,
          damage,
          timeCostSeconds: 0,
          knockback,
          hitstopFrames: hitstop,
          isLauncher,
          launchDirection: launchDir,
          verb,
          position: { ...enemy.position }
        };

        this.registerHit(hit);
        return hit;
      }
    }
    return null;
  }

  public registerHit(hit: CombatHit): void {
    const tuning = TUNING.get();
    this.ki = Math.min(this.maxKi, this.ki + tuning.combat.kiGainPerHit);
    this.comboCount++;
    this.comboTimer = tuning.combat.lightComboResetSeconds;
    this.registerVerb(hit.verb);

    // Cancel transmission recovery upon landing a hit
    if (this.actionState === "transmission") {
      this.actionState = "neutral";
      this.actionTimer = 0;
    }

    this.onHitLanded?.(hit);
  }

  private registerVerb(verb: string): void {
    this.comboVerbs.add(verb);
    // Toying bonus: combo using 4+ distinct verbs grants bonus score!
    if (this.comboVerbs.size >= 4 && !this.toyingBonusAwarded) {
      this.toyingBonusAwarded = true;
    }
  }

  public takeHit(damage: number, timeCost: number, knockback: Vec2): boolean {
    if (this.invulnerableTimer > 0) return false;

    // Check perfect guard
    if (this.actionState === "guard" && this.actionTimer > 0) {
      // PERFECT GUARD!
      this.spawnAfterimage("#00f0ff", 0.6);
      this.actionState = "perfect-guard-counter";
      this.actionTimer = 0.35;
      this.invulnerableTimer = 0.45;
      this.vel = { x: -knockback.x * 0.2, y: 2 };
      this.ki = Math.min(this.maxKi, this.ki + 25);
      return false; // Negated hit!
    }

    // Normal hit taken
    let effectiveKnockbackX = knockback.x;
    let effectiveKnockbackY = knockback.y;

    if (this.hasAdaptation("lift")) {
      // Lift penalty: knockback is 45% farther
      effectiveKnockbackX *= TUNING.get().dimensions.skyreachZenithKnockbackPenalty;
      effectiveKnockbackY *= TUNING.get().dimensions.skyreachZenithKnockbackPenalty;
    }
    if (this.hasAdaptation("weight")) {
      // Weight offsets knockback
      effectiveKnockbackX *= 0.75;
      effectiveKnockbackY *= 0.75;
    }

    this.vel = { x: effectiveKnockbackX, y: effectiveKnockbackY };
    this.invulnerableTimer = 0.35;
    return true; // Hit landed
  }

  private findNearestEnemy(enemies: EnemyState[], maxRange: number): EnemyState | null {
    let nearest: EnemyState | null = null;
    let minDist = maxRange;
    for (const enemy of enemies) {
      if (enemy.health <= 0) continue;
      const dist = Math.hypot(enemy.position.x - this.pos.x, enemy.position.y - this.pos.y);
      if (dist < minDist) {
        minDist = dist;
        nearest = enemy;
      }
    }
    return nearest;
  }

  private spawnAfterimage(color: string, lifetime: number): void {
    this.afterimages.push({
      id: `afterimage-${Date.now()}-${Math.random()}`,
      position: { ...this.pos },
      facing: this.facing,
      alpha: 0.9,
      lifetime,
      color
    });
  }

  private isAttacking(): boolean {
    return (
      this.actionState === "light-1" ||
      this.actionState === "light-2" ||
      this.actionState === "light-3" ||
      this.actionState === "heavy-launcher" ||
      this.actionState === "charging-beam" ||
      this.actionState === "firing-beam" ||
      this.actionState === "burst-field"
    );
  }

  private canAttack(): boolean {
    return (
      this.actionState === "neutral" ||
      this.actionState === "run" ||
      this.actionState === "jump" ||
      this.actionState === "flight" ||
      this.actionState === "light-1" ||
      this.actionState === "light-2"
    );
  }
}

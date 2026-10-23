import { CollisionWorld } from "./Collision.js";
import { DimensionManager } from "./Dimensions.js";
import { EnemyManager } from "./Enemies.js";
import { MultiverseMap } from "./MultiverseMap.js";
import { ReplayRecorder, ReplayPlayer, type ReplayData } from "./Replay.js";
import { RunClock, type RunPhase } from "./RunClock.js";
import { TUNING } from "./Tuning.js";
import type {
  AdaptationId,
  CombatHit,
  DimensionId,
  DimensionMark,
  LegacyRunSummary,
  PlayerInput,
  Projectile,
  ThresholdOption,
  Vec2
} from "./types.js";
import { Zenith } from "./Zenith.js";

export interface SimulationEvent {
  type: string;
  payload?: Record<string, unknown>;
}

export class KairosSimulation {
  public seed: number;
  public tickCount: number = 0;
  public hitstopRemainingFrames: number = 0;

  // Subsystems
  public zenith: Zenith;
  public world: CollisionWorld;
  public enemies: EnemyManager;
  public clock: RunClock;
  public dimensions: DimensionManager;
  public multiverseMap: MultiverseMap;
  public projectiles: Projectile[] = [];

  // Replay
  public recorder: ReplayRecorder;
  public replayer: ReplayPlayer;

  // Stats
  public enemiesKilled: number = 0;
  public peakPowerMultiplier: number = 1.0;
  public maxCombo: number = 0;
  public threatDefeated: boolean = false;
  public threatDefeatedAtSeconds?: number;
  public legacySummary?: LegacyRunSummary;

  // Event bus to Renderer & Impact adapter
  public eventQueue: SimulationEvent[] = [];

  constructor(seed: number = 1337, runDurationSeconds?: number) {
    this.seed = seed;
    const duration = runDurationSeconds ?? TUNING.get().clock.defaultRunDurationSeconds;

    this.zenith = new Zenith({ x: -25, y: 1.5 });
    this.world = new CollisionWorld();
    this.enemies = new EnemyManager();
    this.clock = new RunClock(duration);
    this.dimensions = new DimensionManager(seed);
    this.multiverseMap = new MultiverseMap();
    this.recorder = new ReplayRecorder(seed, duration);
    this.replayer = new ReplayPlayer();

    this.setupListeners();
    this.loadDimension("threshold");
  }

  reset(newSeed?: number, durationSeconds?: number): void {
    if (newSeed !== undefined) this.seed = newSeed;
    const duration = durationSeconds ?? TUNING.get().clock.defaultRunDurationSeconds;

    this.tickCount = 0;
    this.hitstopRemainingFrames = 0;
    this.enemiesKilled = 0;
    this.peakPowerMultiplier = 1.0;
    this.maxCombo = 0;
    this.threatDefeated = false;
    this.threatDefeatedAtSeconds = undefined;
    this.legacySummary = undefined;
    this.projectiles = [];
    this.eventQueue = [];

    this.clock.reset(duration);
    this.dimensions.buildDimensions(this.seed);
    this.multiverseMap.initMap();
    this.recorder.reset(this.seed, duration);
    this.replayer.stop();

    this.zenith.reset({ x: -25, y: 1.5 });
    this.loadDimension("threshold");
  }

  private setupListeners(): void {
    this.clock.onThresholdTriggered = (index: number, options: ThresholdOption[]) => {
      this.eventQueue.push({
        type: "threshold-triggered",
        payload: { index, options }
      });
    };

    this.clock.onOverflowEntered = () => {
      this.eventQueue.push({ type: "overflow-entered" });
    };

    this.clock.onFadeFightStarted = () => {
      // Spawn The Threat directly into current dimension!
      this.spawnThreatBoss();
      this.eventQueue.push({ type: "fade-fight-started" });
    };

    this.clock.onRunEnded = (fadeLine: string) => {
      this.legacySummary = {
        seed: this.seed,
        totalRunTimeSeconds: this.clock.state.totalDurationSeconds,
        elapsedSeconds: this.clock.state.elapsedSeconds,
        finalClockSeconds: this.clock.state.remainingSeconds,
        peakPowerMultiplier: this.peakPowerMultiplier,
        threatDefeated: this.threatDefeated,
        threatDefeatedAtSeconds: this.threatDefeatedAtSeconds,
        fadeTriggered: true,
        dimensionsMarked: [...this.dimensions.marks],
        insightsLearned: this.zenith.hasWarpBeam ? ["Warp Beam"] : [],
        maxCombo: this.maxCombo,
        enemiesDefeated: this.enemiesKilled,
        fadeLineSpoken: fadeLine
      };
      this.eventQueue.push({
        type: "run-ended",
        payload: { summary: this.legacySummary }
      });
    };

    this.dimensions.onAdaptationUnlocked = (adaptation: AdaptationId, dimensionName: string) => {
      this.zenith.grantAdaptation(adaptation);
      this.eventQueue.push({
        type: "adaptation-unlocked",
        payload: { adaptation, dimensionName }
      });
    };

    this.dimensions.onDimensionMarked = (mark: DimensionMark) => {
      this.multiverseMap.updateCorruptionAndThreat(
        this.clock.state.elapsedSeconds,
        this.clock.state.totalDurationSeconds,
        this.dimensions.marks
      );
      this.eventQueue.push({
        type: "dimension-marked",
        payload: { mark }
      });
    };

    this.zenith.onHitLanded = (hit: CombatHit) => {
      this.enemies.applyHitToEnemy(hit.targetId, hit);
      this.hitstopRemainingFrames = Math.max(this.hitstopRemainingFrames, hit.hitstopFrames);
      this.eventQueue.push({
        type: "zenith-hit-landed",
        payload: { hit, inOverflow: this.clock.state.inOverflow }
      });
    };

    this.zenith.onProjectileSpawned = (proj: Projectile) => {
      this.projectiles.push(proj);
    };

    this.zenith.onInsightLearned = (insight: string) => {
      this.eventQueue.push({
        type: "insight-learned",
        payload: { insight }
      });
    };

    this.enemies.onEnemyKilled = (enemy) => {
      this.enemiesKilled++;
      if (enemy.type === "the-threat") {
        this.threatDefeated = true;
        this.threatDefeatedAtSeconds = this.clock.state.elapsedSeconds;
        this.eventQueue.push({ type: "threat-defeated" });
      }

      // Add exposure to current dimension
      const expAmount = enemy.type === "armored-brute" ? 35 : enemy.type === "heavy-flyer" ? 40 : 18;
      this.dimensions.addExposure(expAmount);
    };

    this.enemies.onEnemyProjectileSpawned = (proj: Projectile) => {
      this.projectiles.push(proj);
    };
  }

  loadDimension(dimensionId: DimensionId): void {
    const instance = this.dimensions.setCurrent(dimensionId);
    this.world.setPlatforms(instance.platforms);
    this.zenith.pos = { ...instance.playerSpawn };
    this.zenith.vel = { x: 0, y: 0 };
    this.enemies.clear();
    this.projectiles = [];

    // Check mark on entry (e.g., Weight into Skyreach)
    this.dimensions.checkMarkOnEntry(this.zenith.hasAdaptation("weight"), this.clock.state.elapsedSeconds);

    // Spawn initial enemy wave based on dimension
    this.spawnEnemiesForDimension(dimensionId, instance.marked);

    this.eventQueue.push({
      type: "dimension-loaded",
      payload: { dimensionId, definition: instance.definition }
    });
  }

  private spawnEnemiesForDimension(id: DimensionId, marked: boolean): void {
    const current = this.dimensions.getCurrent();
    const spawns = current.spawnPoints;

    switch (id) {
      case "threshold":
        // Swarm fodder & 1 ranged type
        for (let i = 0; i < Math.min(spawns.length, 4); i++) {
          const type = i === 1 ? "ranged-blaster" : "swarm-fodder";
          this.enemies.spawn(type, spawns[i]);
        }
        break;
      case "leadfall":
        // Armored brutes with ground slams
        for (let i = 0; i < Math.min(spawns.length, 3); i++) {
          this.enemies.spawn("armored-brute", spawns[i]);
        }
        break;
      case "skyreach":
        // Fast flyers & heavy flyer
        for (let i = 0; i < Math.min(spawns.length, 4); i++) {
          const type = i === 2 ? "heavy-flyer" : "fast-flyer";
          this.enemies.spawn(type, spawns[i]);
        }
        break;
      case "corridor":
        // Light encounters
        for (let i = 0; i < Math.min(spawns.length, 2); i++) {
          this.enemies.spawn("swarm-fodder", spawns[i]);
        }
        break;
      case "threat-node":
        this.spawnThreatBoss();
        break;
    }
  }

  spawnThreatBoss(): void {
    this.enemies.spawn("the-threat", { x: 12, y: 2.5 });
  }

  /**
   * Main 60 Hz simulation tick.
   */
  step(rawInput: PlayerInput): void {
    this.tickCount++;

    // Replay override or recording
    let activeInput = rawInput;
    if (this.replayer.active) {
      const sampled = this.replayer.sampleTick(this.tickCount);
      if (sampled) activeInput = sampled;
    } else {
      this.recorder.recordTick(this.tickCount, activeInput);
    }

    // Hitstop check: freezes entity logic for combat impact feel
    if (this.hitstopRemainingFrames > 0) {
      this.hitstopRemainingFrames--;
      return;
    }

    const dt = 1 / 60;

    // 1. Clock tick
    this.clock.tick(dt, this.threatDefeated);
    if (this.clock.state.continuousPowerMultiplier > this.peakPowerMultiplier) {
      this.peakPowerMultiplier = this.clock.state.continuousPowerMultiplier;
    }

    // Multiverse corruption update
    this.multiverseMap.updateCorruptionAndThreat(
      this.clock.state.elapsedSeconds,
      this.clock.state.totalDurationSeconds,
      this.dimensions.marks
    );

    // 2. Zenith update
    const staggerActive = this.clock.state.staggerRemainingSeconds > 0;
    const zenithResult = this.zenith.update(
      dt,
      activeInput,
      this.enemies.enemies,
      this.world,
      staggerActive
    );

    if (this.zenith.comboCount > this.maxCombo) {
      this.maxCombo = this.zenith.comboCount;
    }

    // 3. Enemy updates
    const currentDim = this.dimensions.getCurrent();
    const enemyResult = this.enemies.update(
      dt,
      this.zenith.pos,
      this.zenith.hasAdaptation("weight"),
      currentDim.definition.id,
      currentDim.marked,
      this.world
    );

    // Process enemy hits on Zenith
    for (const hit of enemyResult.enemyHits) {
      const landed = this.zenith.takeHit(hit.damage, hit.timeCostSeconds, hit.knockback);
      if (landed) {
        // Time is health: deduct seconds from clock!
        this.clock.deductTime(hit.timeCostSeconds);
        this.hitstopRemainingFrames = Math.max(this.hitstopRemainingFrames, hit.hitstopFrames);
        this.eventQueue.push({
          type: "zenith-hit-taken",
          payload: { hit, remainingSeconds: this.clock.state.remainingSeconds }
        });
      } else {
        // Perfect Guard Counter event!
        this.hitstopRemainingFrames = 12;
        this.eventQueue.push({
          type: "zenith-perfect-guard",
          payload: { position: { ...this.zenith.pos } }
        });
      }
    }

    // 4. Projectiles update
    this.updateProjectiles(dt);

    // Dynamic respawn if all dimension enemies cleared
    if (
      this.enemies.enemies.length === 0 &&
      currentDim.definition.id !== "threat-node" &&
      currentDim.definition.id !== "corridor"
    ) {
      this.spawnEnemiesForDimension(currentDim.definition.id, currentDim.marked);
    }
  }

  private updateProjectiles(dt: number): void {
    for (let i = this.projectiles.length - 1; i >= 0; i--) {
      const p = this.projectiles[i];
      p.lifetime -= dt;
      p.position.x += p.velocity.x * dt;
      p.position.y += p.velocity.y * dt;

      if (p.dragsDownward) {
        p.velocity.y += TUNING.get().movement.gravity * 0.4 * dt;
      }

      if (p.lifetime <= 0) {
        this.projectiles.splice(i, 1);
        continue;
      }

      // Check collision
      if (p.ownerId === "zenith") {
        for (const enemy of this.enemies.enemies) {
          if (enemy.health <= 0) continue;
          const dist = Math.hypot(enemy.position.x - p.position.x, enemy.position.y - p.position.y);
          if (dist < enemy.radius + p.radius) {
            enemy.health -= p.damage;
            enemy.staggerTimer = 0.2;
            if (p.dragsDownward) {
              enemy.velocity.y = -25; // Drag down to earth!
            }

            this.eventQueue.push({
              type: "projectile-hit",
              payload: { position: { ...p.position }, damage: p.damage }
            });

            if (!p.piercing) {
              this.projectiles.splice(i, 1);
              break;
            }
          }
        }
      } else {
        // Enemy projectile hitting Zenith
        const dist = Math.hypot(this.zenith.pos.x - p.position.x, this.zenith.pos.y - p.position.y);
        if (dist < this.zenith.halfWidth + p.radius) {
          const landed = this.zenith.takeHit(p.damage, p.timeCostSeconds, {
            x: Math.sign(p.velocity.x) * 8,
            y: 2
          });
          if (landed) {
            this.clock.deductTime(p.timeCostSeconds);
          }
          this.projectiles.splice(i, 1);
        }
      }
    }
  }

  travelTo(dimensionId: DimensionId, instant: boolean): void {
    if (instant) {
      // Instant transmission travel costs 5s of clock
      this.clock.deductTime(TUNING.get().clock.teleportDimensionCostSeconds);
      this.loadDimension(dimensionId);
    } else {
      // Flight traversal via Corridor
      this.loadDimension("corridor");
      // Once corridor is traversed, arrives at target
    }
  }

  drainEvents(): SimulationEvent[] {
    const events = this.eventQueue;
    this.eventQueue = [];
    return events;
  }
}

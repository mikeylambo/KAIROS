import test from "node:test";
import assert from "node:assert/strict";
import { KairosSimulation } from "../dist-test/sim/KairosSimulation.js";
import { TUNING } from "../dist-test/sim/Tuning.js";

const neutralInput = {
  moveX: 0,
  moveY: 0,
  jump: false,
  burst: false,
  instantTransmission: false,
  lightAttack: false,
  heavyAttack: false,
  guard: false,
  kiVolley: false,
  chargeBeam: false,
  releaseBeam: false,
  burstField: false
};

test("1. Combat: Light string, heavy launcher, and chase transmission", () => {
  const sim = new KairosSimulation(42, 1800);
  assert.equal(sim.zenith.comboCount, 0);

  // Spawn an armored brute with high health so combo string can fully chain
  const enemy = sim.enemies.spawn("armored-brute", { x: 0, y: 1.5 });
  sim.zenith.pos = { x: enemy.position.x - 1.2, y: enemy.position.y };
  sim.zenith.facing = 1;

  // Light 1
  sim.step({ ...neutralInput, lightAttack: true });
  assert.equal(sim.zenith.comboCount, 1, "Light 1 connects");

  // Advance frames
  for (let i = 0; i < 12; i++) sim.step(neutralInput);

  // Light 2
  sim.step({ ...neutralInput, lightAttack: true });
  assert.equal(sim.zenith.comboCount, 2, "Light 2 connects");

  for (let i = 0; i < 12; i++) sim.step(neutralInput);

  // Heavy launcher upwards
  sim.step({ ...neutralInput, moveX: 1, moveY: 1, heavyAttack: true });
  assert.equal(sim.zenith.comboCount, 3, "Heavy launcher connects");
  assert.ok(enemy.launchedTimer > 0, "Enemy is in launched state");
  assert.ok(enemy.velocity.y > 10, "Enemy has upward launch velocity");
  assert.equal(sim.zenith.launchedEnemyId, enemy.id, "Chase target is tracked");

  // Advance frames through hitstop (10 frames) and enemy launch flight
  for (let i = 0; i < 15; i++) sim.step(neutralInput);

  // Chase transmission: warp to enemy's trajectory!
  sim.step({ ...neutralInput, instantTransmission: true });
  assert.equal(sim.zenith.comboCount, 4, "Chase attack connects in mid-air");
  assert.ok(sim.zenith.flying, "Zenith is airborne in chase combo");
  assert.ok(sim.zenith.comboVerbs.has("chase"), "Chase verb recorded");
});

test("2. Clock & Vessel: Time is health, power growth, and overflow", () => {
  const sim = new KairosSimulation(101, 1800);
  assert.equal(sim.clock.state.remainingSeconds, 1800);

  // Enemy hit costs seconds
  const initialSeconds = sim.clock.state.remainingSeconds;
  sim.clock.deductTime(5.0); // Heavy hit
  assert.equal(sim.clock.state.remainingSeconds, initialSeconds - 5.0, "Deducted 5s from clock");

  // Continuous power growth over elapsed time
  for (let i = 0; i < 180; i++) {
    sim.step(neutralInput);
  }
  assert.ok(sim.clock.state.continuousPowerMultiplier > 1.0, "Power grows with elapsed time");

  // Scale clock down to test 28:00 overflow and fade fight
  TUNING.setRunDuration(60); // 60s run
  const fastSim = new KairosSimulation(999, 60);

  // Advance clock until remaining time reaches 0 and fade fight starts
  while (fastSim.clock.state.phase === "running") {
    fastSim.step(neutralInput);
  }

  assert.equal(fastSim.clock.state.phase, "fade-fight", "Phase transitions to fade-fight");
  assert.ok(fastSim.clock.state.inOverflow, "Zenith is in overflow state during fade-fight");

  // Defeat threat boss during fade fight -> triggers fade dissolve
  fastSim.threatDefeated = true;
  fastSim.step(neutralInput);
  assert.equal(fastSim.clock.state.phase, "fade-dissolve", "Defeating threat leads to fade dissolve");

  // Fast forward through dissolve
  while (fastSim.clock.state.phase !== "ended") {
    fastSim.step(neutralInput);
  }

  assert.ok(fastSim.legacySummary, "Legacy summary generated upon fade ending");
  assert.ok(fastSim.legacySummary.fadeTriggered, "Fade cinematic triggered");
  TUNING.reset();
});

test("3. Dimensions: Weight adaptation and marking Skyreach", () => {
  const sim = new KairosSimulation(77, 1800);
  assert.equal(sim.dimensions.currentDimensionId, "threshold");

  // Travel to Leadfall
  sim.travelTo("leadfall", true);
  assert.equal(sim.dimensions.currentDimensionId, "leadfall");

  // Fill exposure meter in Leadfall
  const adaptResult = sim.dimensions.addExposure(100);
  assert.equal(adaptResult.adapted, true);
  assert.equal(adaptResult.adaptationId, "weight");
  assert.ok(sim.zenith.hasAdaptation("weight"), "Zenith gained Weight adaptation");

  // Travel to Skyreach carrying Weight
  sim.travelTo("skyreach", true);
  assert.equal(sim.dimensions.currentDimensionId, "skyreach");

  // Verify Skyreach was marked!
  const currentDim = sim.dimensions.getCurrent();
  assert.ok(currentDim.marked, "Skyreach is marked by carrying Weight");
  assert.ok(sim.multiverseMap.nodes.get("skyreach")?.marked, "Multiverse map node reflects mark");

  // Verify flyers in Skyreach are pulled down by gravity!
  const flyer = sim.enemies.enemies.find((e) => e.type === "fast-flyer" || e.type === "heavy-flyer");
  assert.ok(flyer, "Skyreach flyer spawned");

  // Step simulation and observe downward velocity on flyer
  sim.step(neutralInput);
  assert.ok(flyer.isGroundedByWeight, "Flyer is grounded by weight adaptation field");
  assert.ok(flyer.velocity.y < 0, "Gravity pulls flyer toward floor");
});

test("4. Determinism & Replay", () => {
  const runSeed = 54321;
  const simA = new KairosSimulation(runSeed, 1800);

  // Play 120 ticks with varied inputs
  for (let tick = 0; tick < 120; tick++) {
    const input = {
      ...neutralInput,
      moveX: tick % 20 < 10 ? 1 : -1,
      jump: tick % 30 === 0,
      lightAttack: tick % 15 === 0
    };
    simA.step(input);
  }

  // Export replay
  const replayData = simA.recorder.exportData();
  assert.equal(replayData.frames.length, 120, "Recorded 120 frames of input");

  // Create new simulation with identical seed and replay recorded inputs
  const simB = new KairosSimulation(runSeed, 1800);
  simB.replayer.load(replayData);

  for (let tick = 0; tick < 120; tick++) {
    simB.step(neutralInput); // Replayer will supply recorded inputs
  }

  // Verify bit-for-bit identical state!
  assert.equal(simB.zenith.pos.x, simA.zenith.pos.x, "Identical X position");
  assert.equal(simB.zenith.pos.y, simA.zenith.pos.y, "Identical Y position");
  assert.equal(simB.zenith.vel.x, simA.zenith.vel.x, "Identical X velocity");
  assert.equal(simB.zenith.vel.y, simA.zenith.vel.y, "Identical Y velocity");
  assert.equal(simB.zenith.comboCount, simA.zenith.comboCount, "Identical combo count");
  assert.equal(simB.clock.state.remainingSeconds, simA.clock.state.remainingSeconds, "Identical clock state");
});

test("5. Full Run E2E: Threshold -> Leadfall Adapt -> Mark Skyreach -> Threat Slay -> Fade Ending", () => {
  const sim = new KairosSimulation(2026, 60);

  // 1. Threshold
  assert.equal(sim.dimensions.currentDimensionId, "threshold");
  for (let i = 0; i < 30; i++) sim.step(neutralInput);

  // 2. Travel to Leadfall and adapt to Weight
  sim.travelTo("leadfall", true);
  sim.dimensions.addExposure(100);
  assert.ok(sim.zenith.hasAdaptation("weight"), "Adapted to Weight in Leadfall");

  // 3. Travel to Skyreach and leave Mark
  sim.travelTo("skyreach", true);
  assert.ok(sim.dimensions.getCurrent().marked, "Skyreach marked by Weight");
  assert.equal(sim.dimensions.marks.length, 1);

  // 4. Travel to Threat Rupture
  sim.travelTo("threat-node", true);
  const threat = sim.enemies.enemies.find((e) => e.type === "the-threat");
  assert.ok(threat, "The Threat boss spawned");

  // Damage Threat to 0
  threat.health = 0;
  sim.step(neutralInput);
  assert.equal(sim.threatDefeated, true, "The Threat defeated");

  // Trigger Fade Ending
  sim.clock.triggerFadeDissolve();
  while (sim.clock.state.phase !== "ended") {
    sim.step(neutralInput);
  }

  assert.ok(sim.legacySummary, "Legacy summary generated");
  assert.equal(sim.legacySummary.threatDefeated, true);
  assert.equal(sim.legacySummary.dimensionsMarked.length, 1);
  assert.equal(sim.legacySummary.dimensionsMarked[0].dimensionId, "skyreach");
});

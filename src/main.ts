import { BrowserInputSource } from "./ported/input/BrowserInputSource.js";
import { KairosSimulation } from "./sim/KairosSimulation.js";
import { TUNING } from "./sim/Tuning.js";
import type { PlayerInput } from "./sim/types.js";
import { KairosRenderer } from "./render/KairosRenderer.js";
import { KairosHUD } from "./ui/HUD.js";
import { TuningPanel } from "./ui/TuningPanel.js";

// Input bindings using @slu/web-shell InputBinding schema
const INPUT_BINDINGS = [
  { action: "moveLeft", keyboard: ["KeyA", "ArrowLeft"] },
  { action: "moveRight", keyboard: ["KeyD", "ArrowRight"] },
  { action: "moveUp", keyboard: ["KeyW", "ArrowUp"] },
  { action: "moveDown", keyboard: ["KeyS", "ArrowDown"] },
  { action: "jump", keyboard: ["KeyW", "ArrowUp"] },
  { action: "burst", keyboard: ["ShiftLeft", "ShiftRight"] },
  { action: "transmission", keyboard: ["Space"] },
  { action: "lightAttack", keyboard: ["KeyJ"] },
  { action: "heavyAttack", keyboard: ["KeyK"] },
  { action: "guard", keyboard: ["KeyL"] },
  { action: "kiVolley", keyboard: ["KeyU"] },
  { action: "beam", keyboard: ["KeyI"] },
  { action: "burstField", keyboard: ["KeyO"] },
  { action: "toggleMap", keyboard: ["KeyM"] },
  { action: "toggleTuner", keyboard: ["Backquote", "Tab"] }
];

async function init(): Promise<void> {
  const gameCanvas = document.getElementById("game-canvas") as HTMLCanvasElement;
  const overlayCanvas = document.getElementById("overlay-canvas") as HTMLCanvasElement;
  const uiRoot = document.getElementById("ui") as HTMLElement;

  if (!gameCanvas || !overlayCanvas || !uiRoot) {
    throw new Error("Missing canvas or UI root in DOM.");
  }

  // 1. Initialize latched browser input source
  const inputSource = new BrowserInputSource(INPUT_BINDINGS);
  inputSource.attach(window);

  // 2. Initialize 60 Hz Simulation
  const seed = 0x51ac;
  const sim = new KairosSimulation(seed);

  // 3. Initialize 2.5D Three.js Renderer
  const renderer = new KairosRenderer(gameCanvas, overlayCanvas);
  renderer.rebuildEnvironment(sim);

  // 4. Initialize HUD and Tuning Panel
  const hud = new KairosHUD(uiRoot);
  const tuner = new TuningPanel(uiRoot, sim, (show) => {
    hud.showNumericTimer = show;
  });

  document.getElementById("btn-toggle-tuner")?.addEventListener("click", () => {
    tuner.toggle();
  });

  hud.onTravelRequested = (id, instant) => {
    sim.travelTo(id, instant);
  };

  hud.onRestartRequested = () => {
    sim.reset(Math.floor(Math.random() * 100000));
  };

  hud.onReplayRequested = () => {
    const replayData = sim.recorder.exportData();
    sim.replayer.load(replayData);
    sim.reset(replayData.seed, replayData.runDurationSeconds);
    sim.replayer.active = true;
  };

  // Listen to simulation threshold events
  sim.clock.onThresholdTriggered = (index, options) => {
    hud.showThresholdModal(index, options);
  };

  // Keyboard shortcut for Tuner & Map
  window.addEventListener("keydown", (e) => {
    if (e.code === "Tab" || e.code === "Backquote") {
      e.preventDefault();
      tuner.toggle();
    } else if (e.code === "KeyM") {
      hud.toggleMapModal(true, sim);
    }
  });

  // Track beam charging state
  let beamCharging = false;

  // 5. Deterministic Fixed Timestep Accumulator Loop
  const FIXED_TIMESTEP = 1 / 60;
  let lastTime = performance.now();
  let accumulator = 0;

  function loop(currentTime: number): void {
    requestAnimationFrame(loop);

    const frameDelta = Math.min(0.1, (currentTime - lastTime) / 1000);
    lastTime = currentTime;

    // Slow motion debug toggle
    const slowmo = (window as any).KAIROS_SLOWMO ? 0.25 : renderer.impactBridge.slowmoFactor;
    accumulator += frameDelta * slowmo;

    // Poll latched inputs
    const rawInputs = inputSource.poll();

    const moveX = (rawInputs.get("moveRight") ?? 0) - (rawInputs.get("moveLeft") ?? 0);
    const moveY = (rawInputs.get("moveUp") ?? 0) - (rawInputs.get("moveDown") ?? 0);

    const beamKey = (rawInputs.get("beam") ?? 0) > 0;
    const chargeBeam = beamKey;
    let releaseBeam = false;
    if (beamCharging && !beamKey) {
      releaseBeam = true;
    }
    beamCharging = beamKey;

    const playerInput: PlayerInput = {
      moveX,
      moveY,
      jump: (rawInputs.get("jump") ?? 0) > 0,
      burst: (rawInputs.get("burst") ?? 0) > 0,
      instantTransmission: (rawInputs.get("transmission") ?? 0) > 0,
      lightAttack: (rawInputs.get("lightAttack") ?? 0) > 0,
      heavyAttack: (rawInputs.get("heavyAttack") ?? 0) > 0,
      guard: (rawInputs.get("guard") ?? 0) > 0,
      kiVolley: (rawInputs.get("kiVolley") ?? 0) > 0,
      chargeBeam,
      releaseBeam,
      burstField: (rawInputs.get("burstField") ?? 0) > 0
    };

    // Fixed 60 Hz simulation updates (max 5 steps to guard against spiral of death)
    let steps = 0;
    while (accumulator >= FIXED_TIMESTEP && steps < 5) {
      sim.step(playerInput);
      accumulator -= FIXED_TIMESTEP;
      steps++;
    }

    // Render 3D and 2D overlays
    renderer.render(sim, frameDelta);

    // Update HUD
    hud.update(sim);
  }

  requestAnimationFrame(loop);
}

// Auto-boot on load
if (typeof window !== "undefined") {
  window.addEventListener("DOMContentLoaded", () => {
    init().catch(console.error);
  });
}

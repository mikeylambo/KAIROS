import type { KairosSimulation } from "../sim/KairosSimulation.js";
import { TUNING } from "../sim/Tuning.js";
import type { DimensionId } from "../sim/types.js";

export class TuningPanel {
  public visible: boolean = false;
  private container: HTMLElement;
  private panelEl!: HTMLElement;
  private sim: KairosSimulation;
  private onNumericTimerToggled?: (show: boolean) => void;

  constructor(container: HTMLElement, sim: KairosSimulation, onNumericTimerToggled?: (show: boolean) => void) {
    this.container = container;
    this.sim = sim;
    this.onNumericTimerToggled = onNumericTimerToggled;
    this.buildPanel();
  }

  toggle(): void {
    this.visible = !this.visible;
    this.panelEl.style.display = this.visible ? "block" : "none";
  }

  private buildPanel(): void {
    const t = TUNING.get();
    this.panelEl = document.createElement("div");
    this.panelEl.id = "kairos-tuning-panel";
    this.panelEl.style.cssText = `
      position:fixed; top:20px; right:20px; width:380px; max-height:88vh;
      background:rgba(15,23,42,0.95); border:2px solid #f59e0b; border-radius:10px;
      color:#e2e8f0; font-family:monospace; font-size:12px; z-index:999;
      display:none; box-shadow:0 0 24px rgba(0,0,0,0.8); overflow-y:auto; padding:20px;
    `;

    this.panelEl.innerHTML = `
      <div style="display:flex; justify-content:space-between; align-items:center; border-bottom:1px solid #334155; padding-bottom:10px; margin-bottom:14px;">
        <strong style="color:#f59e0b; font-size:14px;">KAIROS LIVE TUNER</strong>
        <button id="close-tuner-btn" style="background:none; border:none; color:#94a3b8; font-size:18px; cursor:pointer;">&times;</button>
      </div>

      <!-- Quick Action Buttons -->
      <div style="margin-bottom:16px;">
        <div style="color:#38bdf8; font-weight:bold; margin-bottom:6px;">QUICK ACTIONS</div>
        <div style="display:grid; grid-template-columns:1fr 1fr; gap:6px;">
          <button id="btn-grant-weight" style="background:#b45309; color:#fff; border:none; padding:6px; border-radius:4px; cursor:pointer;">+ Weight (Leadfall)</button>
          <button id="btn-grant-lift" style="background:#0284c7; color:#fff; border:none; padding:6px; border-radius:4px; cursor:pointer;">+ Lift (Skyreach)</button>
          <button id="btn-spawn-threat" style="background:#7c3aed; color:#fff; border:none; padding:6px; border-radius:4px; cursor:pointer;">Spawn Threat Boss</button>
          <button id="btn-trigger-overflow" style="background:#e11d48; color:#fff; border:none; padding:6px; border-radius:4px; cursor:pointer;">28:00 Overflow</button>
          <button id="btn-trigger-fade" style="background:#eab308; color:#000; font-weight:bold; border:none; padding:6px; border-radius:4px; cursor:pointer;">Trigger Fade</button>
          <button id="btn-trigger-threshold" style="background:#059669; color:#fff; border:none; padding:6px; border-radius:4px; cursor:pointer;">Threshold Choice</button>
        </div>
      </div>

      <!-- Jump Dimension -->
      <div style="margin-bottom:16px;">
        <div style="color:#38bdf8; font-weight:bold; margin-bottom:6px;">JUMP TO DIMENSION</div>
        <div style="display:flex; gap:6px; flex-wrap:wrap;">
          <button class="jump-btn" data-id="threshold" style="background:#334155; color:#fff; border:none; padding:5px 8px; border-radius:4px; cursor:pointer;">Threshold</button>
          <button class="jump-btn" data-id="leadfall" style="background:#334155; color:#fff; border:none; padding:5px 8px; border-radius:4px; cursor:pointer;">Leadfall</button>
          <button class="jump-btn" data-id="skyreach" style="background:#334155; color:#fff; border:none; padding:5px 8px; border-radius:4px; cursor:pointer;">Skyreach</button>
          <button class="jump-btn" data-id="corridor" style="background:#334155; color:#fff; border:none; padding:5px 8px; border-radius:4px; cursor:pointer;">Corridor</button>
          <button class="jump-btn" data-id="threat-node" style="background:#334155; color:#fff; border:none; padding:5px 8px; border-radius:4px; cursor:pointer;">Threat Arena</button>
        </div>
      </div>

      <!-- Clock Presets -->
      <div style="margin-bottom:16px;">
        <div style="color:#38bdf8; font-weight:bold; margin-bottom:6px;">CLOCK RUN DURATION</div>
        <div style="display:flex; gap:6px;">
          <button class="clock-preset-btn" data-sec="1800" style="flex:1; background:#334155; color:#fff; border:none; padding:5px; border-radius:4px; cursor:pointer;">30:00 (Full)</button>
          <button class="clock-preset-btn" data-sec="360" style="flex:1; background:#334155; color:#fff; border:none; padding:5px; border-radius:4px; cursor:pointer;">6:00 (Short)</button>
          <button class="clock-preset-btn" data-sec="120" style="flex:1; background:#334155; color:#fff; border:none; padding:5px; border-radius:4px; cursor:pointer;">2:00 (Quick)</button>
        </div>
      </div>

      <!-- Toggles -->
      <div style="margin-bottom:16px;">
        <div style="color:#38bdf8; font-weight:bold; margin-bottom:6px;">TOGGLES</div>
        <label style="display:block; margin-bottom:4px; cursor:pointer;">
          <input type="checkbox" id="toggle-numeric-timer"> Numeric Timer HUD
        </label>
        <label style="display:block; margin-bottom:4px; cursor:pointer;">
          <input type="checkbox" id="toggle-slowmo"> Slow Motion (0.25x)
        </label>
        <label style="display:block; margin-bottom:4px; cursor:pointer;">
          <input type="checkbox" id="toggle-replay"> Deterministic Replay Mode
        </label>
      </div>

      <!-- Sliders -->
      <div style="color:#38bdf8; font-weight:bold; margin-bottom:6px;">MOVEMENT & COMBAT TUNING</div>

      <div style="margin-bottom:8px;">
        <label>Run Speed: <span id="val-run-speed">${t.movement.runSpeed}</span></label>
        <input type="range" id="slider-run-speed" min="10" max="35" value="${t.movement.runSpeed}" style="width:100%;">
      </div>

      <div style="margin-bottom:8px;">
        <label>Flight Speed: <span id="val-flight-speed">${t.movement.flightSpeed}</span></label>
        <input type="range" id="slider-flight-speed" min="15" max="50" value="${t.movement.flightSpeed}" style="width:100%;">
      </div>

      <div style="margin-bottom:8px;">
        <label>Burst Speed: <span id="val-burst-speed">${t.movement.burstSpeed}</span></label>
        <input type="range" id="slider-burst-speed" min="30" max="110" value="${t.movement.burstSpeed}" style="width:100%;">
      </div>

      <div style="margin-bottom:8px;">
        <label>Heavy Launch Speed: <span id="val-launch-speed">${t.combat.heavyLaunchSpeed}</span></label>
        <input type="range" id="slider-launch-speed" min="20" max="90" value="${t.combat.heavyLaunchSpeed}" style="width:100%;">
      </div>

      <div style="margin-bottom:8px;">
        <label>Chase Window (s): <span id="val-chase-window">${t.combat.chaseWindowSeconds}</span></label>
        <input type="range" id="slider-chase-window" min="0.5" max="3.0" step="0.1" value="${t.combat.chaseWindowSeconds}" style="width:100%;">
      </div>

      <div style="margin-bottom:8px;">
        <label>Light Hit Cost (s): <span id="val-hit-light">${t.clock.lightHitCostSeconds}</span></label>
        <input type="range" id="slider-hit-light" min="0.5" max="10.0" step="0.5" value="${t.clock.lightHitCostSeconds}" style="width:100%;">
      </div>

      <div style="margin-bottom:8px;">
        <label>Heavy Hit Cost (s): <span id="val-hit-heavy">${t.clock.heavyHitCostSeconds}</span></label>
        <input type="range" id="slider-hit-heavy" min="1.0" max="20.0" step="0.5" value="${t.clock.heavyHitCostSeconds}" style="width:100%;">
      </div>
    `;

    this.container.appendChild(this.panelEl);
    this.wireListeners();
  }

  private wireListeners(): void {
    this.panelEl.querySelector("#close-tuner-btn")?.addEventListener("click", () => this.toggle());

    this.panelEl.querySelector("#btn-grant-weight")?.addEventListener("click", () => {
      this.sim.zenith.grantAdaptation("weight");
    });

    this.panelEl.querySelector("#btn-grant-lift")?.addEventListener("click", () => {
      this.sim.zenith.grantAdaptation("lift");
    });

    this.panelEl.querySelector("#btn-spawn-threat")?.addEventListener("click", () => {
      this.sim.spawnThreatBoss();
    });

    this.panelEl.querySelector("#btn-trigger-overflow")?.addEventListener("click", () => {
      this.sim.clock.state.inOverflow = true;
      this.sim.clock.state.elapsedSeconds = this.sim.clock.state.totalDurationSeconds * 0.94;
    });

    this.panelEl.querySelector("#btn-trigger-fade")?.addEventListener("click", () => {
      this.sim.clock.triggerFadeDissolve();
    });

    this.panelEl.querySelector("#btn-trigger-threshold")?.addEventListener("click", () => {
      this.sim.clock.state.thresholdReached[0] = false;
      this.sim.clock.state.elapsedSeconds = TUNING.get().clock.threshold1Seconds;
    });

    this.panelEl.querySelectorAll(".jump-btn").forEach((btn) => {
      btn.addEventListener("click", (e) => {
        const id = (e.currentTarget as HTMLElement).getAttribute("data-id") as DimensionId;
        this.sim.loadDimension(id);
      });
    });

    this.panelEl.querySelectorAll(".clock-preset-btn").forEach((btn) => {
      btn.addEventListener("click", (e) => {
        const sec = Number((e.currentTarget as HTMLElement).getAttribute("data-sec"));
        TUNING.setRunDuration(sec);
        this.sim.reset(this.sim.seed, sec);
      });
    });

    // Toggles
    const toggleTimer = this.panelEl.querySelector("#toggle-numeric-timer") as HTMLInputElement;
    toggleTimer?.addEventListener("change", (e) => {
      this.onNumericTimerToggled?.((e.target as HTMLInputElement).checked);
    });

    const toggleSlowmo = this.panelEl.querySelector("#toggle-slowmo") as HTMLInputElement;
    toggleSlowmo?.addEventListener("change", (e) => {
      (window as any).KAIROS_SLOWMO = (e.target as HTMLInputElement).checked;
    });

    const toggleReplay = this.panelEl.querySelector("#toggle-replay") as HTMLInputElement;
    toggleReplay?.addEventListener("change", (e) => {
      const active = (e.target as HTMLInputElement).checked;
      if (active) {
        const data = this.sim.recorder.exportData();
        this.sim.replayer.load(data);
        this.sim.reset(data.seed, data.runDurationSeconds);
        this.sim.replayer.active = true;
      } else {
        this.sim.replayer.stop();
      }
    });

    // Sliders
    this.wireSlider("slider-run-speed", "val-run-speed", (val) => {
      TUNING.update((t) => (t.movement.runSpeed = val));
    });
    this.wireSlider("slider-flight-speed", "val-flight-speed", (val) => {
      TUNING.update((t) => (t.movement.flightSpeed = val));
    });
    this.wireSlider("slider-burst-speed", "val-burst-speed", (val) => {
      TUNING.update((t) => (t.movement.burstSpeed = val));
    });
    this.wireSlider("slider-launch-speed", "val-launch-speed", (val) => {
      TUNING.update((t) => (t.combat.heavyLaunchSpeed = val));
    });
    this.wireSlider("slider-chase-window", "val-chase-window", (val) => {
      TUNING.update((t) => (t.combat.chaseWindowSeconds = val));
    });
    this.wireSlider("slider-hit-light", "val-hit-light", (val) => {
      TUNING.update((t) => (t.clock.lightHitCostSeconds = val));
    });
    this.wireSlider("slider-hit-heavy", "val-hit-heavy", (val) => {
      TUNING.update((t) => (t.clock.heavyHitCostSeconds = val));
    });
  }

  private wireSlider(sliderId: string, labelId: string, onChange: (val: number) => void): void {
    const slider = this.panelEl.querySelector(`#${sliderId}`) as HTMLInputElement;
    const label = this.panelEl.querySelector(`#${labelId}`) as HTMLElement;
    slider?.addEventListener("input", () => {
      const val = Number(slider.value);
      label.innerText = String(val);
      onChange(val);
    });
  }
}

import type { KairosSimulation } from "../sim/KairosSimulation.js";
import type { DimensionId, LegacyRunSummary, ThresholdOption } from "../sim/types.js";

export class KairosHUD {
  public container: HTMLElement;
  public showNumericTimer: boolean = false;
  private timerEl!: HTMLElement;
  private kiEl!: HTMLElement;
  private kiFillEl!: HTMLElement;
  private comboEl!: HTMLElement;
  private comboCountEl!: HTMLElement;
  private comboVerbsEl!: HTMLElement;
  private dimensionBadgeEl!: HTMLElement;
  private toyingBannerEl!: HTMLElement;

  // Modals
  private mapModalEl!: HTMLElement;
  private thresholdModalEl!: HTMLElement;
  private legacyModalEl!: HTMLElement;
  private codexModalEl!: HTMLElement;

  public onTravelRequested?: (dimensionId: DimensionId, instant: boolean) => void;
  public onThresholdSelected?: (option: ThresholdOption) => void;
  public onRestartRequested?: () => void;
  public onReplayRequested?: () => void;

  constructor(container: HTMLElement) {
    this.container = container;
    this.buildHUD();
  }

  private buildHUD(): void {
    this.container.innerHTML = `
      <!-- Top Left: Dimension & Clock -->
      <div id="hud-top-left" style="position:absolute; top:20px; left:24px; color:#fff; font-family:sans-serif; pointer-events:auto; z-index:10;">
        <div id="dim-badge" style="font-size:14px; font-weight:700; letter-spacing:2px; text-transform:uppercase; color:#00f0ff; background:rgba(12,14,23,0.85); padding:6px 14px; border-radius:4px; border-left:3px solid #00f0ff; display:inline-block; margin-bottom:8px;">
          The Threshold
        </div>
        <div id="numeric-timer" style="font-size:24px; font-weight:800; font-variant-numeric:tabular-nums; color:#ffe680; display:none; background:rgba(0,0,0,0.6); padding:4px 10px; border-radius:4px;">
          30:00
        </div>
      </div>

      <!-- Top Right: Navigation Buttons -->
      <div id="hud-top-right" style="position:absolute; top:20px; right:24px; display:flex; gap:10px; z-index:10; pointer-events:auto;">
        <button id="btn-open-map" style="background:#1e293b; color:#38bdf8; border:1px solid #0284c7; padding:8px 16px; border-radius:6px; font-weight:700; cursor:pointer;">
          Multiverse Map (M)
        </button>
        <button id="btn-open-codex" style="background:#1e293b; color:#e2e8f0; border:1px solid #475569; padding:8px 14px; border-radius:6px; font-weight:600; cursor:pointer;">
          Codex
        </button>
        <button id="btn-toggle-tuner" style="background:#0f172a; color:#f59e0b; border:1px solid #d97706; padding:8px 14px; border-radius:6px; font-weight:700; cursor:pointer;">
          Tuning (~/Tab)
        </button>
      </div>

      <!-- Bottom Center: Ki Bar & State -->
      <div id="hud-bottom-center" style="position:absolute; bottom:28px; left:50%; transform:translateX(-50%); width:380px; text-align:center; pointer-events:none; z-index:10;">
        <div style="display:flex; justify-content:space-between; font-size:12px; font-weight:700; letter-spacing:1.5px; color:#94a3b8; margin-bottom:4px; font-family:sans-serif;">
          <span>KI ENERGY</span>
          <span id="ki-text">100 / 100</span>
        </div>
        <div style="width:100%; height:10px; background:rgba(15,23,42,0.8); border:1px solid rgba(56,189,248,0.4); border-radius:6px; overflow:hidden;">
          <div id="ki-bar-fill" style="width:100%; height:100%; background:linear-gradient(90deg, #0284c7, #38bdf8, #f43f5e); transition:width 0.08s ease-out;"></div>
        </div>
        <div id="combo-verbs-active" style="margin-top:6px; font-size:11px; font-weight:600; color:#38bdf8; letter-spacing:1px; height:16px;"></div>
      </div>

      <!-- Center Left: Combo Counter & Toying Bonus -->
      <div id="hud-combo-container" style="position:absolute; top:35%; left:36px; pointer-events:none; z-index:10; font-family:sans-serif; opacity:0; transition:opacity 0.2s;">
        <div id="combo-count" style="font-size:48px; font-weight:900; color:#fff; text-shadow:0 0 16px rgba(0,240,255,0.8); font-style:italic;">
          0
        </div>
        <div style="font-size:14px; font-weight:800; letter-spacing:2px; color:#38bdf8;">COMBO</div>
        <div id="toying-banner" style="display:none; margin-top:8px; background:linear-gradient(90deg, #ec4899, #f43f5e); color:#fff; font-size:12px; font-weight:900; padding:4px 10px; border-radius:4px; letter-spacing:1.5px; box-shadow:0 0 12px rgba(244,63,94,0.8);">
          TOYING BONUS +500 XP
        </div>
      </div>

      <!-- Controls Cheat-Sheet Bottom Left -->
      <div style="position:absolute; bottom:20px; left:24px; color:#64748b; font-size:11px; font-family:sans-serif; pointer-events:none; z-index:5;">
        [A/D] Run &bull; [W/Space] Jump &bull; [W/S/A/D in air] Flight &bull; [Shift] Burst &bull; [Space] Transmission &bull; [J] Light (x3) &bull; [K] Heavy Launch &bull; [L] Guard &bull; [U] Ki Volley &bull; [I] Charge Beam &bull; [O] Burst Field
      </div>

      <!-- Modals Container -->
      <div id="modals-root" style="pointer-events:auto;"></div>
    `;

    this.timerEl = this.container.querySelector("#numeric-timer")!;
    this.kiEl = this.container.querySelector("#ki-text")!;
    this.kiFillEl = this.container.querySelector("#ki-bar-fill")!;
    this.comboEl = this.container.querySelector("#hud-combo-container")!;
    this.comboCountEl = this.container.querySelector("#combo-count")!;
    this.comboVerbsEl = this.container.querySelector("#combo-verbs-active")!;
    this.dimensionBadgeEl = this.container.querySelector("#dim-badge")!;
    this.toyingBannerEl = this.container.querySelector("#toying-banner")!;

    // Wire buttons
    this.container.querySelector("#btn-open-map")?.addEventListener("click", () => this.toggleMapModal(true));
    this.container.querySelector("#btn-open-codex")?.addEventListener("click", () => this.toggleCodexModal(true));
  }

  update(sim: KairosSimulation): void {
    const clock = sim.clock.state;
    const zenith = sim.zenith;
    const dim = sim.dimensions.getCurrent();

    // 1. Numeric Timer
    if (this.showNumericTimer) {
      this.timerEl.style.display = "block";
      const totalSec = Math.ceil(clock.remainingSeconds);
      const mins = Math.floor(totalSec / 60);
      const secs = totalSec % 60;
      this.timerEl.innerText = `${mins.toString().padStart(2, "0")}:${secs.toString().padStart(2, "0")}`;
      if (clock.inOverflow) {
        this.timerEl.style.color = "#f43f5e";
      } else {
        this.timerEl.style.color = "#ffe680";
      }
    } else {
      this.timerEl.style.display = "none";
    }

    // 2. Dimension Badge
    let markSuffix = dim.marked ? " [MARKED]" : "";
    let adaptSuffix = dim.adapted ? " (ADAPTED)" : ` (${Math.round((dim.exposureMeter / dim.exposureMax) * 100)}%)`;
    this.dimensionBadgeEl.innerText = `${dim.definition.name}${markSuffix} ${adaptSuffix}`;

    // 3. Ki Bar
    this.kiEl.innerText = `${Math.round(zenith.ki)} / ${zenith.maxKi}`;
    this.kiFillEl.style.width = `${(zenith.ki / zenith.maxKi) * 100}%`;

    // 4. Combo Counter & Toying Bonus
    if (zenith.comboCount > 0) {
      this.comboEl.style.opacity = "1";
      this.comboCountEl.innerText = `${zenith.comboCount}`;
      const verbs = Array.from(zenith.comboVerbs).join(" &bull; ");
      this.comboVerbsEl.innerHTML = verbs;

      if (zenith.toyingBonusAwarded) {
        this.toyingBannerEl.style.display = "inline-block";
      } else {
        this.toyingBannerEl.style.display = "none";
      }
    } else {
      this.comboEl.style.opacity = "0";
      this.comboVerbsEl.innerText = "";
      this.toyingBannerEl.style.display = "none";
    }

    // Check if legacy summary is ready
    if (sim.legacySummary && !this.legacyModalEl) {
      this.showLegacyModal(sim.legacySummary);
    }
  }

  toggleMapModal(show: boolean, sim?: KairosSimulation): void {
    const root = this.container.querySelector("#modals-root")!;
    if (!show) {
      if (this.mapModalEl) {
        root.removeChild(this.mapModalEl);
        (this.mapModalEl as any) = null;
      }
      return;
    }

    if (this.mapModalEl) return;

    const modal = document.createElement("div");
    modal.id = "map-modal";
    modal.style.cssText = `
      position:fixed; top:0; left:0; width:100%; height:100%;
      background:rgba(8,10,18,0.88); backdrop-filter:blur(8px);
      display:flex; justify-content:center; align-items:center; z-index:100;
      font-family:sans-serif; color:#fff;
    `;

    modal.innerHTML = `
      <div style="background:#0f172a; border:2px solid #0284c7; border-radius:12px; width:720px; max-width:92%; padding:32px; box-shadow:0 0 32px rgba(2,132,199,0.4); position:relative;">
        <button id="close-map-btn" style="position:absolute; top:16px; right:16px; background:none; border:none; color:#94a3b8; font-size:24px; cursor:pointer;">&times;</button>
        <h2 style="margin:0 0 6px 0; font-size:24px; color:#38bdf8; letter-spacing:1px;">MULTIVERSE NODE MAP</h2>
        <p style="margin:0 0 24px 0; font-size:13px; color:#94a3b8;">Select a destination to travel. Instant transmission costs 5 seconds of clock; flight through the corridor is free.</p>

        <div style="display:grid; grid-template-columns:1fr 1fr; gap:16px; margin-bottom:24px;">
          <!-- Threshold -->
          <div style="background:#1e293b; padding:18px; border-radius:8px; border:1px solid #334155;">
            <div style="display:flex; justify-content:space-between; align-items:center;">
              <h3 style="margin:0; font-size:16px; color:#e2e8f0;">The Threshold</h3>
              <span style="font-size:11px; background:#0369a1; padding:2px 8px; border-radius:10px;">Band 1</span>
            </div>
            <p style="font-size:12px; color:#94a3b8; margin:8px 0 14px 0;">Skyline city. Standard rules. Swarm fodder and ranged blaster.</p>
            <div style="display:flex; gap:8px;">
              <button class="travel-btn" data-id="threshold" data-instant="true" style="flex:1; background:#0284c7; color:#fff; border:none; padding:8px; border-radius:4px; font-weight:700; cursor:pointer;">Warp (5s)</button>
              <button class="travel-btn" data-id="threshold" data-instant="false" style="flex:1; background:#334155; color:#cbd5e1; border:none; padding:8px; border-radius:4px; font-weight:600; cursor:pointer;">Fly (Free)</button>
            </div>
          </div>

          <!-- Leadfall -->
          <div style="background:#1e293b; padding:18px; border-radius:8px; border:1px solid #334155;">
            <div style="display:flex; justify-content:space-between; align-items:center;">
              <h3 style="margin:0; font-size:16px; color:#f97316;">Leadfall</h3>
              <span style="font-size:11px; background:#b45309; padding:2px 8px; border-radius:10px;">Band 2</span>
            </div>
            <p style="font-size:12px; color:#94a3b8; margin:8px 0 14px 0;">Heavy gravity foundry. Armored brutes with ground slams. Adaptation: Weight.</p>
            <div style="display:flex; gap:8px;">
              <button class="travel-btn" data-id="leadfall" data-instant="true" style="flex:1; background:#ea580c; color:#fff; border:none; padding:8px; border-radius:4px; font-weight:700; cursor:pointer;">Warp (5s)</button>
              <button class="travel-btn" data-id="leadfall" data-instant="false" style="flex:1; background:#334155; color:#cbd5e1; border:none; padding:8px; border-radius:4px; font-weight:600; cursor:pointer;">Fly (Free)</button>
            </div>
          </div>

          <!-- Skyreach -->
          <div style="background:#1e293b; padding:18px; border-radius:8px; border:1px solid #334155;">
            <div style="display:flex; justify-content:space-between; align-items:center;">
              <h3 style="margin:0; font-size:16px; color:#38bdf8;">Skyreach</h3>
              <span style="font-size:11px; background:#0369a1; padding:2px 8px; border-radius:10px;">Band 2</span>
            </div>
            <p style="font-size:12px; color:#94a3b8; margin:8px 0 14px 0;">Open sky with no floor. Flying enemies. Adaptation: Lift. [Weight grounds flyers!]</p>
            <div style="display:flex; gap:8px;">
              <button class="travel-btn" data-id="skyreach" data-instant="true" style="flex:1; background:#0284c7; color:#fff; border:none; padding:8px; border-radius:4px; font-weight:700; cursor:pointer;">Warp (5s)</button>
              <button class="travel-btn" data-id="skyreach" data-instant="false" style="flex:1; background:#334155; color:#cbd5e1; border:none; padding:8px; border-radius:4px; font-weight:600; cursor:pointer;">Fly (Free)</button>
            </div>
          </div>

          <!-- Threat Rupture -->
          <div style="background:#2e1065; padding:18px; border-radius:8px; border:1px solid #7c3aed;">
            <div style="display:flex; justify-content:space-between; align-items:center;">
              <h3 style="margin:0; font-size:16px; color:#e879f9;">Threat Rupture</h3>
              <span style="font-size:11px; background:#9333ea; padding:2px 8px; border-radius:10px;">Apex Boss</span>
            </div>
            <p style="font-size:12px; color:#c084fc; margin:8px 0 14px 0;">Early hunt challenge (unlocked at 20:00 or now). Slay the Threat before the fade!</p>
            <div style="display:flex; gap:8px;">
              <button class="travel-btn" data-id="threat-node" data-instant="true" style="flex:1; background:#a855f7; color:#fff; border:none; padding:8px; border-radius:4px; font-weight:700; cursor:pointer;">Hunt Threat</button>
            </div>
          </div>
        </div>
      </div>
    `;

    modal.querySelector("#close-map-btn")?.addEventListener("click", () => this.toggleMapModal(false));
    modal.querySelectorAll(".travel-btn").forEach((btn) => {
      btn.addEventListener("click", (e) => {
        const target = e.currentTarget as HTMLElement;
        const id = target.getAttribute("data-id") as DimensionId;
        const instant = target.getAttribute("data-instant") === "true";
        this.onTravelRequested?.(id, instant);
        this.toggleMapModal(false);
      });
    });

    root.appendChild(modal);
    this.mapModalEl = modal;
  }

  showThresholdModal(thresholdIndex: number, options: ThresholdOption[]): void {
    const root = this.container.querySelector("#modals-root")!;
    if (this.thresholdModalEl) {
      root.removeChild(this.thresholdModalEl);
    }

    const modal = document.createElement("div");
    modal.style.cssText = `
      position:fixed; top:0; left:0; width:100%; height:100%;
      background:rgba(15,23,42,0.92); backdrop-filter:blur(10px);
      display:flex; justify-content:center; align-items:center; z-index:110;
      font-family:sans-serif; color:#fff;
    `;

    const titles = ["10:00 THRESHOLD REACHED", "20:00 THRESHOLD REACHED", "28:00 OVERFLOW THRESHOLD"];
    const colors = ["#38bdf8", "#f59e0b", "#f43f5e"];

    let cardsHtml = "";
    options.forEach((opt, idx) => {
      cardsHtml += `
        <div class="threshold-card" data-idx="${idx}" style="background:#1e293b; border:2px solid #334155; border-radius:10px; padding:24px; cursor:pointer; transition:all 0.15s; display:flex; flex-direction:column; justify-content:space-between;">
          <div>
            <div style="font-size:11px; text-transform:uppercase; letter-spacing:1.5px; color:#38bdf8; margin-bottom:8px;">${opt.category}</div>
            <h3 style="margin:0 0 10px 0; font-size:18px; color:#fff;">${opt.title}</h3>
            <p style="margin:0; font-size:13px; color:#94a3b8; line-height:1.5;">${opt.description}</p>
          </div>
          <button style="margin-top:20px; width:100%; background:#0284c7; color:#fff; border:none; padding:10px; border-radius:6px; font-weight:700; cursor:pointer;">Absorb Upgrade</button>
        </div>
      `;
    });

    modal.innerHTML = `
      <div style="width:840px; max-width:94%; text-align:center;">
        <h1 style="margin:0 0 8px 0; font-size:28px; color:${colors[thresholdIndex]}; letter-spacing:2px;">${titles[thresholdIndex]}</h1>
        <p style="margin:0 0 32px 0; font-size:14px; color:#94a3b8;">The vessel expands. Select one power modification to assimilate:</p>
        <div style="display:grid; grid-template-columns:repeat(3, 1fr); gap:18px; text-align:left;">
          ${cardsHtml}
        </div>
      </div>
    `;

    modal.querySelectorAll(".threshold-card").forEach((card) => {
      card.addEventListener("click", (e) => {
        const target = e.currentTarget as HTMLElement;
        const idx = Number(target.getAttribute("data-idx"));
        const chosen = options[idx];
        if (chosen) {
          chosen.apply();
          this.onThresholdSelected?.(chosen);
        }
        root.removeChild(modal);
        (this.thresholdModalEl as any) = null;
      });
    });

    root.appendChild(modal);
    this.thresholdModalEl = modal;
  }

  toggleCodexModal(show: boolean): void {
    const root = this.container.querySelector("#modals-root")!;
    if (!show) {
      if (this.codexModalEl) {
        root.removeChild(this.codexModalEl);
        (this.codexModalEl as any) = null;
      }
      return;
    }

    if (this.codexModalEl) return;

    const modal = document.createElement("div");
    modal.style.cssText = `
      position:fixed; top:0; left:0; width:100%; height:100%;
      background:rgba(8,10,18,0.9); backdrop-filter:blur(8px);
      display:flex; justify-content:center; align-items:center; z-index:100;
      font-family:sans-serif; color:#fff;
    `;

    modal.innerHTML = `
      <div style="background:#0f172a; border:2px solid #e2e8f0; border-radius:12px; width:640px; max-width:92%; padding:32px; position:relative;">
        <button id="close-codex-btn" style="position:absolute; top:16px; right:16px; background:none; border:none; color:#94a3b8; font-size:24px; cursor:pointer;">&times;</button>
        <h2 style="margin:0 0 6px 0; font-size:24px; color:#f8fafc; letter-spacing:1px;">CODEX OF THE MULTIVERSE</h2>
        <p style="margin:0 0 24px 0; font-size:13px; color:#94a3b8;">Insights and systemic interactions discovered across all runs.</p>

        <div style="background:#1e293b; padding:16px; border-radius:8px; margin-bottom:14px;">
          <h4 style="margin:0 0 4px 0; color:#38bdf8;">Technique: Warp Beam</h4>
          <p style="margin:0; font-size:12px; color:#94a3b8;">Fire a beam during or immediately after combat transmission 3 times to unlock instant Warp Beam execution.</p>
        </div>

        <div style="background:#1e293b; padding:16px; border-radius:8px; margin-bottom:14px;">
          <h4 style="margin:0 0 4px 0; color:#f97316;">Mark: Gravity into Skyreach</h4>
          <p style="margin:0; font-size:12px; color:#94a3b8;">Entering Skyreach with the Leadfall Weight adaptation subjects all flyers to gravity, grounding them for combat.</p>
        </div>

        <div style="background:#1e293b; padding:16px; border-radius:8px;">
          <h4 style="margin:0 0 4px 0; color:#e2e8f0;">Vessel: The 30-Minute Life</h4>
          <p style="margin:0; font-size:12px; color:#94a3b8;">Zenith exists for 30 minutes. Time is health; time never refills. Every run ends in the fade at peak power.</p>
        </div>
      </div>
    `;

    modal.querySelector("#close-codex-btn")?.addEventListener("click", () => this.toggleCodexModal(false));
    root.appendChild(modal);
    this.codexModalEl = modal;
  }

  showLegacyModal(summary: LegacyRunSummary): void {
    const root = this.container.querySelector("#modals-root")!;
    if (this.legacyModalEl) return;

    const modal = document.createElement("div");
    modal.style.cssText = `
      position:fixed; top:0; left:0; width:100%; height:100%;
      background:rgba(5,7,12,0.96); backdrop-filter:blur(12px);
      display:flex; justify-content:center; align-items:center; z-index:200;
      font-family:sans-serif; color:#fff;
    `;

    const mins = Math.floor(summary.elapsedSeconds / 60);
    const secs = Math.floor(summary.elapsedSeconds % 60);

    let marksList = summary.dimensionsMarked.map((m) => `<li><strong>${m.dimensionId}:</strong> ${m.description}</li>`).join("");
    if (!marksList) marksList = "<li>None</li>";

    modal.innerHTML = `
      <div style="background:#090d16; border:2px solid #facc15; border-radius:12px; width:680px; max-width:92%; padding:36px; box-shadow:0 0 40px rgba(250,204,21,0.3); text-align:center;">
        <h1 style="margin:0 0 6px 0; font-size:32px; color:#fef08a; letter-spacing:3px;">THE FADE</h1>
        <p style="font-size:16px; font-style:italic; color:#e2e8f0; margin:12px 0 28px 0;">"${summary.fadeLineSpoken}"</p>

        <div style="display:grid; grid-template-columns:1fr 1fr; gap:16px; text-align:left; background:#131b2e; padding:20px; border-radius:8px; margin-bottom:24px;">
          <div>
            <div style="font-size:11px; color:#94a3b8; text-transform:uppercase;">Time Elapsed</div>
            <div style="font-size:20px; font-weight:800; color:#fff;">${mins}m ${secs}s</div>
          </div>
          <div>
            <div style="font-size:11px; color:#94a3b8; text-transform:uppercase;">Peak Power Multiplier</div>
            <div style="font-size:20px; font-weight:800; color:#38bdf8;">${summary.peakPowerMultiplier.toFixed(2)}x</div>
          </div>
          <div>
            <div style="font-size:11px; color:#94a3b8; text-transform:uppercase;">The Threat Outcome</div>
            <div style="font-size:18px; font-weight:700; color:${summary.threatDefeated ? "#4ade80" : "#f87171"};">
              ${summary.threatDefeated ? `Defeated (${Math.floor(summary.threatDefeatedAtSeconds ?? 0)}s)` : "Dissolved in Fade Fight"}
            </div>
          </div>
          <div>
            <div style="font-size:11px; color:#94a3b8; text-transform:uppercase;">Enemies Slayed / Max Combo</div>
            <div style="font-size:18px; font-weight:700; color:#fff;">${summary.enemiesDefeated} / ${summary.maxCombo}x</div>
          </div>
        </div>

        <div style="text-align:left; background:#131b2e; padding:16px; border-radius:8px; margin-bottom:28px; font-size:12px; color:#cbd5e1;">
          <div style="font-weight:700; color:#38bdf8; margin-bottom:6px;">Dimensions Marked on Multiverse:</div>
          <ul style="margin:0; padding-left:18px; line-height:1.6;">${marksList}</ul>
          <div style="margin-top:10px; color:#94a3b8;">Run Seed: <code>${summary.seed}</code></div>
        </div>

        <div style="display:flex; gap:12px; justify-content:center;">
          <button id="restart-run-btn" style="background:#eab308; color:#000; font-weight:800; font-size:15px; border:none; padding:12px 28px; border-radius:6px; cursor:pointer;">
            New Run
          </button>
          <button id="replay-run-btn" style="background:#1e293b; color:#38bdf8; border:1px solid #0284c7; font-weight:700; font-size:15px; padding:12px 24px; border-radius:6px; cursor:pointer;">
            Watch Replay
          </button>
        </div>
      </div>
    `;

    modal.querySelector("#restart-run-btn")?.addEventListener("click", () => {
      root.removeChild(modal);
      (this.legacyModalEl as any) = null;
      this.onRestartRequested?.();
    });

    modal.querySelector("#replay-run-btn")?.addEventListener("click", () => {
      root.removeChild(modal);
      (this.legacyModalEl as any) = null;
      this.onReplayRequested?.();
    });

    root.appendChild(modal);
    this.legacyModalEl = modal;
  }
}

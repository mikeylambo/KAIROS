import * as THREE from "three";
import type { KairosSimulation } from "../sim/KairosSimulation.js";
import type { EnemyState, Projectile, TerrainPlatform } from "../sim/types.js";
import { KairosImpactBridge } from "./ImpactBridge.js";
import { ZenithVisual } from "./ZenithModel.js";

export class KairosRenderer {
  public scene: THREE.Scene;
  public camera: THREE.PerspectiveCamera;
  public renderer: THREE.WebGLRenderer;
  public impactBridge: KairosImpactBridge;

  // Visual actors
  public zenithVisual: ZenithVisual;
  private platformMeshes: Map<string, THREE.Mesh> = new Map();
  private enemyMeshes: Map<string, THREE.Group> = new Map();
  private projectileMeshes: Map<string, THREE.Mesh> = new Map();
  private afterimageMeshes: THREE.Mesh[] = [];

  // Parallax background group
  private backgroundGroup: THREE.Group;
  private backgroundObjects: THREE.Object3D[] = [];

  // Lights
  private ambientLight: THREE.AmbientLight;
  private dirLight: THREE.DirectionalLight;
  private rimPointLight: THREE.PointLight;

  // Camera tracking
  private cameraPos = new THREE.Vector3(0, 5, 22);
  private cameraTarget = new THREE.Vector3(0, 5, 0);

  // Overlay canvas for speed lines & impact frames
  public overlayCanvas: HTMLCanvasElement;
  private overlayCtx: CanvasRenderingContext2D | null;

  constructor(canvas: HTMLCanvasElement, overlayCanvas: HTMLCanvasElement) {
    this.overlayCanvas = overlayCanvas;
    this.overlayCtx = overlayCanvas.getContext("2d");

    // WebGL Renderer
    this.renderer = new THREE.WebGLRenderer({
      canvas,
      antialias: true,
      powerPreference: "high-performance"
    });
    this.renderer.setSize(window.innerWidth, window.innerHeight);
    this.renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
    this.renderer.toneMapping = THREE.ACESFilmicToneMapping;
    this.renderer.toneMappingExposure = 1.15;

    // Scene & Camera (2.5D perspective)
    this.scene = new THREE.Scene();
    this.scene.background = new THREE.Color(0x0c0d14);

    this.camera = new THREE.PerspectiveCamera(
      52,
      window.innerWidth / window.innerHeight,
      0.1,
      200
    );
    this.camera.position.set(0, 5, 22);

    // Impact Bridge
    this.impactBridge = new KairosImpactBridge();

    // Lighting
    this.ambientLight = new THREE.AmbientLight(0xffffff, 0.7);
    this.scene.add(this.ambientLight);

    this.dirLight = new THREE.DirectionalLight(0xfff8e7, 1.2);
    this.dirLight.position.set(10, 25, 18);
    this.scene.add(this.dirLight);

    this.rimPointLight = new THREE.PointLight(0x00ffff, 1.5, 30);
    this.scene.add(this.rimPointLight);

    // Background group
    this.backgroundGroup = new THREE.Group();
    this.scene.add(this.backgroundGroup);

    // Zenith Visual
    this.zenithVisual = new ZenithVisual();
    this.scene.add(this.zenithVisual.group);

    this.handleResize();
    window.addEventListener("resize", () => this.handleResize());
  }

  handleResize(): void {
    const w = window.innerWidth;
    const h = window.innerHeight;
    this.camera.aspect = w / h;
    this.camera.updateProjectionMatrix();
    this.renderer.setSize(w, h);

    this.overlayCanvas.width = w;
    this.overlayCanvas.height = h;
  }

  rebuildEnvironment(sim: KairosSimulation): void {
    const dim = sim.dimensions.getCurrent().definition;

    // Remove existing platforms
    for (const mesh of this.platformMeshes.values()) {
      this.scene.remove(mesh);
    }
    this.platformMeshes.clear();

    // Clear background
    while (this.backgroundGroup.children.length > 0) {
      this.backgroundGroup.remove(this.backgroundGroup.children[0]);
    }
    this.backgroundObjects = [];

    // Theme colors
    let groundColor = 0x222633;
    let bgColor = 0x0c0e17;

    switch (dim.theme) {
      case "dusk-city":
        bgColor = 0x110f22;
        groundColor = 0x232438;
        this.scene.fog = new THREE.FogExp2(0x110f22, 0.015);
        this.buildDuskCityBackground();
        break;
      case "rust-iron":
        bgColor = 0x160f0d;
        groundColor = 0x3d2822;
        this.scene.fog = new THREE.FogExp2(0x160f0d, 0.018);
        this.buildLeadfallFoundryBackground();
        break;
      case "pale-sky":
        bgColor = 0x6e8fa8;
        groundColor = 0xdbe7f0;
        this.scene.fog = new THREE.FogExp2(0x6e8fa8, 0.012);
        this.buildSkyreachBackground();
        break;
      case "void-corridor":
        bgColor = 0x080410;
        groundColor = 0x2a1645;
        this.scene.fog = new THREE.FogExp2(0x080410, 0.02);
        this.buildVoidCorridorBackground();
        break;
    }

    this.scene.background = new THREE.Color(bgColor);

    // Build platform meshes
    for (const plat of sim.world.platforms) {
      const w = plat.aabb.maxX - plat.aabb.minX;
      const h = plat.aabb.maxY - plat.aabb.minY;
      const d = 3.5; // Depth along Z for 2.5D look

      const geo = new THREE.BoxGeometry(w, h, d);
      const mat = new THREE.MeshStandardMaterial({
        color: plat.type === "breakable" ? 0x8a5438 : groundColor,
        roughness: 0.8,
        metalness: dim.theme === "rust-iron" ? 0.4 : 0.1
      });

      const mesh = new THREE.Mesh(geo, mat);
      mesh.position.set(
        (plat.aabb.minX + plat.aabb.maxX) * 0.5,
        (plat.aabb.minY + plat.aabb.maxY) * 0.5,
        0
      );
      this.scene.add(mesh);
      this.platformMeshes.set(plat.id, mesh);
    }
  }

  private buildDuskCityBackground(): void {
    // Distant city silhouette skyscrapers
    const mat = new THREE.MeshBasicMaterial({ color: 0x1b1933 });
    for (let i = -10; i <= 10; i++) {
      const height = 15 + Math.abs(i * 3) % 18;
      const geo = new THREE.BoxGeometry(5.5, height, 4);
      const bldg = new THREE.Mesh(geo, mat);
      bldg.position.set(i * 7, height * 0.5 - 2, -18);
      this.backgroundGroup.add(bldg);
      this.backgroundObjects.push(bldg);
    }
  }

  private buildLeadfallFoundryBackground(): void {
    // Massive furnace pipes and rust pillars
    const mat = new THREE.MeshStandardMaterial({ color: 0x2e1a14, roughness: 0.9 });
    for (let i = -8; i <= 8; i += 2) {
      const geo = new THREE.CylinderGeometry(1.4, 2.2, 40, 12);
      const pillar = new THREE.Mesh(geo, mat);
      pillar.position.set(i * 10, 15, -15);
      this.backgroundGroup.add(pillar);
      this.backgroundObjects.push(pillar);
    }
  }

  private buildSkyreachBackground(): void {
    // Floating distant sky monoliths & sun halo
    const mat = new THREE.MeshStandardMaterial({ color: 0xc4d8e8, roughness: 0.5 });
    for (let i = -6; i <= 6; i++) {
      const geo = new THREE.OctahedronGeometry(3.5, 0);
      const rock = new THREE.Mesh(geo, mat);
      rock.position.set(i * 12, 10 + (i % 3) * 6, -20);
      rock.rotation.set(0.3 * i, 0.5 * i, 0);
      this.backgroundGroup.add(rock);
      this.backgroundObjects.push(rock);
    }
  }

  private buildVoidCorridorBackground(): void {
    // Hyper-dimensional speed rings
    const ringMat = new THREE.MeshBasicMaterial({ color: 0x00f0ff, wireframe: true });
    for (let i = -10; i <= 10; i++) {
      const geo = new THREE.TorusGeometry(12, 0.3, 8, 24);
      const ring = new THREE.Mesh(geo, ringMat);
      ring.position.set(i * 10, 10, -12);
      this.backgroundGroup.add(ring);
      this.backgroundObjects.push(ring);
    }
  }

  render(sim: KairosSimulation, dt: number): void {
    // Process simulation events into Impact Bridge
    const events = sim.drainEvents();
    for (const ev of events) {
      this.processSimulationEvent(ev, sim);
    }

    this.impactBridge.update(dt);

    // 1. Update Zenith Visual
    const z = sim.zenith;
    this.zenithVisual.update(
      z.pos.x,
      z.pos.y,
      z.facing,
      z.bankAngle,
      sim.clock.state,
      z.vel.x,
      z.vel.y,
      dt
    );

    this.rimPointLight.position.set(z.pos.x, z.pos.y + 1.2, 2.5);

    // 2. Camera Tracking with Lead-Ahead and Screenshake
    const leadX = z.vel.x * 0.22;
    const leadY = z.vel.y * 0.12;
    const targetCamX = z.pos.x + leadX;
    const targetCamY = Math.max(4.0, z.pos.y + leadY + 1.5);

    this.cameraPos.x += (targetCamX - this.cameraPos.x) * Math.min(1.0, 6.0 * dt);
    this.cameraPos.y += (targetCamY - this.cameraPos.y) * Math.min(1.0, 5.0 * dt);

    // Apply screenshake & punch zoom
    const shake = this.impactBridge.screenShake;
    const shakeOffsetX = (Math.random() - 0.5) * shake * 1.5;
    const shakeOffsetY = (Math.random() - 0.5) * shake * 1.5;

    const baseZ = 22 / this.impactBridge.cameraPunchZoom;
    this.camera.position.set(
      this.cameraPos.x + shakeOffsetX,
      this.cameraPos.y + shakeOffsetY,
      baseZ
    );
    this.camera.lookAt(this.cameraPos.x, this.cameraPos.y, 0);

    // Parallax background follow
    this.backgroundGroup.position.x = this.cameraPos.x * 0.65;

    // 3. Update Enemies
    this.syncEnemies(sim.enemies.enemies);

    // 4. Update Projectiles
    this.syncProjectiles(sim.projectiles);

    // 5. Update Afterimages
    this.syncAfterimages(sim.zenith.afterimages);

    // Render 3D Scene
    this.renderer.render(this.scene, this.camera);

    // Render 2D Overlay (Impact frames, speed lines, overflow crack distortion)
    this.renderOverlay(sim);
  }

  private processSimulationEvent(ev: { type: string; payload?: Record<string, unknown> }, sim: KairosSimulation): void {
    this.impactBridge.ensureAudio();

    switch (ev.type) {
      case "zenith-hit-landed": {
        const hit = ev.payload?.hit as any;
        if (hit.isLauncher) {
          this.impactBridge.triggerRecipe("kairos.launch.directional", { position: hit.position });
        } else if (hit.verb === "chase") {
          this.impactBridge.triggerRecipe("kairos.chase.impact", { position: hit.position });
        } else if (hit.verb === "light") {
          this.impactBridge.triggerRecipe("kairos.hit.light", { position: hit.position });
        } else {
          this.impactBridge.triggerRecipe("kairos.hit.heavy", { position: hit.position });
        }

        // 28:00 Overflow screen cracks
        if (ev.payload?.inOverflow) {
          this.impactBridge.triggerRecipe("kairos.overflow.crack");
        }
        break;
      }

      case "zenith-perfect-guard": {
        this.impactBridge.triggerRecipe("kairos.guard.perfect", { position: ev.payload?.position as any });
        break;
      }

      case "zenith-hit-taken": {
        this.impactBridge.triggerRecipe("kairos.hit.heavy");
        break;
      }

      case "overflow-entered": {
        this.impactBridge.triggerRecipe("kairos.overflow.crack");
        break;
      }

      case "fade-fight-started": {
        this.impactBridge.triggerRecipe("kairos.overflow.crack");
        break;
      }

      case "run-ended": {
        this.impactBridge.triggerRecipe("kairos.fade.dissolve");
        break;
      }

      case "dimension-loaded": {
        this.rebuildEnvironment(sim);
        break;
      }
    }
  }

  private syncEnemies(enemies: EnemyState[]): void {
    const activeIds = new Set(enemies.map((e) => e.id));

    // Remove dead enemies
    for (const [id, mesh] of this.enemyMeshes.entries()) {
      if (!activeIds.has(id)) {
        this.scene.remove(mesh);
        this.enemyMeshes.delete(id);
      }
    }

    // Add or update enemies
    for (const enemy of enemies) {
      let group = this.enemyMeshes.get(enemy.id);
      if (!group) {
        group = this.buildEnemyMesh(enemy);
        this.scene.add(group);
        this.enemyMeshes.set(enemy.id, group);
      }

      group.position.set(enemy.position.x, enemy.position.y, 0);
      group.scale.x = enemy.facing;

      // Stagger / hit reaction tilt
      if (enemy.staggerTimer > 0) {
        group.rotation.z = -enemy.facing * 0.3;
      } else if (enemy.launchedTimer > 0) {
        group.rotation.z += 0.2;
      } else {
        group.rotation.z = 0;
      }
    }
  }

  private buildEnemyMesh(enemy: EnemyState): THREE.Group {
    const group = new THREE.Group();

    switch (enemy.type) {
      case "swarm-fodder": {
        const geo = new THREE.OctahedronGeometry(0.55, 0);
        const mat = new THREE.MeshStandardMaterial({ color: 0xe11d48, roughness: 0.3 });
        const mesh = new THREE.Mesh(geo, mat);
        group.add(mesh);
        break;
      }
      case "ranged-blaster": {
        const geo = new THREE.DodecahedronGeometry(0.65, 0);
        const mat = new THREE.MeshStandardMaterial({ color: 0xa855f7, roughness: 0.4 });
        const mesh = new THREE.Mesh(geo, mat);
        group.add(mesh);
        break;
      }
      case "armored-brute": {
        const geo = new THREE.BoxGeometry(1.6, 2.2, 1.4);
        const mat = new THREE.MeshStandardMaterial({ color: 0x78350f, metalness: 0.6, roughness: 0.5 });
        const mesh = new THREE.Mesh(geo, mat);
        group.add(mesh);
        break;
      }
      case "fast-flyer": {
        const geo = new THREE.ConeGeometry(0.6, 1.4, 4);
        const mat = new THREE.MeshStandardMaterial({ color: 0x0284c7, roughness: 0.3 });
        const mesh = new THREE.Mesh(geo, mat);
        mesh.rotation.z = -Math.PI * 0.5;
        group.add(mesh);
        break;
      }
      case "heavy-flyer": {
        const geo = new THREE.CylinderGeometry(1.2, 1.2, 0.7, 8);
        const mat = new THREE.MeshStandardMaterial({ color: 0x1e3a8a, metalness: 0.5 });
        const mesh = new THREE.Mesh(geo, mat);
        group.add(mesh);
        break;
      }
      case "the-threat": {
        // Multi-tier dark entity with reality crack core
        const bodyGeo = new THREE.TorusKnotGeometry(1.0, 0.35, 64, 8);
        const bodyMat = new THREE.MeshStandardMaterial({
          color: 0x180928,
          emissive: 0x4a044e,
          metalness: 0.8,
          roughness: 0.2
        });
        const mesh = new THREE.Mesh(bodyGeo, bodyMat);
        group.add(mesh);

        const auraGeo = new THREE.SphereGeometry(1.4, 16, 16);
        const auraMat = new THREE.MeshBasicMaterial({
          color: 0xff0055,
          wireframe: true,
          transparent: true,
          opacity: 0.4
        });
        const aura = new THREE.Mesh(auraGeo, auraMat);
        group.add(aura);
        break;
      }
    }

    return group;
  }

  private syncProjectiles(projectiles: Projectile[]): void {
    const activeIds = new Set(projectiles.map((p) => p.id));

    for (const [id, mesh] of this.projectileMeshes.entries()) {
      if (!activeIds.has(id)) {
        this.scene.remove(mesh);
        this.projectileMeshes.delete(id);
      }
    }

    for (const p of projectiles) {
      let mesh = this.projectileMeshes.get(p.id);
      if (!mesh) {
        let geo: THREE.BufferGeometry;
        let mat: THREE.Material;

        if (p.type === "beam-segment") {
          geo = new THREE.CylinderGeometry(p.radius, p.radius, 4.0, 12);
          mat = new THREE.MeshBasicMaterial({
            color: 0x00f0ff,
            transparent: true,
            opacity: 0.9,
            blending: THREE.AdditiveBlending
          });
        } else if (p.type === "burst-wave") {
          geo = new THREE.RingGeometry(p.radius * 0.7, p.radius, 32);
          mat = new THREE.MeshBasicMaterial({
            color: 0xffd700,
            side: THREE.DoubleSide,
            transparent: true,
            opacity: 0.7,
            blending: THREE.AdditiveBlending
          });
        } else {
          geo = new THREE.SphereGeometry(p.radius, 12, 12);
          mat = new THREE.MeshBasicMaterial({
            color: p.ownerId === "zenith" ? 0x00ffff : 0xff2255,
            blending: THREE.AdditiveBlending
          });
        }

        mesh = new THREE.Mesh(geo, mat);
        this.scene.add(mesh);
        this.projectileMeshes.set(p.id, mesh);
      }

      mesh.position.set(p.position.x, p.position.y, 0);
      if (p.type === "beam-segment") {
        mesh.rotation.z = Math.atan2(p.velocity.y, p.velocity.x) - Math.PI * 0.5;
      }
    }
  }

  private syncAfterimages(afterimages: { id: string; position: { x: number; y: number }; alpha: number; color: string }[]): void {
    // Keep pool of afterimage plane meshes
    while (this.afterimageMeshes.length < afterimages.length) {
      const geo = new THREE.PlaneGeometry(1.2, 2.0);
      const mat = new THREE.MeshBasicMaterial({
        color: 0x00f0ff,
        transparent: true,
        opacity: 0.8,
        blending: THREE.AdditiveBlending
      });
      const mesh = new THREE.Mesh(geo, mat);
      this.scene.add(mesh);
      this.afterimageMeshes.push(mesh);
    }

    for (let i = 0; i < this.afterimageMeshes.length; i++) {
      const mesh = this.afterimageMeshes[i];
      if (i < afterimages.length) {
        const data = afterimages[i];
        mesh.visible = true;
        mesh.position.set(data.position.x, data.position.y, -0.05);
        (mesh.material as THREE.MeshBasicMaterial).opacity = data.alpha * 0.6;
        (mesh.material as THREE.MeshBasicMaterial).color.setStyle(data.color);
      } else {
        mesh.visible = false;
      }
    }
  }

  private renderOverlay(sim: KairosSimulation): void {
    if (!this.overlayCtx) return;
    const ctx = this.overlayCtx;
    const w = this.overlayCanvas.width;
    const h = this.overlayCanvas.height;

    ctx.clearRect(0, 0, w, h);

    // 1. SLU Impact Frames: Full screen flash / color-inversion
    if (this.impactBridge.activeImpactFrames > 0) {
      this.impactBridge.activeImpactFrames--;
      ctx.fillStyle = this.impactBridge.impactFrameType === "tri-color" ? "#00f0ff" : "#ffffff";
      ctx.globalCompositeOperation = "difference";
      ctx.fillRect(0, 0, w, h);
      ctx.globalCompositeOperation = "source-over";
    }

    // 2. Speed lines at high velocity or launcher impacts
    const speedIntensity = Math.max(
      this.impactBridge.speedLinesIntensity,
      Math.hypot(sim.zenith.vel.x, sim.zenith.vel.y) / 75
    );

    if (speedIntensity > 0.3) {
      ctx.save();
      ctx.strokeStyle = "rgba(255, 255, 255, 0.4)";
      ctx.lineWidth = 2;
      const count = Math.round(speedIntensity * 24);
      for (let i = 0; i < count; i++) {
        const x = Math.random() * w;
        const y = Math.random() * h;
        const len = 40 + Math.random() * 80;
        ctx.beginPath();
        ctx.moveTo(x, y);
        ctx.lineTo(x + len * Math.sign(sim.zenith.vel.x || 1), y);
        ctx.stroke();
      }
      ctx.restore();
    }

    // 3. 28:00 Overflow reality fracture vignette
    if (sim.clock.state.inOverflow) {
      ctx.save();
      const grad = ctx.createRadialGradient(w * 0.5, h * 0.5, w * 0.3, w * 0.5, h * 0.5, w * 0.6);
      grad.addColorStop(0, "rgba(0, 0, 0, 0)");
      grad.addColorStop(1, "rgba(255, 0, 127, 0.35)");
      ctx.fillStyle = grad;
      ctx.fillRect(0, 0, w, h);
      ctx.restore();
    }

    // 4. Fade Dissolve Vignette
    if (sim.clock.state.phase === "fade-dissolve") {
      const dissolveAlpha = 1.0 - (sim.clock.state.fadeDissolveRemainingSeconds / 3.5);
      ctx.fillStyle = `rgba(255, 250, 230, ${Math.min(1.0, dissolveAlpha * 0.85)})`;
      ctx.fillRect(0, 0, w, h);
    }
  }
}

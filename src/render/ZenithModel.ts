import * as THREE from "three";
import type { ClockState } from "../sim/RunClock.js";

export class ZenithVisual {
  public group: THREE.Group;
  public meshRoot: THREE.Group;
  public bodyMaterials: THREE.MeshStandardMaterial[] = [];
  public crackMaterial: THREE.MeshBasicMaterial;
  public chestCoreMesh: THREE.Mesh;
  public leftRibbon: THREE.Line;
  public rightRibbon: THREE.Line;
  public rimLightMesh: THREE.Mesh;

  private ribbonPointsLeft: THREE.Vector3[] = [];
  private ribbonPointsRight: THREE.Vector3[] = [];
  private readonly maxRibbonSegments = 16;

  constructor() {
    this.group = new THREE.Group();
    this.meshRoot = new THREE.Group();
    this.group.add(this.meshRoot);

    // Kintsugi cracks material (emissive gold/cyan that glows brighter with clock)
    this.crackMaterial = new THREE.MeshBasicMaterial({
      color: 0xffd700,
      transparent: true,
      opacity: 0.15,
      blending: THREE.AdditiveBlending
    });

    // Chest core burst mesh (for 28:00 overflow and fade stage)
    const coreGeo = new THREE.SphereGeometry(0.22, 16, 16);
    const coreMat = new THREE.MeshBasicMaterial({
      color: 0xffffff,
      transparent: true,
      opacity: 0.0,
      blending: THREE.AdditiveBlending
    });
    this.chestCoreMesh = new THREE.Mesh(coreGeo, coreMat);
    this.chestCoreMesh.position.set(0, 1.15, 0.28);
    this.meshRoot.add(this.chestCoreMesh);

    // Build the stylized silhouette matching the locked art rules
    this.buildStylizedHumanoid();

    // Two trailing shoulder light ribbons
    const ribbonMatLeft = new THREE.LineBasicMaterial({
      color: 0x00f0ff,
      linewidth: 3,
      transparent: true,
      opacity: 0.85
    });
    const ribbonMatRight = new THREE.LineBasicMaterial({
      color: 0xff007f,
      linewidth: 3,
      transparent: true,
      opacity: 0.85
    });

    for (let i = 0; i < this.maxRibbonSegments; i++) {
      this.ribbonPointsLeft.push(new THREE.Vector3(-0.35, 1.3, -0.2));
      this.ribbonPointsRight.push(new THREE.Vector3(0.35, 1.3, -0.2));
    }

    const geoL = new THREE.BufferGeometry().setFromPoints(this.ribbonPointsLeft);
    const geoR = new THREE.BufferGeometry().setFromPoints(this.ribbonPointsRight);
    this.leftRibbon = new THREE.Line(geoL, ribbonMatLeft);
    this.rightRibbon = new THREE.Line(geoR, ribbonMatRight);
    this.group.add(this.leftRibbon);
    this.group.add(this.rightRibbon);

    // Thin cyan/magenta rim light shell
    const rimGeo = new THREE.CylinderGeometry(0.55, 0.45, 2.1, 16);
    const rimMat = new THREE.MeshBasicMaterial({
      color: 0x00ffff,
      wireframe: true,
      transparent: true,
      opacity: 0.28
    });
    this.rimLightMesh = new THREE.Mesh(rimGeo, rimMat);
    this.rimLightMesh.position.set(0, 1.0, 0);
    this.meshRoot.add(this.rimLightMesh);
  }

  private buildStylizedHumanoid(): void {
    // 1. Black Sleeveless High-Neck Top (Torso)
    const torsoGeo = new THREE.CylinderGeometry(0.36, 0.28, 0.85, 16);
    const blackTopMat = new THREE.MeshStandardMaterial({
      color: 0x0f1115,
      roughness: 0.4,
      metalness: 0.1
    });
    this.bodyMaterials.push(blackTopMat);
    const torso = new THREE.Mesh(torsoGeo, blackTopMat);
    torso.position.set(0, 1.15, 0);
    this.meshRoot.add(torso);

    // 2. Head with Porcelain skin and Swept-Back Dark Hair
    const headGeo = new THREE.SphereGeometry(0.24, 16, 16);
    const porcelainMat = new THREE.MeshStandardMaterial({
      color: 0xf3ede8,
      roughness: 0.25,
      metalness: 0.05
    });
    this.bodyMaterials.push(porcelainMat);
    const head = new THREE.Mesh(headGeo, porcelainMat);
    head.position.set(0, 1.82, 0);
    this.meshRoot.add(head);

    // Hair: smooth swept-back dark hair
    const hairGeo = new THREE.ConeGeometry(0.28, 0.55, 12);
    const hairMat = new THREE.MeshStandardMaterial({
      color: 0x08090b,
      roughness: 0.6
    });
    const hair = new THREE.Mesh(hairGeo, hairMat);
    hair.rotation.x = -Math.PI * 0.42;
    hair.position.set(0, 1.9, -0.15);
    this.meshRoot.add(hair);

    // 3. Black Sash around waist
    const sashGeo = new THREE.TorusGeometry(0.32, 0.06, 8, 16);
    const sashMat = new THREE.MeshStandardMaterial({ color: 0x181a20, roughness: 0.5 });
    const sash = new THREE.Mesh(sashGeo, sashMat);
    sash.rotation.x = Math.PI * 0.5;
    sash.position.set(0, 0.75, 0);
    this.meshRoot.add(sash);

    // 4. Loose Black Trousers (Legs)
    const legLGeo = new THREE.CylinderGeometry(0.18, 0.14, 0.8, 12);
    const legRGeo = new THREE.CylinderGeometry(0.18, 0.14, 0.8, 12);
    const trousersMat = new THREE.MeshStandardMaterial({ color: 0x12141a, roughness: 0.7 });
    this.bodyMaterials.push(trousersMat);

    const legL = new THREE.Mesh(legLGeo, trousersMat);
    legL.position.set(-0.2, 0.4, 0);
    const legR = new THREE.Mesh(legRGeo, trousersMat);
    legR.position.set(0.2, 0.4, 0);
    this.meshRoot.add(legL);
    this.meshRoot.add(legR);

    // 5. Bare feet & porcelain skin accents
    const footGeo = new THREE.BoxGeometry(0.12, 0.08, 0.22);
    const footL = new THREE.Mesh(footGeo, porcelainMat);
    footL.position.set(-0.2, 0.04, 0.04);
    const footR = new THREE.Mesh(footGeo, porcelainMat);
    footR.position.set(0.2, 0.04, 0.04);
    this.meshRoot.add(footL);
    this.meshRoot.add(footR);

    // 6. Arms with black wraps on forearms
    const armLGeo = new THREE.CylinderGeometry(0.1, 0.09, 0.7, 12);
    const armRGeo = new THREE.CylinderGeometry(0.1, 0.09, 0.7, 12);
    const armL = new THREE.Mesh(armLGeo, blackTopMat);
    armL.position.set(-0.48, 1.15, 0);
    armL.rotation.z = Math.PI * 0.08;
    const armR = new THREE.Mesh(armRGeo, blackTopMat);
    armR.position.set(0.48, 1.15, 0);
    armR.rotation.z = -Math.PI * 0.08;
    this.meshRoot.add(armL);
    this.meshRoot.add(armR);

    // Kintsugi fracture lines layer overlay on torso
    const crackGeo = new THREE.CylinderGeometry(0.37, 0.29, 0.86, 12, 4, true);
    const cracks = new THREE.Mesh(crackGeo, this.crackMaterial);
    cracks.position.set(0, 1.15, 0);
    this.meshRoot.add(cracks);
  }

  update(
    worldX: number,
    worldY: number,
    facing: number,
    bankAngle: number,
    clock: ClockState,
    velX: number,
    velY: number,
    dt: number
  ): void {
    this.group.position.set(worldX, worldY, 0);
    this.meshRoot.scale.x = facing;
    this.meshRoot.rotation.z = bankAngle;

    // ── Diegetic Clock Driven Elements ───────────────────────────────────────
    // 1. Kintsugi Cracks: widen and glow brighter as clock drains
    const crackProgress = clock.diegeticCrackProgress; // 0 to 1
    this.crackMaterial.opacity = 0.1 + crackProgress * 0.85;
    if (clock.inOverflow) {
      // 28:00 overflow: pulse intensely with cyan and gold
      const pulse = 0.8 + Math.sin(Date.now() * 0.015) * 0.2;
      this.crackMaterial.color.setHex(0xff007f);
      this.crackMaterial.opacity = pulse;

      // Chest center burst of light
      this.chestCoreMesh.scale.setScalar(1.0 + Math.sin(Date.now() * 0.02) * 0.4);
      (this.chestCoreMesh.material as THREE.MeshBasicMaterial).opacity = 0.85;
    } else {
      this.crackMaterial.color.setHex(0xffd700);
      (this.chestCoreMesh.material as THREE.MeshBasicMaterial).opacity = Math.max(0, (crackProgress - 0.6) * 1.5);
    }

    // 2. Shoulder Ribbons: fray and shorten as time drains
    // diegeticFrayProgress goes from 0 (long ribbons) to 1 (shortened stubs)
    const effectiveSegments = Math.max(3, Math.round(this.maxRibbonSegments * (1.0 - clock.diegeticFrayProgress * 0.75)));

    // Physics trail for ribbons
    const shoulderL = new THREE.Vector3(worldX - facing * 0.35, worldY + 1.35, -0.2);
    const shoulderR = new THREE.Vector3(worldX + facing * 0.35, worldY + 1.35, -0.2);

    this.ribbonPointsLeft[0].copy(shoulderL);
    this.ribbonPointsRight[0].copy(shoulderR);

    const lagSpeed = Math.max(4.0, 18.0 - clock.diegeticAfterimageLag * 40);

    for (let i = 1; i < this.maxRibbonSegments; i++) {
      if (i < effectiveSegments) {
        // Trailing lag behind Zenith
        const targetL = this.ribbonPointsLeft[i - 1].clone().add(new THREE.Vector3(-velX * 0.018 - facing * 0.1, -velY * 0.018 - 0.06, 0));
        const targetR = this.ribbonPointsRight[i - 1].clone().add(new THREE.Vector3(-velX * 0.018 - facing * 0.1, -velY * 0.018 - 0.06, 0));
        this.ribbonPointsLeft[i].lerp(targetL, Math.min(1.0, lagSpeed * dt));
        this.ribbonPointsRight[i].lerp(targetR, Math.min(1.0, lagSpeed * dt));
      } else {
        // Collapsed/frayed off
        this.ribbonPointsLeft[i].copy(this.ribbonPointsLeft[effectiveSegments - 1]);
        this.ribbonPointsRight[i].copy(this.ribbonPointsRight[effectiveSegments - 1]);
      }
    }

    this.leftRibbon.geometry.setFromPoints(this.ribbonPointsLeft);
    this.rightRibbon.geometry.setFromPoints(this.ribbonPointsRight);
    this.leftRibbon.geometry.computeVertexNormals();
    this.rightRibbon.geometry.computeVertexNormals();

    // 3. Rim Light: subtle breathing cyan/magenta
    const rimHue = (Date.now() * 0.0008) % 1;
    this.rimLightMesh.rotation.y += 0.02;
    (this.rimLightMesh.material as THREE.MeshBasicMaterial).color.setHSL(rimHue < 0.5 ? 0.52 : 0.9, 1.0, 0.6);
  }
}

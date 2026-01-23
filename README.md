
# ROV Runtime Builder & Simulator (Godot 4.6)

[不习惯英文？点击查看中文版说明 🇨🇳](README_CHS.md)

This project is a **runtime-configurable ROV (Remotely Operated Vehicle) simulator** built with **Godot Engine 4.6**.

It focuses on:

* Physically plausible underwater motion
* Thruster-based force-driven dynamics
* Modular ROV construction at runtime (no editor required)
* Clear separation between *design-time parts* and *simulation-time behavior*

The project is intended for **ROV concept validation, teaching, and interactive simulation**, rather than photorealistic rendering.

---

## Core Concepts

### 1. Physics-Driven ROV Simulation

* Uses `RigidBody3D` as the physical core
* All motion is produced by **forces and torques**, not kinematic hacks
* Hydrodynamics are approximated with:

  * Anisotropic linear drag
  * Angular damping
  * Buoyancy with configurable center of buoyancy
* Thrusters are modeled as force generators with PWM → thrust curves

### 2. Runtime ROV Construction

Unlike typical Godot projects, **ROV assembly does not rely on the Godot editor**.

At runtime:

* Parts are instantiated from data (`PartData`)
* Position, rotation, and parameters are adjusted via UI
* The final configuration is assembled into a simulated ROV entity

This allows:

* End users to build robots inside the application
* No need to ship the Godot editor
* A workflow similar to games like *Besiege* or *SimpleRockets*

### 3. Separation of Responsibilities

* **PartData**: describes *what a part is* (parameters, limits, defaults)
* **Runtime Part Node**: executes behavior (thruster force, sensor output, etc.)
* **Assembler**: converts data → live simulation nodes
* **Simulation**: consumes forces and states, unaware of UI or editor logic

---

## Requirements

* **Godot Engine 4.6 (official release)**
* Windows / Linux / macOS (desktop focus)

---

## How to Use

### 1. Download Godot 4.6

1. Go to the official Godot website:
   [https://godotengine.org](https://godotengine.org)
2. Download **Godot Engine 4.6 (Standard version)**

   * Do **not** use Mono/.NET unless you know you need it
3. Extract the executable (no installation required)

---

### 2. Clone This Repository

```bash
git clone <your-repo-url>
```

Or download the ZIP and extract it.

---

### 3. Open the Project in Godot

1. Launch `Godot_v4.6.exe`
2. Click **Import**
3. Select the project folder (the one containing `project.godot`)
4. Confirm import

Godot will load the project and reimport assets automatically.

---

### 4. Run the Simulator

* Open the main scene (e.g. simulation or builder scene)
* Click **Run Project (F5)**

From there you can:

* Enter the build mode
* Place thrusters and other parts
* Adjust parameters via UI
* Switch to simulation mode and observe behavior

---

## Typical Workflow

1. Enter **Build Mode**
2. Add parts (thrusters, hull elements, etc.)
3. Adjust:

   * Position
   * Orientation
   * Part-specific parameters (thrust, direction, limits)
4. Assemble into a complete ROV
5. Start simulation
6. Observe forces, motion, and stability

---

## License

This project is licensed under the **Apache License 2.0**.

You are free to use, modify, and distribute this software, including for commercial purposes, as long as you comply with the terms of the license.

See the `LICENSE` file for full details.
# Lost in Pixels

A 2D pixel-style game built with **Godot 4.6**. You explore a chunk-based world, interact with creatures (e.g. rabbits that eat and wander), and use simple combat and items.

---

## Getting Godot

1. **Download Godot 4.6** (or the latest 4.x that matches the project):
  - [godotengine.org/download](https://godotengine.org/download)
  - Choose the **Standard** version for your OS (e.g. Windows, Linux, macOS).
2. **Install / run**
  - Windows: extract the ZIP and run `Godot_v4.x_*.exe`.  
  - No system-wide install required; the editor runs from the folder.

---

## How to launch the game

1. Open **Godot Engine**.
2. **Import** or **Open** the project: point to the folder that contains `project.godot` (this repo’s root).
3. In the editor, press **F5** or click the **Play** (▶) button to run the main scene.

---

## What the game does

- **World**: A procedurally generated, chunk-based 2D world.
- **Creatures**: Animals (e.g. rabbits) with simple AI: they get hungry, seek food (e.g. carrots), wander, and can flee. Some creatures can fly. They have health and can be damaged or eaten.
- **You**: You control a character that can move, attack nearby creatures, interact with the world.

---

## What you can do (controls)


| Action           | Input                                        |
| ---------------- | -------------------------------------------- |
| **Move**         | **WASD** or **Arrow keys** or **left stick** |
| **Attack**       | **F**                                        |
| **Spawn carrot** | **Q** (or **A** on AZERTY)                   |
| **Interact**     | **E**                                        |


- **Move**: Walk around the world; your movement speed can be modified by the terrain (e.g. different chunk types).
- **Attack**: Hit enemies/creatures in a short range, instantly killing them.
- **Spawn carrot**: Places a carrot in the world (e.g. in front of you). Creatures that eat food will go for it, and they might follow you afterwards
- **Interact**: Try, and find out what happens

---

## Tech notes

- **Engine**: Godot 4.6, **Forward+** renderer.  
- **Physics**: 2D (Jolt is listed in `project.godot` for 3D; 2D uses Godot’s built-in 2D physics).  
- **Main scene**: `scenes/game.tscn`.

If something doesn’t run, ensure you’re using **Godot 4.x** (ideally 4.6) and that the project path contains `project.godot`.

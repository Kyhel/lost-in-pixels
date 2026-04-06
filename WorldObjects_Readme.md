# World objects — Context for design & tooling

## Regenerating this document from the codebase

When world-object behavior or data has changed, open this file in your editor (or attach it) and paste the prompt below into a new chat so the assistant can **re-scan the implementation** and **rewrite** `WorldObjects_Readme.md` in the same spirit.

**Copy everything inside the fence:**

```text
Regenerate WorldObjects_Readme.md for the Lost in Pixels Godot project.

Requirements:
- Explore world-object code and related systems (object data, behaviors, features, spawning, chunk registration, player/creature interaction, inventory drops).
- Describe how world objects work **in the game**—what they represent, how they appear, and how the player and creatures use them.
- Keep it **functional and conceptual**: good as context for another AI or designer, **not** a class-by-class or file walkthrough.
- Preserve the purpose of the doc: a pasteable overview of the world object system.
- Start the file with this same "Regenerating this document" section and the same copy-paste prompt (update the prompt text only if the workflow changes).
- Replace the body below that with an up-to-date summary; match the tone and structure of the previous version unless the code clearly needs new sections.
```

---

Use this document as **high-level context** for **interactive and decorative objects** placed in the *Lost in Pixels* world. It is **functional and conceptual**, not an implementation guide.

---

## What a world object is

A **world object** is something that exists **in the scene** at a position: pickups, plants, props, and similar. Each type is defined by **data** (identity, visuals, collision size, optional custom scene) plus two kinds of add-ons:

- **Behaviors** — gameplay rules: can this be **picked up**, **eaten by creatures**, **produced** by a parent object, **fetched** by a tamed creature, and so on.
- **Features** — setup that is not a full “behavior,” often **presentation or environment** (for example a tree’s **canopy/foliage** layering and masking).

Objects live in the **loaded chunk** that contains their position so the game can **spawn**, **track**, and **query** them efficiently as you move around the world.

---

## How objects enter the world

Objects are **spawned** into the active chunk’s object layer. Sources include:

- **World generation** — for example **trees** and **small vegetation** placed when terrain chunks are built, using biome and tile suitability.
- **Continuous spawning** — optional **real-time spawn definitions** (per object type) that roll over tiles in loaded chunks, respecting **biome**, **tile type**, and **spawn rules** (for example **density**: only spawn if a similar object count nearby is in an allowed band).
- **Player-driven placement** — **dropping items** from inventory (spawns the configured “on drop” object), **abilities** (for example growing a flower), or debug/test spawns. These are marked as **player-placed**, which matters for systems like **taming** (some interactions only count when food was placed by the player).

Placement can be **blocked** if another object would **overlap** too closely—so props do not stack unrealistically in the same spot.

---

## Picking up (player)

Some objects are **pickable**: they map to an **inventory item** when collected. The player uses a **forward cone** and **range** in front of them; among valid targets, the **nearest** is taken first. Successful pickup **removes** the world object and puts the item in inventory (through the normal pickup flow).

---

## Eating and food (creatures vs player)

**Creatures** can **eat** certain world objects that match their **diet** (configured per species). Eating typically **satisfies hunger** and **destroys** the object, and may feed **taming** if the object is valid taming food.

The **player does not eat world objects directly** in the field. Hunger and healing from food go through **items** (for example consuming from inventory), not by walking into a carrot on the ground.

---

## Producer objects (berries, regrowth, etc.)

A **producer** is a world object that **owns several slots** around itself and **spawns** another object type into those slots (for example a bush spawning berries). When a spawned piece is **taken or destroyed**, that slot **empties** and can **fill again over time** with a **random chance** on a timer—so resources can **come back** without manually respawning the whole plant.

---

## Fetching

Objects can be marked as part of the **fetch** loop for tamed creatures: the definition can point to **what kind of object** the creature is carrying when it retrieves something (for example a stick vs a ball). That keeps **world appearance**, **pickup identity**, and **held-item appearance** aligned where the design needs them to differ.

---

## Visuals and special cases (example: trees)

Besides the main sprite and hitbox, some types use **features** for **large layered sprites** (for example **foliage** above or below entities) and **rendering tricks** so the canopy interacts correctly with the world. That is mostly **look and readability**, not a separate gameplay category.

---

## Summary

- World objects are **data-driven** instances in the world with **behaviors** (gameplay) and optional **features** (presentation or setup).
- They are **spawned** by generation, **live spawning rules**, or **player actions**, with **overlap checks** and **chunk association**.
- The **player** interacts through **pickup** (inventory) and **indirect** food via items; **creatures** **eat** eligible objects in the world and may use **fetch** and **producer** mechanics depending on design.

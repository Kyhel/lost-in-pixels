# Creature AI — Context for design & tooling

## Regenerating this document from the codebase

When creature AI has changed, open this file in your editor (or attach it) and paste the prompt below into a new chat so the assistant can **re-scan the implementation** and **rewrite** `CreatureAI_Readme.md` in the same spirit.

**Copy everything inside the fence:**

```text
Regenerate CreatureAI_Readme.md for the Lost in Pixels Godot project.

Requirements:
- Explore the creature AI code (goals, needs, sensors, blackboard, taming, commands, movement-related behavior) and describe how creatures behave **in the game**.
- Keep it **functional and conceptual**: good as context for another AI or designer, **not** a class-by-class or file walkthrough.
- Preserve the purpose of the doc: a pasteable overview of the creature AI system.
- Start the file with this same "Regenerating this document" section and the same copy-paste prompt (update the prompt text only if the workflow changes).
- Replace the body below that with an up-to-date summary; match the tone and structure of the previous version unless the code clearly needs new sections.
```

---

Use this document as **high-level context** for how creatures behave in *Lost in Pixels*. It is **functional and conceptual**, not an implementation guide.

---

## What drives behavior

Creatures are defined by **species data**: which goals they can pursue, which **needs** they have, which **sensors** perceive the world, and traits such as tamability, fetching, or terrain preferences.

Each frame, the game evaluates **goals** and picks the one with the **strongest current “utility” score**. That choice can **stick for a short time** so creatures do not constantly flip between unrelated behaviors. The active goal runs a **behavior plan** (a scripted sequence of conditions and actions: move, wait, pick up objects, etc.).

Needs are numeric meters that drift over time (for example hunger going down). They influence scores and outcomes but are not the whole story—**what the creature currently perceives** (food in range, player in range, etc.) matters just as much.

---

## Needs (internal state)

Typical needs include:

- **Hunger** — falls over time. Drives interest in **eating** when it is low enough and something edible is known.
- **Fear** — rises when the **player is too close** (for untamed creatures), up to a level where **fleeing** becomes the top priority. Tamed creatures do not build fear from the player the same way.
- **Taming progress** — for tamable species, eating the **right food** (usually **placed by the player**) fills this toward a threshold; reaching it marks the creature as **tamed**.
- **Stamina** and **fetch desire** — used for **tamed fetchers** so fetching is not endless: willingness and energy modulate whether they go after a thrown or visible fetchable object.

Exact curves and thresholds are **per species** in data.

---

## Perception and memory

Creatures combine **sensors** (what they notice around them) with a small **shared memory** used by AI: visible food, visible fetch targets, whether they **see the player**, tamed state, active **player command** (see below), and combat-related mood such as **aggressiveness** and **chasing state**.

Food detection respects **diet**: configured **object types** (plants, items, etc.) and optionally **other creature species** as prey. **Tamed creatures are not treated as prey** for the eating logic.

---

## Common behaviors (goals)

These are the **ideas** behind major goals; not every species has every goal.

### Fleeing

When **fear** is high enough, fleeing **overrides** almost everything else. The creature prioritizes **getting away** from the threat (typically the player).

### Eating

If the creature is **hungry enough** and **knows about food** nearby, it will try to **move to and eat** it. It can target **world objects** or, for carnivores, **other creatures** that match its prey list.

**Tamable** species that are **not yet tamed** may also seek **special taming food** (player-placed items that grant taming progress) even when they are not particularly hungry, so they can **choose to approach** taming bait.

### Wandering and idle movement

When nothing urgent applies, a **low-priority** goal keeps the creature **moving around** in a relaxed way—picking destinations that respect **species terrain rules** (biomes, allowed terrain types, water/swim/fly rules, etc.).

### Hostile / aggressive behavior toward the player

Hostile species maintain an **aggressiveness** level while they **see the player**. It **rises** while the player remains visible and **falls** when the player is lost or when the creature is “cooling down.” When aggressiveness is **full**, the creature enters a **chase / attack** phase. Some species add **extra rules** (for example only chasing while the player stands on certain terrain), so aggression is **not always a simple “always chase”** behavior.

### Flying

Flying species use a parallel **low-priority** patrol-style goal similar in spirit to wandering, adapted for **flight** instead of ground walking.

---

## Taming and companions

**Taming** is a **progress** toward a threshold, usually by eating **correct player-placed food** defined per species. Once **tamed**, the creature’s blackboard marks it as **tamed**, which **unlocks** follower and command-based goals and **changes** fear-related behavior toward the player.

**Following** (loosely following the player) is mainly relevant when **tamed** and the player is **far away**—the creature is **more motivated** to close the distance when the gap is large.

---

## Player commands (tamed creatures)

When tamed, the player can set a **command** that biases behavior:

- **Free** — default companion behavior: **wander** and other autonomous goals are allowed; the creature is not locked to a tight follow.
- **Heel** — **stay close** to the player (follow at short range).
- **Stay** — **hold position** for a **limited time**; when the timer ends, the command **falls back** to free.

Active commands sit at a **moderate priority**—strong enough to **shape** behavior when the creature is not panicking, starving, or in another urgent state.

---

## Fetching (tamed fetchers)

Species with a **fetcher** trait define which **objects** count as fetchables. When **tamed**, the creature can **prioritize** going to a visible fetchable, **picking it up**, **bringing it back**, and **giving it to the player**. **Stamina** and **fetch desire** **soften** how eager the creature is when searching, so fetch is **optional** and **tempered** by fatigue and desire.

---

## Summary

- Behavior is **goal-driven** with **utility scores**, **short commitment** to the current goal, and **per-species** priorities.
- **Needs** (hunger, fear, taming, stamina, fetch desire) **shape** urgency and eligibility.
- **Sensors** supply **what is known** about food, the player, and fetch targets.
- **Taming** flips the creature into a **companion** with **commands** and optional **fetch**.
- **Combat** is **staged** (build-up, chase, recover) with **data-defined** aggression and **species-specific** rules where needed.

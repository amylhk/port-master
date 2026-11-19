# Project Status and Proposed Structure

## What exists

- A detailed English game vision and architecture blueprint in `docs/gameplay-blueprint.md`.
- Design-level exploration of a day/night loop, harbour operations, inspection, merchants, and economic systems.

## What does not exist yet

- No functional Godot project, gameplay scenes, scripts, assets pipeline, or playable build is represented in this repository.

## Possible Godot structure (proposal only)

If a Godot implementation is selected, a prototype might use:

```text
godot/
  project.godot
  scenes/
    harbour/
    inspection/
    ui/
  scripts/
    simulation/
    economy/
    inspection/
    merchants/
  data/
    commodities/
    vessels/
    events/
  assets/
    art/
    audio/
```

This is a planning sketch, **not an existing project tree**. The engine, project architecture, and MVP scope remain open decisions.

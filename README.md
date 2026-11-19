# Port Master: Melaka 1511

**Status: Early Godot 4 gameplay experiment / pre-production.**

A historical trading-hub game concept set in Melaka before the Portuguese conquest of 1511. This repository contains a **small playable harbour scheduling experiment**, alongside the larger ideal-gameplay design blueprint. It is **not** a complete game or finished vertical slice.

## Run the experiment

1. Install Godot 4.x.
2. Import this folder by selecting `project.godot` in Godot Project Manager.
3. Run the project (F6/F5).
4. Assign waiting ships to one of two berths; advance time and observe parallel cargo processing and limited anchorage capacity.

## Implemented

- Godot project configuration and main `.tscn` scene
- GDScript harbour queue and berth assignment
- Five fictional test ships and a three-slot anchorage
- Parallel berth processing, time advancement, and event log
- Capacity-based lost arrivals

## Not implemented

- Real-time clock, detailed inspection, manifests, reference manual, merchant AI, royal purchasing, economics, narrative, and diplomacy
- End-of-day ship departure logic (ships currently remain waiting)

The simulation currently uses **manual time advancement**, not the proposed real-time design. These simplifications are intentional to test the harbour queue independently.

## Design documentation

- [`docs/gameplay-blueprint.md`](docs/gameplay-blueprint.md) — aspirational design, not a claim of implemented features.
- [`design/project-status.md`](design/project-status.md) — design-stage context.

## Repository structure

```text
project.godot
scenes/harbour.tscn
scripts/harbour.gd
docs/gameplay-blueprint.md
design/project-status.md
```

# Port Master: Melaka 1511

**Status: Early Godot 4 gameplay experiment / pre-production.**

A historical trading-hub game concept set in Melaka before the Portuguese conquest of 1511. This repository contains the **Stage A core fun prototype**: one playable port day with two berths, a limited anchorage, and one Detailed Inspection case. It is **not** a complete game or finished vertical slice.

## Run the experiment

1. Install Godot 4.3.
2. Import this folder by selecting `project.godot` in Godot Project Manager.
3. Run the project (F5).
4. Assign waiting ships to berths and step time forward. Read each ship's unloading duration and tide deadline before committing a berth. The closing ledger records duty, rice supply, and missed trade. Replay to try a different priority.
5. To investigate the porcelain trader, assign another ship to the first berth before choosing **Inspect**. Detailed Inspection takes the second berth and advances the port clock by 45 minutes; the other berth and scheduled arrivals keep working. Compare the manifest, cargo, testimony, and reference manual before filing a ruling and citing evidence.

## Implemented

- Godot project configuration and main `.tscn` scene
- GDScript harbour queue and berth assignment
- Six fictional ships, timed arrivals and tide deadlines, and a three-slot anchorage
- Parallel unloading, port log, and a closing ledger with duty, rice supply, inspection duty, and lost trade
- One data-driven Detailed Inspection with a separate reference manual and a consequential ruling

## Not implemented

- Real-time clock, Basic Inspection, merchant AI, royal purchasing, linked days, narrative campaign, and diplomacy

Stage A keeps **manual time advancement** and uses the blueprint's alternative fixed inspection cost. The inspection does not additionally run a wall-clock timer while you read.

## Verify

```sh
godot --headless --editor --import --quit
godot --headless --check-only --script scripts/harbour.gd
godot --headless --quit-after 120
godot --headless --script tests/stage_a.gd
```

## Design documentation

- [`docs/gameplay-blueprint.md`](docs/gameplay-blueprint.md) — aspirational design, not a claim of implemented features.
- [`docs/data-formats.md`](docs/data-formats.md) — Writer and Artist authoring formats.
- [`design/project-status.md`](design/project-status.md) — design-stage context.

## Repository structure

```text
project.godot
scenes/harbour.tscn
scripts/harbour.gd
scripts/port_day.gd
data/
assets/inspection/
docs/gameplay-blueprint.md
design/project-status.md
```

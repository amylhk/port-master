# Port Master: Melaka 1511

**Status: Early Godot 4 gameplay experiment / pre-production.**

A historical trading-hub game concept set in Melaka before the Portuguese conquest of 1511. The **Stage B prototype** runs for fifteen linked port days, with two berths, a limited anchorage, and eighteen scheduled Detailed Inspection cases. The historical campaign and finale are not part of the playable schedule yet.

## Run the experiment

1. Install [Godot 4.7.2](https://github.com/godotengine/godot/releases/tag/4.7.2-stable).
2. Import this folder by selecting `project.godot` in Godot Project Manager.
3. Run the project (F5).
4. Assign waiting ships to berths and step time forward. Read each ship's unloading duration and tide deadline before committing a berth. Use the quay office to select a deputy or open a merchant offer.
5. Close the watch at 17:00, resolve available evening events and departure accounts, and begin the next day. Ships still at anchor carry over. The closing ledger records duty, rice supply, and missed trade; **Replay the day** restores that morning's state.
6. To investigate the Kim Hong on day 1, assign another ship to the first berth before choosing **Inspect**. Detailed Inspection takes the second berth and advances the port clock by 45 minutes; the other berth and scheduled arrivals keep working. Compare the manifest, cargo, testimony, and reference manual before filing a ruling and citing evidence.

## Implemented

- Godot project configuration and main `.tscn` scene
- GDScript harbour queue and berth assignment
- Named merchant ships, linked daily schedules, tide deadlines, and a three-slot anchorage
- Parallel unloading, port log, and a closing ledger with duty, rice supply, inspection duty, and lost trade
- Data-driven Detailed Inspections with a shared reference manual and consequential rulings
- Deputy delegation, state purchasing offers, merchant trust, and departure and tax accounts

## Not implemented

- Real-time clock, Basic Inspection, merchant AI, historical story chains, finale, and diplomacy

The prototype keeps **manual time advancement** and uses the blueprint's alternative fixed inspection cost. The inspection does not additionally run a wall-clock timer while you read.

## Verify

On a fresh clone, run the import command before launching Godot headless so textures such as `banner_header.png` are available.

```sh
godot --headless --editor --import --quit
godot --headless --check-only --script scripts/harbour.gd
godot --headless --quit-after 120
godot --headless --script tests/stage_a.gd
godot --headless --script tests/stage_b.gd
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

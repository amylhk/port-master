# Port Master: Melaka 1511

**Status: Playable Day 1 rebuild in Godot 4.7.2 / pre-production.**

A historical trading-hub game set in Melaka before the Portuguese conquest of 1511. F5 now opens **Day 1 only**: drag ships onto two berths, open cargo at the inspection desk, consult the manual and stamp the declaration. The interface and Day 1 copy use written Traditional Chinese, with bundled [Noto Sans TC](https://github.com/google/fonts/tree/main/ofl/notosanstc) and its SIL Open Font License.

## Run the experiment

1. Install [Godot 4.7.2](https://github.com/godotengine/godot/releases/tag/4.7.2-stable).
2. Import this folder by selecting `project.godot` in Godot Project Manager.
3. Run the project (F5).
4. Drag a waiting ship onto a highlighted empty berth, or click the ship and then the berth. Read its unloading duration and departure deadline before committing. Use the clock buttons to advance time; thinking and reading do not run a real-time clock.
5. Case ships offer declared unloading or detailed inspection. Inspection occupies the chosen berth and advances time by its fixed cost; the other berth and scheduled arrivals keep working. Open physical evidence, consult the manual, choose an evidence citation and a plain ruling stamp, then stamp the declaration. Full original evidence is one click away; consequences appear only after filing.
6. Close the watch when ready, or automatically at 17:00. The closing ledger records duty, rice supply and lost trade. Replay restores the morning. Deputies, offers, economy, evenings and later days are deliberately absent from this new main scene.

The previous fifteen-day Stage B prototype remains available in `scenes/harbour.tscn` for regression checks and later development, not as the current player entry point. Stage D remains unmerged.

## Day 1 rebuild

- Sea-view harbour with unboxed draggable ships, pier-side moorings and click fallback
- Isometric harbour art uses the existing asset paths; the scene remains playable with older art
- The painted sea extends beyond the centered play surface on non-16:9 windows
- Original six Day 1 ships, departure deadlines, two berths and three anchorage slots
- Original parallel unloading, fixed inspection time costs and four authored cases
- Hands-on cargo, seals, scales, testimony, paged manual and unselected plain stamps
- Parchment-and-teal desk, short copy with full evidence on click, closing and replay

## Not implemented

- Real-time clock, Basic Inspection, merchant AI, historical story chains, finale, and diplomacy

The prototype keeps **manual time advancement** and uses the blueprint's alternative fixed inspection cost. The inspection does not additionally run a wall-clock timer while you read.

## Verify

On a fresh clone, run the import command before launching Godot headless so textures such as `banner_header.png` are available.

```sh
godot --headless --editor --import --quit
godot --headless --check-only --script scripts/day_one.gd
godot --headless --check-only --script scripts/harbour.gd
godot --headless --quit-after 120
godot --headless --script tests/day_one.gd
godot --headless --script tests/day1_text.gd
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
scenes/day_one.tscn
scripts/day_one.gd
scenes/harbour.tscn
scripts/harbour.gd
scripts/port_day.gd
data/
assets/inspection/
docs/gameplay-blueprint.md
design/project-status.md
```

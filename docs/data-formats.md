# Stage A authoring formats

Stage A uses UTF-8 JSON objects under `res://data/`, read with `FileAccess` and `JSON.parse_string`. Required fields are listed below unless marked optional. Labels and prose are display text; keep IDs stable and unique within each collection. Use JSON `\n` for paragraph breaks.

| File | Object shape |
| --- | --- |
| `data/port_day.json` | `briefing` (text), `start_minute`, `end_minute`, `rice_target` (integers), `ships` (array ordered by arrival) |
| `data/manual/manual_stage_a.json` | `title` (text); `entries` (array of objects with `title` and `text`, in reading order) |
| `data/inspections/<id>.json` | `id`, `title`, `subtitle` (text); `minutes` (integer); `evidence`, `rulings`, `reasons` (arrays); `hidden_truth` (object) |

- **Ships:** `id`, `name`, `cargo` (text); `arrival` and `departure` (integers, minutes since midnight); `minutes` (positive unloading duration); `duty` (integer), `rice` (integer sacks); optional `inspection_case` is the case ID. Deadline times are the last minute a sale can complete.
- **Registering inspections:** Put the case file in `data/inspections/` and add its ID (without `.json`) to the ship, e.g. `"inspection_case": "case_002"` loads `data/inspections/case_002.json`. The file's `id` must match. The day can reference multiple case IDs and fails to load if any referenced file is missing. Ships without `inspection_case` use normal berth assignment.
- **Evidence:** each page has `id`, `label` (short button text), `title`, and `text`. Optional `image` is the full Godot resource path. Put observations on the evidence pages and generally applicable conventions in the manual. The manifest describes what was declared, never the expected correct markings or an assessment.
- **Choices:** `rulings` and `reasons` each contain `id` and `label` pairs. The current outcome handlers reserve `clear` for clearing as declared and `hold` for stopping the sale. Other ruling IDs attempt an amendment.
- **Hidden truth:** `ruling_id` and `reason_id` identify the one successful combination. A successful amendment credits `extra_duty` only after unloading. `success`, `clear`, `unsupported`, and `hold` are feedback text shown only after filing. Keep all pre-ruling text independent of this object. This hides the answer in play, not from someone reading the JSON.

## Art

Use Godot-importable **SVG** for vector illustrations or **PNG** for raster art, at `res://assets/inspection/<lowercase-kebab-name>.<ext>`. Set `evidence[].image` to the full path; the game fits it without stretching in the evidence panel. The shipped placeholder is `lot-seven.svg` (2:1). Keep the evidence text sufficient without the illustration. No illustration is required to run.

Open/import the project in Godot to import new textures. If configuring a packaged build later, include `data/**/*.json` as non-resource files and include textures loaded through JSON paths.

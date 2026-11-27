# Data authoring formats

Authoring data uses UTF-8 JSON objects under `res://data/`, read with `FileAccess` and `JSON.parse_string`. Required fields are listed below unless marked optional. Labels and prose are display text; keep IDs stable and unique within each collection. Use JSON `\n` for paragraph breaks.

| File | Object shape |
| --- | --- |
| `data/port_day.json` | `briefing` (text), `start_minute`, `end_minute`, `rice_target` (integers), `ships` (array ordered by arrival) |
| `data/manual/manual_stage_a.json` | `title` (text); `entries` (array of objects with `title` and `text`, in reading order) |
| `data/inspections/case_001.json` | `id`, `title`, `subtitle` (text); `minutes` (integer); `evidence`, `rulings`, `reasons` (arrays); `hidden_truth` (object) |
| `data/briefings/<id>.json` | One morning briefing per file: `id`, `title`, `body` (text); `day` (integer) or `trigger` (condition text); optional `requires`, `choices`, `notes` (arrays) |
| `data/events/<id>.json` | One evening event per file, same shape as a briefing |
| `data/deputies/<id>.json` | One Stage B deputy per file: `id`, `name`, `role`, `bio` (text); `skills`, `flaw`, `delegation_lines` (objects); optional `notes` (array) |

- **Ships:** `id`, `name`, `cargo` (text); `arrival` and `departure` (integers, minutes since midnight); `minutes` (positive unloading duration); `duty` (integer), `rice` (integer sacks); optional `inspection_case` is the case ID. Deadline times are the last minute a sale can complete.
- **Evidence:** each page has `id`, `label` (short button text), `title`, and `text`. Optional `image` is the full Godot resource path. Put observations on the evidence pages and generally applicable conventions in the manual. The manifest describes what was declared, never the expected correct markings or an assessment.
- **Choices:** `rulings` and `reasons` each contain `id` and `label` pairs. The current outcome handlers reserve `clear` for clearing as declared and `hold` for stopping the sale. Other ruling IDs attempt an amendment.
- **Hidden truth:** `ruling_id` and `reason_id` identify the one successful combination; `extra_duty` is credited only after unloading. `success`, `clear`, `unsupported`, and `hold` are feedback text shown only after filing. Keep all pre-ruling text independent of this object. This hides the answer in play, not from someone reading the JSON.


## Briefings and events

Morning briefings live in `data/briefings/` and evening events in `data/events/`, one item per file, named `<id>.json`. Both use the same shape:

- `id`, `title`, `body` (text). `body` is what the player reads; use `\n\n` between paragraphs.
- Exactly one of `day` (integer, the day it is read) or `trigger` (a condition string such as `"day>=2"`).
- Optional `requires`: named flags that must all be set, for conditions a `trigger` cannot express. The loader defines each flag.
- Optional `choices`: each has `id`, `label` (button text), `outcome_text` (shown after picking) and `effects`, an object of integer deltas with any of `duty`, `supply` and `reputation`.
- Optional `notes`: author notes on sources and game abstractions, never shown in play.

Briefing flags in use: `rice_short_yesterday` (rice landed the previous day fell below `rice_target`), `ship_lost_yesterday` (at least one ship lost the previous day), `major_fraud_ruled_yesterday` (a correct Major Fraud ruling the previous day), `ships_held_over` (ships carried over unresolved from the previous day). Run `godot --headless --script tests/briefings.gd` to check briefing files.

Sample briefing (`data/briefings/rice_short.json`, abridged):

```json
{
  "id": "rice_short",
  "trigger": "day>=2",
  "requires": ["rice_short_yesterday"],
  "title": "The granary keepers are worried",
  "body": "Shahbandar, less rice came ashore yesterday than the town needs.\n\nThe granary keepers ask what they should do before the next rice ship berths.",
  "choices": [
    {"id": "open_granary", "label": "Ask the treasury to open the royal granary",
     "outcome_text": "The treasury opens the royal granary and sells at the old price.",
     "effects": {"duty": -4, "supply": 8, "reputation": 1}}
  ]
}
```

Sample event (illustrative; `data/events/` holds the real ones):

```json
{
  "id": "sample_evening_visit",
  "day": 1,
  "title": "A visitor after the closing bell",
  "body": "A Kling merchant waits at the harbour office with a gift of cloth and a question about tomorrow's berths.",
  "choices": [
    {"id": "accept_gift", "label": "Accept the cloth and hear him out",
     "outcome_text": "He leaves pleased, and other merchants hear that the office can be approached.",
     "effects": {"reputation": 1}},
    {"id": "decline_gift", "label": "Decline politely",
     "outcome_text": "He takes the cloth home. The office keeps its distance.",
     "effects": {"reputation": 0}}
  ]
}
```

## Deputies

Stage B deputies live in `data/deputies/`, one deputy per file named `<id>.json`.

- `id`, `name`, `role`, `bio` (non-empty text).
- `skills`: integer ratings from 0 to 5 for exactly three delegable tasks: `berth`, `inspection`, and `purchasing`.
- `flaw`: `id` identifies the flaw, and `text` describes it (both non-empty text). The game decides how the flaw changes outcomes; the prose does not set a numerical modifier.
- `delegation_lines`: keyed by the same three task IDs. Each task has `assign` (spoken when given the work) and `good`, `mixed`, and `bad` (spoken when reporting the result). Each is a non-empty array of non-empty strings. The game could pick a line at random from the matching array when it has multiple variants.
- Optional `notes`: authoring-only strings, never shown in play. Start every note with `[FACT]` (source-backed), `[INFERENCE]` (plausible reconstruction), or `[GAMEPLAY]` (fiction or design abstraction).

Flaw IDs in use (intended effects):

| ID | Effect |
| --- | --- |
| `kin_and_countrymen` | Valuation and inspection are more lenient toward ships from Pasai and Bengal. |
| `accepts_presents` | A captain's gift can win a kinder tally or leave a fault unreported. |
| `weighs_everything` | Checking weights personally slows inspection and can cost a ship berth time or delay its departure. |
| `old_favours` | A captain owed a favour may jump the berth queue. |
| `rice_before_all` | Rice takes priority, sometimes at the expense of duty or other cargo. |

Run `godot --headless --script tests/deputies.gd` to check deputy files.

Sample deputy (illustrative and abridged; a real file also needs the `inspection` and `purchasing` entries under `delegation_lines`):

```json
{
  "id": "pak_mamat",
  "name": "Pak Mamat",
  "role": "Roads pilot",
  "bio": "He knows the anchorage and its captains.",
  "skills": {"berth": 5, "inspection": 1, "purchasing": 1},
  "flaw": {"id": "old_favours", "text": "Captains he owes may jump the berth queue."},
  "delegation_lines": {
    "berth": {
      "assign": ["I'll take the boat out, Shahbandar."],
      "good": ["She's tied up and ready to unload."],
      "mixed": ["She's in, but the next ship has to wait."],
      "bad": ["She gave up waiting and sailed."]
    }
  },
  "notes": ["[GAMEPLAY] Pak Mamat is fictional."]
}
```

## Art

Use Godot-importable **SVG** for vector illustrations or **PNG** for raster art, at `res://assets/inspection/<lowercase-kebab-name>.<ext>`. Set `evidence[].image` to the full path; the game fits it without stretching in the evidence panel. The shipped placeholder is `lot-seven.svg` (2:1). Keep the evidence text sufficient without the illustration. No illustration is required to run.

Open/import the project in Godot to import new textures. If configuring a packaged build later, include `data/**/*.json` as non-resource files and include textures loaded through JSON paths.

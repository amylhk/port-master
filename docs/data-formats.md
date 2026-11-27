# Data authoring formats

Authoring data uses UTF-8 JSON objects under `res://data/`, read with `FileAccess` and `JSON.parse_string`. Required fields are listed below unless marked optional. Labels and prose are display text; keep IDs stable and unique within each collection. Use JSON `\n` for paragraph breaks.

| File | Object shape |
| --- | --- |
| `data/port_day.json` | `briefing` (text), `start_minute`, `end_minute`, `rice_target` (integers), `ships` (array ordered by arrival) |
| `data/manual/manual_stage_a.json` | `title` (text); `entries` (array of objects with `title` and `text`, in reading order) |
| `data/inspections/<id>.json` | `id`, `title`, `subtitle` (text); `minutes` (integer); `evidence`, `rulings`, `reasons` (arrays); `hidden_truth` (object) |
| `data/briefings/<id>.json` | One morning briefing per file: `id`, `title`, `body` (text); `day` (integer) or `trigger` (condition text); optional `requires`, `choices`, `notes` (arrays) |
| `data/events/<id>.json` | One evening event per file, same shape as a briefing |
| `data/departures/<id>.json` | One Stage B departure or tax event per file: evening event shape plus `merchant_id`, `chain_id` (text) and `step` (integer) |
| `data/history/<id>.json` | One Stage D historical event per file: departure-chain shape with `merchant_id` only for merchant-centred chains |
| `data/deputies/<id>.json` | One Stage B deputy per file: `id`, `name`, `role`, `bio` (text); `skills`, `flaw`, `delegation_lines` (objects); optional `notes` (array) |
| `data/offers/<id>.json` | One Stage B state purchasing offer per file: `id`, `merchant_id`, `title`, `body` (text); `day` (integer) or `trigger` (condition text); optional `requires`, `choices` (arrays) |

- **Ships:** `id`, `name`, `cargo` (text); `arrival` and `departure` (integers, minutes since midnight); `minutes` (positive unloading duration); `duty` (integer), `rice` (integer sacks); optional `inspection_case` is the case ID. Deadline times are the last minute a sale can complete. Optional `image` (ship sprite) and `cargo_image` (cargo icon) are full resource paths.
- **Registering inspections:** Put the case file in `data/inspections/` and add its ID (without `.json`) to the ship, e.g. `"inspection_case": "case_002"` loads `data/inspections/case_002.json`. The file's `id` must match. The day can reference multiple case IDs and fails to load if any referenced file is missing. Ships without `inspection_case` use normal berth assignment.
- **Port day art (optional):** `art` object in `data/port_day.json` with `backdrop` (harbour view), `banner` (screen header), `berth_marker` (berth plates) and `panel` (briefing parchment), each a full resource path.
- **Case art (optional):** `art` object in an inspection case with `desk` (inspection screen backdrop).
- **Evidence:** each page has `id`, `label` (short button text), `title`, and `text`. Optional `image` is the full Godot resource path. Put observations on the evidence pages and generally applicable conventions in the manual. The manifest describes what was declared, never the expected correct markings or an assessment.
- **Choices:** `rulings` and `reasons` must each contain at least one `id` and `label` pair. The current outcome handlers reserve `clear` for clearing as declared and `hold` for stopping the sale. A hold with the correct evidence is recorded separately in the closing ledger; it earns no duty and does not count as a lost sale. Other ruling IDs attempt an amendment.
- **Hidden truth:** `ruling_id` and `reason_id` identify the one successful combination. A successful amendment credits `extra_duty` only after unloading. `success`, `clear`, `unsupported`, and `hold` are feedback text shown only after filing. Keep all pre-ruling text independent of this object. This hides the answer in play, not from someone reading the JSON.


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

## Stage B departures and taxes

Put each departure-chain step in its own `data/departures/<id>.json` file. Use the evening event fields above, including exactly one of `day` or `trigger`, and add:

- `merchant_id`: the ID of an existing merchant in `data/merchants/`.
- `chain_id`: a stable ID shared by all steps in the chain.
- `step`: a positive integer, starting at 1 and increasing by 1 per step within the chain.

When a step plays, the game is to set `<chain_id>_step_<n>` for later days, even if the step has no choices. Each step after the first lists the previous step's flag in `requires`. For example, step 2 of `arus_account` requires `arus_account_step_1`. Use inspection outcome flags to gate the relevant first steps. Spell hold flags `case_00N_hold`, not `case_00N_held`, in both departures and evening events.

Choice effects can include integer `merchant_trust` deltas for the named merchant, in addition to `duty`, `supply` and `reputation`. Use optional `notes` lines prefixed with `fact:`, `inference:` or `gameplay:` to distinguish historical evidence from invented accounts and mechanics. The player is a shahbandar; file dues and customs rulings in the temenggung's name and label port-wide player authority as a gameplay abstraction.

Validate with `godot --headless --script tests/departures.gd`. These are Stage B authoring files; the Stage A main scene does not play them yet.

## Stage D historical chains

Put each step in its own `data/history/<id>.json` file. Reuse the departure-chain format above: `id`, `title`, `body`, exactly one of `day` or `trigger`, `chain_id`, integer `step`, and the evening-event `requires`, `choices` and `notes` arrays. Include `merchant_id` from `data/merchants/` on each step of a merchant-centred chain; omit it on port-wide chains. Choice effects are integer deltas for `duty`, `supply`, `reputation` and, only with a named merchant, `merchant_trust`.

Set `<chain_id>_step_<n>` when the step plays, regardless of choice. List the previous step's flag in `requires` for each step after the first; a chain may also require a flag from another chain. The main sequence is `sequeira_visit` → `captives_and_court` → `melaka_siege`. The day 4 and 5 briefings seed the first fleet's approach; the optional `ismail_pedir_warning` chain follows the 1511 messenger episode and starts only with `case_004_hold`. That flag does not gate the fleet's arrival or the finale. The Stage A day-1 inspection and evening-event fixtures are not the Stage D calendar.

The `day` values are compressed campaign slots, not historical dates. Record the dates and uncertainties in the prose and source notes. Use `fact:`, `inference:` and `gameplay:` notes to distinguish sources, interpretations and invented details. The player is a shahbandar; their port-wide authority is a gameplay abstraction, and dues and customs rulings are made in the temenggung's name. The fall of Melaka is the shared historical outcome; choices describe different local consequences and apply only the existing effect deltas.

Validate with `godot --headless --script tests/history.gd`. These files are Stage D authoring data; the Stage A scene does not schedule them.

## Stage B merchants

Write one UTF-8 JSON object per merchant in `data/merchants/<id>.json`, with exactly these fields:

| Field | Type and use |
| --- | --- |
| `id` | Stable, unique snake_case string matching the file name without `.json`. Offers and multi-day departure/tax chains reference this value as `merchant_id`. |
| `name`, `origin`, `bio` | Non-empty display strings: name, place or trade route, and a short fictional character biography. |
| `bloc` | One of `gujarati`, `kling_bengal_pegu_pasai`, `java_eastern_islands`, or `china_ryukyu_champa`. The bloc is a roster grouping, not necessarily the merchant's historical jurisdiction. |
| `ship_ids` | Non-empty array of ship ID strings. Use the exact `data/port_day.json` ID for a ship that already exists there. Planned ships use stable new IDs; a ship may be shared by its owner, factor, or captain. |
| `traits` | Non-empty array of short personality strings. |
| `notes` | Non-empty array of author-note strings. Each begins with `fact:`, `inference:`, or `gameplay:` and ends with its source in parentheses. Record ship types, cargoes, motives and arc hooks here. |

Use `fact:` for attested history, `inference:` for plausible extrapolation, and `gameplay:` for invented characters, motives, ships, and potential outcomes. The bio and traits describe fictional gameplay characters; distinguish any supporting historical background from these inventions in the notes. Seals, cargo marks, manifests and the player's port-wide authority are gameplay abstractions. The player is a shahbandar and files customs rulings in the temenggung's name.

Some research notes cited by this roster are still on separate research branches. Reference snapshots: [commodities](https://github.com/amylhk/port-master/blob/8b01dacbbacdc3b739f766322579761343d77779/docs/research/commodities.md), [ships, weights and currency](https://github.com/amylhk/port-master/blob/7f2e7589794ebd08c7ba0f894cfe38a42d1d36a3/docs/research/ships-weights-currency.md), [port officials](https://github.com/amylhk/port-master/blob/8d2af3d86744f425e987a734fbddca21e17d2c3f/docs/research/port-official.md), [seals, marks and packaging](https://github.com/amylhk/port-master/blob/d30f160dc2727677f3d4b2770fc5906d291f1e4f/docs/research/seals-marks-packaging.md), and [1511 events](https://github.com/amylhk/port-master/blob/26c9abb9568e1ef4baefcdd3feb9cf3c9e292df7/docs/research/1511-events.md).

Run `godot --headless --script tests/merchants.gd` to check the roster.

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

## Stage B state purchasing offers

Write one offer for the state/merchant panel per `data/offers/<id>.json`. The file name must match its unique `id`. Use an existing `data/merchants/` ID as `merchant_id` and name that merchant in the display text.

- `id`, `merchant_id`, `title`, and `body` are non-empty text. Use `\n\n` for paragraph breaks in the body.
- Set exactly one of `day` (positive integer) or `trigger` (non-empty condition string, e.g. `"day>=2"`). More than one offer can share a day.
- Optional `requires` lists named flags that must all be set, in addition to the day or trigger. The conditional offers reuse `rice_short_yesterday` and `ship_lost_yesterday` from the briefings.
- Optional `choices` contains objects with `id` (unique within the offer), `label` (button text), `outcome_text` (shown after choosing), and `effects` (object). Effects may include any of `duty`, `supply`, `reputation`, and `merchant_trust`, as integer deltas. Omit an effect for no change; use `{}` for no effects.

**[FACT]** Pires describes merchants bidding together and dividing cargo at an agreed price (*Suma Oriental*, Cortesão ed., pp. 273–274). He describes the temenggung sitting as Customs Judge and receiving merchandise dues (pp. 265, 273); in play, dues and customs rulings are made in the temenggung's name.

**[INFERENCE]** The specific cargo lots, buyers and competing needs in the offers are plausible reconstructions based on the commodity and trade-route notes linked under Stage B merchants.

**[GAMEPLAY]** The player is a shahbandar; their port-wide authority and the state's right to buy at the normal market price before public sale are abstractions, not attested powers. The deals and their outcomes are fictional. Negative `duty` in a purchase represents public coin spent, not a change to a historical tariff. `supply` measures the benefit to state stores, not a count of physical units; `reputation` measures standing in the port, while `merchant_trust` applies to the named seller.

Run `godot --headless --script tests/offers.gd` to check offer files. Sample offer (illustrative):

```json
{
  "id": "sample_rice_offer",
  "merchant_id": "jaka_wira",
  "day": 1,
  "title": "Rice on the quay",
  "body": "Jaka Wira offers the state a share of his rice before the stallholders buy.",
  "choices": [
    {
      "id": "buy_share",
      "label": "Buy a share for the granary",
      "outcome_text": "Jaka is paid at the market price. The stalls take the remaining sacks.",
      "effects": {"duty": -3, "supply": 4, "merchant_trust": 1}
    },
    {
      "id": "pass",
      "label": "Leave the lot to the stalls",
      "outcome_text": "The stalls take all the rice. The granary keeps its coin but adds no stock.",
      "effects": {"reputation": 1}
    }
  ]
}
```

## Art

Use Godot-importable **SVG** for vector illustrations or **PNG** for raster art, at `res://assets/inspection/<lowercase-kebab-name>.<ext>`. Set `evidence[].image` to the full path; the game fits it without stretching in the evidence panel. The shipped placeholder is `lot-seven.svg` (2:1). Keep the evidence text sufficient without the illustration. No illustration is required to run.

Every art path is optional: when a path is absent or does not resolve, the game shows the ship's cargo text (harbour view) or the text alone and logs a warning. Stage A art lives under `res://assets/art/` (see `docs/art-style-guide.md` for sizes); the harbour view places ship sprites on the 1280×720 backdrop's berths and anchorage.

Open/import the project in Godot to import new textures. If configuring a packaged build later, include `data/**/*.json` as non-resource files and include textures loaded through JSON paths.

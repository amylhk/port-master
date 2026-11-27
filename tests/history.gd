extends SceneTree

const DIR := "res://data/history"
const MERCHANTS_DIR := "res://data/merchants"
const FACTIONS_DIR := "res://data/factions"
const EVENT_KEYS := ["id", "title", "body", "day", "trigger", "requires", "conditions", "priority", "choices", "notes", "chain_id", "step", "merchant_id"]
const EFFECT_KEYS := ["duty", "supply", "reputation", "merchant_trust"]

var failures := 0
var bare_condition := RegEx.create_from_string("^(duty|supply|reputation)(>=|<=|>|<|==)(-?[0-9]+)$")
var qualified_condition := RegEx.create_from_string("^(merchant_trust|faction_standing)\\.([a-z][a-z0-9]*(?:_[a-z0-9]+)*)(>=|<=|>|<|==)(-?[0-9]+)$")


func _initialize() -> void:
    var chains := {}
    var steps_by_flag := {}
    var priorities_by_day := {}
    var count := 0
    for file in DirAccess.get_files_at(DIR):
        if not file.ends_with(".json"):
            continue
        count += 1
        var path := DIR.path_join(file)
        var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
        if not data is Dictionary:
            _fail(path, "must be a JSON object")
            continue
        _check_event(path, data)
        var chain: Variant = data.get("chain_id")
        var value: Variant = data.get("step")
        if not _has_text(chain) or not _is_integer(value) or value < 1:
            _fail(path, "needs a chain_id and a positive integer step")
            continue
        var step := int(value)
        var merchant: Variant = data.get("merchant_id")
        if not chains.has(chain):
            chains[chain] = {"merchant_id": merchant, "steps": {}}
        elif chains[chain]["merchant_id"] != merchant:
            _fail(path, "merchant_id must be consistent within a chain")
        var steps: Dictionary = chains[chain]["steps"]
        if steps.has(step):
            _fail(path, "duplicate step %d in chain %s" % [step, chain])
            continue
        steps[step] = true
        var requirements: Variant = data.get("requires", [])
        if not requirements is Array:
            _fail(path, "requires must be an array")
            requirements = []
        if step > 1 and not requirements.has("%s_step_%d" % [chain, step - 1]):
            _fail(path, "requires must include %s_step_%d" % [chain, step - 1])
        var flag := "%s_step_%d" % [chain, step]
        steps_by_flag[flag] = {"path": path, "day": data.get("day"), "requires": requirements}
        if data.has("priority") and _is_integer(data["priority"]) and data["priority"] >= 1 and _is_integer(data.get("day")):
            var day_key := int(data["day"])
            var priority_val := int(data["priority"])
            if not priorities_by_day.has(day_key):
                priorities_by_day[day_key] = {}
            if priorities_by_day[day_key].has(priority_val):
                _fail(path, "duplicate priority %d on day %d" % [priority_val, day_key])
            else:
                priorities_by_day[day_key][priority_val] = path

    for chain in chains:
        var steps: Dictionary = chains[chain]["steps"]
        for step in range(1, steps.size() + 1):
            if not steps.has(step):
                _fail(chain, "missing step %d" % step)
    for event in steps_by_flag.values():
        for flag in event["requires"]:
            if not _has_text(flag):
                _fail(event["path"], "requires holds flag names")
            elif flag.ends_with("_held"):
                _fail(event["path"], "use _hold, not _held, for %s" % flag)
            elif "_step_" in flag:
                if not steps_by_flag.has(flag):
                    _fail(event["path"], "unknown history step flag %s" % flag)
                else:
                    var prior_day: Variant = steps_by_flag[flag]["day"]
                    if _is_integer(prior_day) and _is_integer(event["day"]) and prior_day >= event["day"]:
                        _fail(event["path"], "%s must play on an earlier day" % flag)
    if count == 0:
        _fail(DIR, "no history steps")
    if failures == 0:
        print("History checks passed: %d files in %d chains." % [count, chains.size()])
    quit(1 if failures else 0)


func _check_event(path: String, data: Dictionary) -> void:
    for key in data:
        if not key in EVENT_KEYS:
            _fail(path, "unknown field %s" % key)
    for key in ["id", "title", "body"]:
        if not _has_text(data.get(key)):
            _fail(path, "needs text field %s" % key)
    if data.get("id") != path.get_file().get_basename():
        _fail(path, "file name must be <id>.json")
    if data.has("day") == data.has("trigger"):
        _fail(path, "needs exactly one of day or trigger")
    elif data.has("day"):
        if not _is_integer(data["day"]) or data["day"] < 1:
            _fail(path, "day must be a positive integer")
    elif not _has_text(data["trigger"]):
        _fail(path, "trigger must be text")
    if data.has("merchant_id"):
        var merchant_id: Variant = data["merchant_id"]
        if not _has_text(merchant_id):
            _fail(path, "merchant_id must be text")
        elif not _id_exists(MERCHANTS_DIR, merchant_id):
            _fail(path, "unknown merchant_id %s" % merchant_id)
    if data.has("conditions"):
        _check_conditions(path, data["conditions"])
    if data.has("priority"):
        if not _is_integer(data["priority"]) or data["priority"] < 1:
            _fail(path, "priority must be a positive integer")
    var notes: Variant = data.get("notes")
    if not notes is Array or notes.is_empty():
        _fail(path, "needs source or gameplay notes")
    else:
        for note in notes:
            if not _has_text(note) or not (note.begins_with("fact:") or note.begins_with("inference:") or note.begins_with("gameplay:")):
                _fail(path, "each note must start with fact:, inference: or gameplay:")
    _check_choices(path, data.get("choices", []), data.has("merchant_id"))


func _check_choices(path: String, choices: Variant, has_merchant: bool) -> void:
    if not choices is Array:
        _fail(path, "choices must be an array")
        return
    var ids := {}
    for choice in choices:
        if not choice is Dictionary:
            _fail(path, "each choice must be an object")
            continue
        for key in choice:
            if not key in ["id", "label", "outcome_text", "effects"]:
                _fail(path, "unknown choice field %s" % key)
        for key in ["id", "label", "outcome_text"]:
            if not _has_text(choice.get(key)):
                _fail(path, "choice needs text field %s" % key)
        var id: Variant = choice.get("id")
        if _has_text(id):
            if ids.has(id):
                _fail(path, "duplicate choice id %s" % id)
            ids[id] = true
        var effects: Variant = choice.get("effects")
        if not effects is Dictionary:
            _fail(path, "choice needs an effects object")
            continue
        for key in effects:
            if key == "faction_standing":
                var standings: Variant = effects[key]
                if not standings is Dictionary or standings.is_empty():
                    _fail(path, "faction_standing must map faction IDs to integer deltas")
                    continue
                for faction_id in standings:
                    if not _id_exists(FACTIONS_DIR, faction_id) or not _is_integer(standings[faction_id]):
                        _fail(path, "invalid faction_standing delta for %s" % faction_id)
            elif not key in EFFECT_KEYS or not _is_integer(effects[key]):
                _fail(path, "effect %s must be an integer duty, supply, reputation or merchant_trust delta" % key)
            elif key == "merchant_trust" and not has_merchant:
                _fail(path, "merchant_trust requires merchant_id")


func _check_conditions(path: String, conditions: Variant) -> void:
    if not conditions is Array:
        _fail(path, "conditions must be an array")
        return
    for entry in conditions:
        if not _has_text(entry):
            _fail(path, "conditions holds condition strings")
            continue
        if bare_condition.search(entry):
            continue
        var matched := qualified_condition.search(entry)
        if matched == null:
            _fail(path, "invalid condition %s" % entry)
            continue
        var stat := matched.get_string(1)
        var target_id := matched.get_string(2)
        if stat == "merchant_trust" and not _id_exists(MERCHANTS_DIR, target_id):
            _fail(path, "condition references unknown merchant_id %s" % target_id)
        elif stat == "faction_standing" and not _id_exists(FACTIONS_DIR, target_id):
            _fail(path, "condition references unknown faction_id %s" % target_id)


func _id_exists(dir: String, target_id: String) -> bool:
    var target_path := dir.path_join(target_id + ".json")
    if not FileAccess.file_exists(target_path):
        return false
    var record: Variant = JSON.parse_string(FileAccess.get_file_as_string(target_path))
    return record is Dictionary and record.get("id") == target_id


func _has_text(value: Variant) -> bool:
    return value is String and not value.strip_edges().is_empty()


func _is_integer(value: Variant) -> bool:
    return value is float and is_finite(value) and value == floor(value)


func _fail(path: String, message: String) -> void:
    failures += 1
    push_error("FAILED: %s: %s" % [path, message])

extends SceneTree

const DIR := "res://data/departures"
const MERCHANTS_DIR := "res://data/merchants"
const EVENTS_DIR := "res://data/events"
const EFFECT_KEYS := ["duty", "supply", "reputation", "merchant_trust"]

var failures := 0


func _initialize() -> void:
    var ids := {}
    var chains := {}
    var count := 0
    for file in DirAccess.get_files_at(DIR):
        if not file.ends_with(".json"):
            continue
        count += 1
        var path := DIR.path_join(file)
        var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
        if not data is Dictionary:
            _fail("%s is not a JSON object" % path)
            continue
        for key in ["id", "title", "body", "merchant_id", "chain_id"]:
            if not _has_text(data.get(key)):
                _fail("%s needs text field %s" % [path, key])
        if _has_text(data.get("id")):
            var id: String = data["id"]
            if id + ".json" != file:
                _fail("%s: file name must be <id>.json" % path)
            if ids.has(id):
                _fail("%s: duplicate id %s" % [path, id])
            ids[id] = true
        if _has_text(data.get("merchant_id")):
            var merchant_id: String = data["merchant_id"]
            var merchant_path := MERCHANTS_DIR.path_join(merchant_id + ".json")
            var merchant: Variant = JSON.parse_string(FileAccess.get_file_as_string(merchant_path))
            if not merchant is Dictionary or merchant.get("id") != merchant_id:
                _fail("%s: unknown merchant_id %s" % [path, merchant_id])
        if data.has("day") == data.has("trigger"):
            _fail("%s needs exactly one of day or trigger" % path)
        elif data.has("day"):
            if not _is_integer(data["day"]) or data["day"] < 1:
                _fail("%s: day must be a positive integer" % path)
        elif not _has_text(data["trigger"]):
            _fail("%s: trigger must be text" % path)
        var requirements := _check_requires(path, data.get("requires", []))
        _check_choices(path, data.get("choices", []))
        if data.has("notes"):
            _check_notes(path, data["notes"])
        var value: Variant = data.get("step")
        if not _is_integer(value) or value < 1:
            _fail("%s: step must be a positive integer" % path)
        elif _has_text(data.get("chain_id")):
            var chain_id: String = data["chain_id"]
            var step := int(value)
            if not chains.has(chain_id):
                chains[chain_id] = {}
            if chains[chain_id].has(step):
                _fail("%s: duplicate step %d in chain %s" % [path, step, chain_id])
            chains[chain_id][step] = true
            if step > 1:
                var previous := "%s_step_%d" % [chain_id, step - 1]
                if not requirements.has(previous):
                    _fail("%s: requires must include %s" % [path, previous])
    for chain_id in chains:
        var steps: Dictionary = chains[chain_id]
        for step in range(1, steps.size() + 1):
            if not steps.has(step):
                _fail("%s: missing step %d" % [chain_id, step])
    for file in DirAccess.get_files_at(EVENTS_DIR):
        if file.ends_with(".json"):
            var path := EVENTS_DIR.path_join(file)
            var event: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
            if not event is Dictionary:
                _fail("%s is not a JSON object" % path)
            else:
                _check_requires(path, event.get("requires", []))
    if count == 0:
        _fail("no departures in " + DIR)
    if failures == 0:
        print("Departure checks passed: %d files in %d chains; evening event hold flags normalized." % [count, chains.size()])
    quit(1 if failures else 0)


func _check_requires(path: String, requirements: Variant) -> Array:
    if not requirements is Array:
        _fail("%s: requires must be an array" % path)
        return []
    for flag in requirements:
        if not _has_text(flag):
            _fail("%s: requires holds flag names" % path)
        elif flag.ends_with("_held"):
            _fail("%s: use _hold, not _held, for %s" % [path, flag])
    return requirements


func _check_choices(path: String, choices: Variant) -> void:
    if not choices is Array:
        _fail("%s: choices must be an array" % path)
        return
    var ids := {}
    for choice in choices:
        if not choice is Dictionary:
            _fail("%s: each choice must be an object" % path)
            continue
        for key in ["id", "label", "outcome_text"]:
            if not _has_text(choice.get(key)):
                _fail("%s: choice needs text field %s" % [path, key])
        if _has_text(choice.get("id")):
            var id: String = choice["id"]
            if ids.has(id):
                _fail("%s: duplicate choice id %s" % [path, id])
            ids[id] = true
        if not choice.get("effects") is Dictionary:
            _fail("%s: choice %s needs an effects object" % [path, choice.get("id")])
            continue
        for key in choice["effects"]:
            if not key in EFFECT_KEYS or not _is_integer(choice["effects"][key]):
                _fail("%s: effect %s must be an integer duty, supply, reputation or merchant_trust delta" % [path, key])


func _check_notes(path: String, notes: Variant) -> void:
    if not notes is Array:
        _fail("%s: notes must be an array" % path)
        return
    for note in notes:
        if not _has_text(note) or not (note.begins_with("fact:") or note.begins_with("inference:") or note.begins_with("gameplay:")):
            _fail("%s: each note must start with fact:, inference: or gameplay:" % path)


func _has_text(value: Variant) -> bool:
    return value is String and not value.strip_edges().is_empty()


func _is_integer(value: Variant) -> bool:
    return value is float and is_finite(value) and value == floor(value)


func _fail(message: String) -> void:
    failures += 1
    push_error("FAILED: " + message)

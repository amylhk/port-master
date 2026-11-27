extends SceneTree

const DIR := "res://data/briefings"
const EFFECT_KEYS := ["duty", "supply", "reputation"]

var failures := 0


func _initialize() -> void:
    var files := DirAccess.get_files_at(DIR)
    var ids := {}
    var days := {}
    var count := 0
    for file in files:
        if not file.ends_with(".json"):
            continue
        count += 1
        var path := DIR.path_join(file)
        var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
        if not data is Dictionary:
            _fail("%s is not a JSON object" % path)
            continue
        for key in ["id", "title", "body"]:
            if not data.get(key) is String or data[key].is_empty():
                _fail("%s needs text field %s" % [path, key])
        if data.get("id", "") + ".json" != file:
            _fail("%s: file name must be <id>.json" % path)
        if ids.has(data.get("id")):
            _fail("%s: duplicate id" % path)
        ids[data.get("id")] = true
        var has_day: bool = data.has("day")
        if has_day == data.has("trigger"):
            _fail("%s needs exactly one of day or trigger" % path)
        elif has_day:
            if not (data["day"] is float and data["day"] == floor(data["day"]) and data["day"] >= 1):
                _fail("%s: day must be a positive integer" % path)
            elif days.has(data["day"]):
                _fail("%s: day %d already has a briefing" % [path, data["day"]])
            days[data.get("day")] = true
        elif not data["trigger"] is String or data["trigger"].is_empty():
            _fail("%s: trigger must be text" % path)
        for flag in data.get("requires", []):
            if not flag is String or flag.is_empty():
                _fail("%s: requires holds flag names" % path)
        var choice_ids := {}
        for choice in data.get("choices", []):
            if not choice is Dictionary:
                _fail("%s: each choice is an object" % path)
                continue
            for key in ["id", "label", "outcome_text"]:
                if not choice.get(key) is String or choice[key].is_empty():
                    _fail("%s: choice needs text field %s" % [path, key])
            if choice_ids.has(choice.get("id")):
                _fail("%s: duplicate choice id" % path)
            choice_ids[choice.get("id")] = true
            if not choice.get("effects") is Dictionary:
                _fail("%s: choice %s needs effects" % [path, choice.get("id")])
                continue
            for key in choice["effects"]:
                var value: Variant = choice["effects"][key]
                if not key in EFFECT_KEYS or not (value is float and value == floor(value)):
                    _fail("%s: effect %s must be an integer duty, supply or reputation delta" % [path, key])
    if count == 0:
        _fail("no briefings in " + DIR)
    if failures == 0:
        print("Briefing checks passed: %d files, %d by day." % [count, days.size()])
    quit(1 if failures else 0)


func _fail(message: String) -> void:
    failures += 1
    push_error("FAILED: " + message)

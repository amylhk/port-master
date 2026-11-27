extends SceneTree

const DIR := "res://data/offers"
const MERCHANT_DIR := "res://data/merchants"
const EFFECT_KEYS := ["duty", "supply", "reputation", "merchant_trust"]

var failures := 0


func _initialize() -> void:
    var merchant_ids := {}
    for file in DirAccess.get_files_at(MERCHANT_DIR):
        if not file.ends_with(".json"):
            continue
        var merchant: Variant = JSON.parse_string(FileAccess.get_file_as_string(MERCHANT_DIR.path_join(file)))
        if merchant is Dictionary and _has_text(merchant.get("id")) and file == merchant["id"] + ".json":
            merchant_ids[merchant["id"]] = true

    var ids := {}
    var count := 0
    for file in DirAccess.get_files_at(DIR):
        if not file.ends_with(".json"):
            continue
        count += 1
        var path := DIR.path_join(file)
        var offer: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
        if not offer is Dictionary:
            _fail("%s is not a JSON object" % path)
            continue
        for key in ["id", "merchant_id", "title", "body"]:
            if not _has_text(offer.get(key)):
                _fail("%s needs text field %s" % [path, key])
        var id: Variant = offer.get("id")
        if _has_text(id):
            if id + ".json" != file:
                _fail("%s: file name must be <id>.json" % path)
            if ids.has(id):
                _fail("%s: duplicate id %s" % [path, id])
            ids[id] = true
        var merchant_id: Variant = offer.get("merchant_id")
        if _has_text(merchant_id) and not merchant_ids.has(merchant_id):
            _fail("%s: unknown merchant_id %s" % [path, merchant_id])
        _check_schedule(path, offer)
        _check_choices(path, offer.get("choices", []))
    if count == 0:
        _fail("no offers in " + DIR)
    if failures == 0:
        print("Offer checks passed: %d files." % count)
    quit(1 if failures else 0)


func _check_schedule(path: String, offer: Dictionary) -> void:
    var has_day := offer.has("day")
    if has_day == offer.has("trigger"):
        _fail("%s needs exactly one of day or trigger" % path)
    elif has_day:
        if not _is_integer(offer["day"]) or offer["day"] < 1:
            _fail("%s: day must be a positive integer" % path)
    elif not _has_text(offer["trigger"]):
        _fail("%s: trigger must be non-empty text" % path)

    var flags: Variant = offer.get("requires", [])
    if not flags is Array:
        _fail("%s: requires must be an array" % path)
        return
    for flag in flags:
        if not _has_text(flag):
            _fail("%s: requires holds non-empty flag names" % path)


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
        var id: Variant = choice.get("id")
        if _has_text(id):
            if ids.has(id):
                _fail("%s: duplicate choice id %s" % [path, id])
            ids[id] = true
        var effects: Variant = choice.get("effects")
        if not effects is Dictionary:
            _fail("%s: choice %s needs an effects object" % [path, id])
            continue
        for key in effects:
            if key not in EFFECT_KEYS:
                _fail("%s: choice %s has unknown effect %s" % [path, id, key])
            elif not _is_integer(effects[key]):
                _fail("%s: choice %s effect %s must be an integer delta" % [path, id, key])


func _is_integer(value: Variant) -> bool:
    return value is float and is_finite(value) and value == floor(value)


func _has_text(value: Variant) -> bool:
    return value is String and not value.strip_edges().is_empty()


func _fail(message: String) -> void:
    failures += 1
    push_error("FAILED: " + message)

extends SceneTree

const HINTS_PATH := "res://data/hints/day_1.json"
const SHORT_PATH := "res://data/short/day_1.json"
const HINT_IDS := [
    "first_ship", "berth_free", "tide_warning", "anchorage_full",
    "inspect_berthed", "open_cargo", "check_manual", "stamp", "day_end",
]

var cjk := RegEx.create_from_string("[㐀-鿿]")


func _initialize() -> void:
    var hints: Variant = JSON.parse_string(FileAccess.get_file_as_string(HINTS_PATH))
    if not hints is Array or hints.size() != HINT_IDS.size():
        _fail("Expected %d hints in %s." % [HINT_IDS.size(), HINTS_PATH])
        return

    var remaining := HINT_IDS.duplicate()
    for hint in hints:
        if not hint is Dictionary or hint.size() != 2:
            _fail("Each hint must be an object with id and text.")
            return
        var id: Variant = hint.get("id")
        var line: Variant = hint.get("text")
        if not id is String or not remaining.has(id):
            _fail("Unexpected or duplicate hint ID: %s." % str(id))
            return
        if not _check_length(line, 14, "hint " + id):
            quit(1)
            return
        remaining.erase(id)

    print("Day 1 hint checks passed: %d hints, up to 14 characters each." % hints.size())
    if not _check_short_text():
        quit(1)
        return
    quit()


func _check_short_text() -> bool:
    var short: Variant = _read_json(SHORT_PATH)
    if not _check_keys(short, ["briefings", "ships", "cases", "events"], SHORT_PATH):
        return false

    var port: Dictionary = _read_json("res://data/port_day.json")
    var ships := {}
    var cases := {}
    for ship in port["ships"]:
        ships[ship["id"]] = ship
        if ship.has("inspection_case"):
            var case_id: String = ship["inspection_case"]
            cases[case_id] = _read_json("res://data/inspections/%s.json" % case_id)
    var briefings := _day_one_stories("res://data/briefings")
    briefings["port_day"] = port
    var events := _day_one_stories("res://data/events")
    if not _check_entries(short["briefings"], briefings, "briefings"):
        return false
    if not _check_entries(short["ships"], ships, "ships"):
        return false
    if not _check_entries(short["cases"], cases, "cases", {"evidence": 24, "rulings": 8}):
        return false
    if not _check_entries(short["events"], events, "events", {"choices": 8}):
        return false

    print("Day 1 short text checks passed: %d briefings, %d ships, %d cases, %d events." % [
        briefings.size(), ships.size(), cases.size(), events.size(),
    ])
    return true


func _check_entries(entries: Variant, sources: Dictionary, section: String, limits := {}) -> bool:
    if not _check_keys(entries, sources.keys(), section):
        return false
    for id in sources:
        var location := "%s/%s" % [section, id]
        var entry: Variant = entries[id]
        if not entry is Dictionary:
            return _invalid("%s must be an object." % location)
        var fields := ["line"] + limits.keys()
        if section != "ships" and entry.has("speaker_id"):
            fields.append("speaker_id")
            var speaker: Variant = entry["speaker_id"]
            if not speaker is String or not speaker.is_valid_filename() or not FileAccess.file_exists(
                "res://assets/art/portraits/%s.png" % speaker
            ):
                return _invalid("%s must name an existing speaker portrait." % location)
        if not _check_keys(entry, fields, location):
            return false
        if not _check_length(entry["line"], 30, location + "/line"):
            return false
        for field in limits:
            var ids := []
            for item in sources[id].get(field, []):
                ids.append(item["id"])
            if not _check_keys(entry[field], ids, location + "/" + field):
                return false
            for item_id in ids:
                if not _check_length(entry[field][item_id], limits[field], "%s/%s/%s" % [location, field, item_id]):
                    return false
    return true


func _check_keys(value: Variant, keys: Array, location: String) -> bool:
    if not value is Dictionary or value.size() != keys.size() or not value.has_all(keys):
        return _invalid("%s must contain exactly these keys: %s." % [location, str(keys)])
    return true


func _check_length(value: Variant, limit: int, location: String) -> bool:
    if not value is String or value.length() > limit or cjk.search(value) == null:
        return _invalid("%s must contain Chinese text and at most %d characters." % [location, limit])
    return true


func _day_one_stories(directory: String) -> Dictionary:
    var stories := {}
    for file in DirAccess.get_files_at(directory):
        if file.ends_with(".json"):
            var story: Dictionary = _read_json(directory.path_join(file))
            if story.get("day") == 1:
                stories[story["id"]] = story
    return stories


func _read_json(path: String) -> Variant:
    return JSON.parse_string(FileAccess.get_file_as_string(path))


func _invalid(message: String) -> bool:
    push_error(message)
    return false


func _fail(message: String) -> void:
    push_error(message)
    quit(1)

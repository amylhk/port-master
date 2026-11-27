extends SceneTree

const DIR := "res://data/deputies"
const TASKS := ["berth", "inspection", "purchasing"]
const LINE_KEYS := ["assign", "good", "mixed", "bad"]

var failures := 0


func _initialize() -> void:
    var ids := {}
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
        for key in ["id", "name", "role", "bio"]:
            if not _has_text(data.get(key)):
                _fail("%s needs text field %s" % [path, key])
        if _has_text(data.get("id")):
            var id: String = data["id"]
            if id + ".json" != file:
                _fail("%s: file name must be <id>.json" % path)
            if ids.has(id):
                _fail("%s: duplicate id" % path)
            ids[id] = true
        _check_skills(path, data.get("skills"))
        var flaw: Variant = data.get("flaw")
        if not flaw is Dictionary or not _has_text(flaw.get("id")) or not _has_text(flaw.get("text")):
            _fail("%s: flaw needs text fields id and text" % path)
        _check_lines(path, data.get("delegation_lines"))
        if data.has("notes"):
            _check_notes(path, data["notes"])
    if count == 0:
        _fail("no deputies in " + DIR)
    if failures == 0:
        print("Deputy checks passed: %d files." % count)
    quit(1 if failures else 0)


func _check_skills(path: String, skills: Variant) -> void:
    if not skills is Dictionary or skills.size() != TASKS.size() or not skills.has_all(TASKS):
        _fail("%s: skills needs exactly berth, inspection and purchasing" % path)
        return
    for task in TASKS:
        var value: Variant = skills[task]
        if not (value is float and value == floor(value) and value >= 0 and value <= 5):
            _fail("%s: skill %s must be an integer from 0 to 5" % [path, task])


func _check_lines(path: String, lines: Variant) -> void:
    if not lines is Dictionary or lines.size() != TASKS.size() or not lines.has_all(TASKS):
        _fail("%s: delegation_lines needs exactly berth, inspection and purchasing" % path)
        return
    for task in TASKS:
        var task_lines: Variant = lines[task]
        if not task_lines is Dictionary:
            _fail("%s: delegation_lines.%s must be an object" % [path, task])
            continue
        for key in LINE_KEYS:
            var variants: Variant = task_lines.get(key)
            var field := "%s: delegation_lines.%s.%s" % [path, task, key]
            if not variants is Array or variants.is_empty():
                _fail("%s must be a non-empty array of lines" % field)
                continue
            for line in variants:
                if not _has_text(line):
                    _fail("%s must contain only non-empty text" % field)


func _check_notes(path: String, notes: Variant) -> void:
    if not notes is Array:
        _fail("%s: notes must be an array" % path)
        return
    for note in notes:
        if not note is String or not (note.begins_with("[FACT]") or note.begins_with("[INFERENCE]") or note.begins_with("[GAMEPLAY]")):
            _fail("%s: each note must start with [FACT], [INFERENCE] or [GAMEPLAY]" % path)


func _has_text(value: Variant) -> bool:
    return value is String and not value.strip_edges().is_empty()


func _fail(message: String) -> void:
    failures += 1
    push_error("FAILED: " + message)

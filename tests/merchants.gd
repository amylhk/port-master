extends SceneTree

const DIR := "res://data/merchants"
const TEXT_FIELDS := ["id", "name", "bloc", "origin", "bio"]
const LIST_FIELDS := ["ship_ids", "traits", "notes"]
const BLOCS := ["gujarati", "kling_bengal_pegu_pasai", "java_eastern_islands", "china_ryukyu_champa"]

var failures := 0


func _initialize() -> void:
    var ids := {}
    var blocs_seen := {}
    var count := 0
    var id_pattern := RegEx.create_from_string("^[a-z][a-z0-9]*(_[a-z0-9]+)*$")
    var note_pattern := RegEx.create_from_string("^(fact|inference|gameplay): +[^ ]+.* +\\([^()]+\\)$")
    for file in DirAccess.get_files_at(DIR):
        if not file.ends_with(".json"):
            continue
        count += 1
        var path := DIR.path_join(file)
        var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
        if not data is Dictionary:
            _fail("%s is not a JSON object" % path)
            continue
        for key in data:
            if key not in TEXT_FIELDS and key not in LIST_FIELDS:
                _fail("%s: unexpected field %s" % [path, key])
        for key in TEXT_FIELDS:
            if not _has_text(data.get(key)):
                _fail("%s: %s must be non-empty text" % [path, key])
        var id: Variant = data.get("id")
        if id is String:
            if not id_pattern.search(id) or file != id + ".json":
                _fail("%s: file name must match its snake_case id" % path)
            if ids.has(id):
                _fail("%s: duplicate id %s" % [path, id])
            ids[id] = true
        var bloc: Variant = data.get("bloc")
        if bloc not in BLOCS:
            _fail("%s: unknown bloc %s" % [path, bloc])
        else:
            blocs_seen[bloc] = true
        for key in LIST_FIELDS:
            var entries: Variant = data.get(key)
            if not entries is Array or entries.is_empty():
                _fail("%s: %s must be a non-empty array" % [path, key])
                continue
            for entry in entries:
                if not _has_text(entry):
                    _fail("%s: %s entries must be non-empty text" % [path, key])
                elif key == "notes" and not note_pattern.search(entry):
                    _fail("%s: each note needs a fact:, inference:, or gameplay: label and a parenthesized source" % path)
    for bloc in BLOCS:
        if not blocs_seen.has(bloc):
            _fail("no merchants in bloc " + bloc)
    if failures == 0:
        print("Merchant checks passed: %d files across %d blocs." % [count, blocs_seen.size()])
    quit(1 if failures else 0)


func _has_text(value: Variant) -> bool:
    return value is String and not value.strip_edges().is_empty()


func _fail(message: String) -> void:
    failures += 1
    push_error("FAILED: " + message)

extends SceneTree

const FACTIONS := "res://data/factions"
const CHARACTERS := "res://data/characters"
const MERCHANTS := "res://data/merchants"
const FACTION_TEXT := ["id", "name", "kind", "leader_id", "bio"]
const CHARACTER_TEXT := ["id", "name", "faction_id", "role", "origin", "bio"]
const KINDS := ["guild", "merchant_network", "household", "court_circle", "quarter", "expedition"]
const BLOCS := ["gujarati", "kling_bengal_pegu_pasai", "java_eastern_islands", "china_ryukyu_champa"]

var failures := 0
var id_pattern := RegEx.create_from_string("^[a-z][a-z0-9]*(_[a-z0-9]+)*$")
var note_pattern := RegEx.create_from_string("^(fact|inference|gameplay): +[^ ]+.* +\\([^()]+\\)$")


func _initialize() -> void:
    var people_ids := {}
    for path in _json_paths(MERCHANTS):
        var data := _read_object(path)
        _register_id(path, data.get("id"), people_ids)

    var faction_ids := {}
    var factions := {}
    for path in _json_paths(FACTIONS):
        var data := _read_object(path)
        _check_fields(path, data, FACTION_TEXT, ["bloc", "member_ids", "goals", "notes"])
        _register_id(path, data.get("id"), faction_ids)
        if data.get("kind") not in KINDS:
            _fail("%s: unknown kind %s" % [path, data.get("kind")])
        if not data.has("bloc") or (data["bloc"] != null and data["bloc"] not in BLOCS):
            _fail("%s: bloc must be a merchant bloc or null" % path)
        _check_list(path, "goals", data.get("goals"))
        _check_list(path, "notes", data.get("notes"))
        factions[path] = data

    var character_paths := _json_paths(CHARACTERS)
    for path in character_paths:
        var data := _read_object(path)
        _check_fields(path, data, CHARACTER_TEXT, ["traits", "notes"])
        _register_id(path, data.get("id"), people_ids)
        _check_list(path, "traits", data.get("traits"))
        _check_list(path, "notes", data.get("notes"))
        _check_reference(path, "faction_id", data.get("faction_id"), faction_ids)

    for path in factions:
        var data: Dictionary = factions[path]
        _check_reference(path, "leader_id", data.get("leader_id"), people_ids)
        var members: Variant = data.get("member_ids")
        if not members is Array:
            _fail("%s: member_ids must be an array" % path)
        else:
            for member in members:
                _check_reference(path, "member_ids", member, people_ids)

    if failures == 0:
        print("Faction checks passed: %d factions and %d characters." % [factions.size(), character_paths.size()])
    quit(1 if failures else 0)


func _json_paths(dir: String) -> Array[String]:
    var paths: Array[String] = []
    for file in DirAccess.get_files_at(dir):
        if file.ends_with(".json"):
            paths.append(dir.path_join(file))
    if paths.is_empty():
        _fail("%s: no JSON files" % dir)
    return paths


func _read_object(path: String) -> Dictionary:
    var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
    if not data is Dictionary:
        _fail("%s is not a JSON object" % path)
        return {}
    return data


func _check_fields(path: String, data: Dictionary, text_fields: Array, other_fields: Array) -> void:
    for key in data:
        if key not in text_fields and key not in other_fields:
            _fail("%s: unexpected field %s" % [path, key])
    for key in text_fields:
        if not _has_text(data.get(key)):
            _fail("%s: %s must be non-empty text" % [path, key])


func _register_id(path: String, id: Variant, ids: Dictionary) -> void:
    if not id is String or not id_pattern.search(id) or path.get_file() != id + ".json":
        _fail("%s: file name must match its snake_case id" % path)
        return
    if ids.has(id):
        _fail("%s: duplicate id %s (also used by %s)" % [path, id, ids[id]])
    else:
        ids[id] = path


func _check_list(path: String, key: String, entries: Variant) -> void:
    if not entries is Array or entries.is_empty():
        _fail("%s: %s must be a non-empty array" % [path, key])
        return
    for entry in entries:
        if not _has_text(entry):
            _fail("%s: %s entries must be non-empty text" % [path, key])
        elif key == "notes" and not note_pattern.search(entry):
            _fail("%s: each note needs a fact:, inference:, or gameplay: label and a parenthesized source" % path)


func _check_reference(path: String, key: String, id: Variant, ids: Dictionary) -> void:
    if not _has_text(id) or not ids.has(id):
        _fail("%s: %s has an unresolved id: %s" % [path, key, id])


func _has_text(value: Variant) -> bool:
    return value is String and not value.strip_edges().is_empty()


func _fail(message: String) -> void:
    failures += 1
    push_error("FAILED: " + message)

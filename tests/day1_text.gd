extends SceneTree

const HINTS_PATH := "res://data/hints/day_1.json"
const HINT_IDS := [
    "first_ship", "berth_free", "tide_warning", "anchorage_full",
    "open_cargo", "check_manual", "stamp", "day_end",
]


func _initialize() -> void:
    var hints: Variant = JSON.parse_string(FileAccess.get_file_as_string(HINTS_PATH))
    if not hints is Array or hints.size() != HINT_IDS.size():
        _fail("Expected %d hints in %s." % [HINT_IDS.size(), HINTS_PATH])
        return

    var words := RegEx.create_from_string("\\S+")
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
        if not line is String or line.strip_edges().is_empty() or words.search_all(line).size() >= 10:
            _fail("Hint %s must contain one to nine words." % id)
            return
        remaining.erase(id)

    print("Day 1 hint checks passed: %d hints under 10 words each." % hints.size())
    quit()


func _fail(message: String) -> void:
    push_error(message)
    quit(1)

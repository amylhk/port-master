extends RefCounted

const BERTH_CAPACITY := 2
const ANCHORAGE_CAPACITY := 3
const INSPECTION_DIR := "res://data/inspections"
const EVENT_DIR := "res://data/events"
const BRIEFING_DIR := "res://data/briefings"
const BRIEFING_FLAG_SOURCES := {
    "rice_short_yesterday": "rice_target_missed",
    "ship_lost_yesterday": "ship_lost",
    "major_fraud_ruled_yesterday": "major_fraud_ruled",
}
const CITATION_METHODS := [
    {"id": "marks", "label": "Compare marks and seals"},
    {"id": "measurements", "label": "Compare counts and weights"},
    {"id": "testimony", "label": "Cross-check testimony and records"},
    {"id": "contents", "label": "Examine opened cargo"},
    {"id": "manifest", "label": "Check the declaration"},
]
const LEGACY_CITATIONS := {
    "marks_weight_route": "contents",
    "piece_count": "measurements",
    "wrong_dacing": "testimony",
    "pedir_messenger": "contents",
}

var scenario: Dictionary
var inspections: Dictionary
var manual: Dictionary
var minute_of_day := 0
var waiting: Array[Dictionary] = []
var berths: Array[Dictionary] = []
var log_lines: Array[String] = []
var pending_case: Dictionary = {}
var next_ship := 0
var completed := 0
var lost := 0
var held := 0
var duty := 0
var rice := 0
var recovered_duty := 0
var ruling_note := ""
var day_number := 1
var supply := 0
var reputation := 0
var flags := {}
var briefing_flags := {}
var events: Array[Dictionary] = []
var briefings: Array[Dictionary] = []
var story_queue: Array[Dictionary] = []
var story_index := 0
var story_outcome := {}

var _opening_supply := 0
var _opening_reputation := 0
var _day_trigger := RegEx.create_from_string("^day\\s*(>=|<=|==|!=|>|<)\\s*([0-9]+)$")


func load_data(scenario_path := "res://data/port_day.json", inspection_dir := INSPECTION_DIR) -> bool:
    inspections.clear()
    scenario = _read_data(scenario_path)
    manual = _read_data("res://data/manual/manual_stage_a.json")
    if scenario.is_empty() or manual.is_empty():
        return false

    var loaded := {}
    for ship in scenario["ships"]:
        if not ship.has("inspection_case"):
            continue
        var case_id: Variant = ship["inspection_case"]
        if not case_id is String or not case_id.is_valid_filename():
            push_error("Invalid inspection_case for ship %s: expected a case ID." % ship["id"])
            return false
        if loaded.has(case_id):
            continue
        var path := inspection_dir.path_join("%s.json" % case_id)
        var inspection := _read_data(path)
        if inspection.is_empty():
            return false
        if inspection.get("id") != case_id:
            push_error("Expected inspection ID '%s' at %s." % [case_id, path])
            return false
        for field in ["rulings", "reasons"]:
            var choices: Variant = inspection.get(field)
            if not choices is Array or choices.is_empty():
                push_error("Expected a nonempty '%s' array at %s." % [field, path])
                return false
        loaded[case_id] = inspection
    inspections = loaded
    events = _load_stories(EVENT_DIR)
    briefings = _load_stories(BRIEFING_DIR)
    return true


func _load_stories(directory: String) -> Array[Dictionary]:
    var stories: Array[Dictionary] = []
    for filename in DirAccess.get_files_at(directory):
        if filename.ends_with(".json"):
            var story := _read_data(directory.path_join(filename))
            if not story.is_empty():
                stories.append(story)
    return stories


func reset() -> void:
    minute_of_day = int(scenario["start_minute"])
    waiting.clear()
    berths.clear()
    log_lines.clear()
    pending_case = {}
    next_ship = 0
    completed = 0
    lost = 0
    held = 0
    duty = 0
    rice = 0
    recovered_duty = 0
    ruling_note = ""
    supply = _opening_supply
    reputation = _opening_reputation
    flags.clear()
    _queue_stories(briefings, briefing_flags, 0)
    _arrivals()


func berth(ship_id: String, inspect: bool) -> void:
    if closed() or not current_story().is_empty() or not pending_case.is_empty() or berths.size() >= BERTH_CAPACITY:
        return
    for i in waiting.size():
        var ship := waiting[i]
        if ship["id"] != ship_id:
            continue
        if not can_finish(ship, inspect):
            return
        var inspection := inspection_for(ship)
        waiting.remove_at(i)
        berths.append(ship)
        _log("%s took a berth." % ship["name"])
        if inspect:
            pending_case = ship
            _log("Detailed Inspection occupied a berth for %d min." % inspection["minutes"])
            _advance_clock(int(inspection["minutes"]))
        elif not inspection.is_empty():
            ruling_note = "%s cleared on the declaration alone." % ship["cargo"]
            _record_ruling(ship, "clear")
        return


func rule(ruling_id: String, reason_id: String) -> void:
    if pending_case.is_empty() or ruling_id.is_empty() or reason_id.is_empty():
        return
    var truth: Dictionary = inspection_for(pending_case)["hidden_truth"]
    _resolve_ruling(ruling_id, reason_id == truth["reason_id"], "")


func rule_with_method(ruling_id: String, method_id: String) -> void:
    if pending_case.is_empty() or ruling_id.is_empty() or method_id.is_empty():
        return
    var truth: Dictionary = inspection_for(pending_case)["hidden_truth"]
    var expected := _citation_method(truth)
    _resolve_ruling(ruling_id, method_id == expected, method_id)


func _citation_method(truth: Dictionary) -> String:
    var authored: Variant = truth.get("citation_method")
    for method in CITATION_METHODS:
        if method["id"] == authored:
            return authored
    return LEGACY_CITATIONS.get(truth["reason_id"], "contents")


func _resolve_ruling(ruling_id: String, evidence_matches: bool, method_id: String) -> void:
    var ship := pending_case
    pending_case = {}
    var inspection := inspection_for(ship)
    var truth: Dictionary = inspection["hidden_truth"]
    var ruling_matches: bool = ruling_id == truth["ruling_id"]
    var supported := ruling_matches and evidence_matches
    var outcome := ruling_id
    if ruling_id == "hold":
        berths.erase(ship)
        if supported:
            held += 1
            _log("Cargo held: %s." % ship["name"])
            ruling_note = truth["success"]
        else:
            _lose(ship, "Cargo held")
            ruling_note = truth["hold"]
            if truth["ruling_id"] == "hold":
                outcome = "hold_unsupported"
    elif ruling_id == "clear":
        ruling_note = truth["success"] if supported else truth["clear"]
    elif supported:
        ship["extra_duty"] = int(truth["extra_duty"])
        ruling_note = truth["success"]
        flags["any_ruling_amended"] = true
        if ruling_id == "major_fraud":
            flags["major_fraud_ruled"] = true
    else:
        ruling_note = truth["unsupported"]
        outcome = "clear"
    _record_ruling(ship, outcome)
    if not supported:
        ruling_note += "\n\n" + _ruling_feedback(inspection, ruling_matches, evidence_matches, method_id)
    _log(ruling_note)


func _record_ruling(ship: Dictionary, ruling_id: String) -> void:
    var case_id: String = ship["inspection_case"]
    flags["%s_%s" % [case_id, ruling_id]] = true
    if ruling_id == "clear":
        flags[case_id + "_cleared"] = true


func story_matches(story: Dictionary, required_flags: Dictionary) -> bool:
    if story.has("day"):
        var target: Variant = story["day"]
        if not (target is float or target is int) or target != day_number:
            return false
    elif not _trigger_matches(story.get("trigger", "")):
        return false
    var requirements: Variant = story.get("requires", [])
    if not requirements is Array:
        return false
    for flag in requirements:
        if not required_flags.has(flag):
            return false
    return true


func _trigger_matches(trigger: Variant) -> bool:
    if not trigger is String:
        return false
    var parts := _day_trigger.search(trigger)
    if parts == null:
        return false
    var target := int(parts.get_string(2))
    match parts.get_string(1):
        ">=": return day_number >= target
        "<=": return day_number <= target
        "==": return day_number == target
        "!=": return day_number != target
        ">": return day_number > target
        "<": return day_number < target
    return false


func _queue_stories(stories: Array[Dictionary], required_flags: Dictionary, first_index: int) -> void:
    story_queue.clear()
    story_index = first_index
    story_outcome = {}
    for story in stories:
        if story_matches(story, required_flags):
            story_queue.append(story)


func start_evening() -> void:
    if closed() and story_index == -1 and not story_queue.is_empty():
        story_index = 0


func current_story() -> Dictionary:
    if story_index >= 0 and story_index < story_queue.size():
        return story_queue[story_index]
    return {}


func choose_story(choice_id: String) -> void:
    if not story_outcome.is_empty():
        return
    for choice in current_story().get("choices", []):
        if choice["id"] == choice_id:
            var effects: Dictionary = choice["effects"]
            duty += int(effects.get("duty", 0))
            supply += int(effects.get("supply", 0))
            reputation += int(effects.get("reputation", 0))
            story_outcome = choice
            return


func continue_story() -> void:
    var story := current_story()
    if story.is_empty() or (not story.get("choices", []).is_empty() and story_outcome.is_empty()):
        return
    story_outcome = {}
    story_index += 1


func begin_next_day() -> void:
    if not closed() or (not story_queue.is_empty() and story_index < story_queue.size()):
        return
    day_number += 1
    briefing_flags.clear()
    for flag in BRIEFING_FLAG_SOURCES:
        if flags.has(BRIEFING_FLAG_SOURCES[flag]):
            briefing_flags[flag] = true
    _opening_supply = supply
    _opening_reputation = reputation
    reset()


func _ruling_feedback(case_data: Dictionary, ruling_matches: bool, evidence_matches: bool, method_id: String) -> String:
    var truth: Dictionary = case_data["hidden_truth"]
    var diagnosis := "The ruling and the cited evidence were both off."
    if ruling_matches:
        diagnosis = "The ruling was right, but the cited evidence did not support it."
    elif evidence_matches:
        diagnosis = "The evidence was relevant, but the ruling was wrong."
    var explanation := ""
    var feedback: Variant = truth.get("feedback_by_method")
    if not evidence_matches and feedback is Dictionary:
        var custom: Variant = feedback.get(method_id)
        if custom is String:
            explanation = custom.strip_edges()
    if explanation.is_empty():
        explanation = "Decisive finding: %s" % _choice_label(case_data["reasons"], truth["reason_id"])
    if not evidence_matches and not method_id.is_empty():
        diagnosis += "\nSupporting method: %s" % _choice_label(CITATION_METHODS, _citation_method(truth))
    return "%s\nCorrect ruling: %s\n%s" % [
        diagnosis, _choice_label(case_data["rulings"], truth["ruling_id"]), explanation,
    ]


func _choice_label(choices: Array, id: String) -> String:
    for choice in choices:
        if choice["id"] == id:
            return choice["label"]
    return id


func advance(minutes: int) -> void:
    if pending_case.is_empty() and current_story().is_empty():
        _advance_clock(minutes)


func can_finish(ship: Dictionary, inspect: bool) -> bool:
    var duration := int(ship["minutes"])
    if inspect:
        var inspection := inspection_for(ship)
        if inspection.is_empty():
            return false
        duration += int(inspection["minutes"])
    return minute_of_day + duration <= mini(int(ship["departure"]), int(scenario["end_minute"]))


func inspection_for(ship: Dictionary) -> Dictionary:
    return inspections.get(ship.get("inspection_case", ""), {})


func ship_at_anchor(slot: int) -> Dictionary:
    for ship in waiting:
        if ship["anchor_slot"] == slot:
            return ship
    return {}


func closed() -> bool:
    return minute_of_day >= int(scenario["end_minute"])


func all_ships_resolved() -> bool:
    return next_ship >= scenario["ships"].size() and waiting.is_empty() and berths.is_empty()


static func clock(minutes: int) -> String:
    @warning_ignore("integer_division")
    return "%02d:%02d" % [minutes / 60, minutes % 60]


func _advance_clock(minutes: int) -> void:
    for step in mini(minutes, int(scenario["end_minute"]) - minute_of_day):
        minute_of_day += 1
        for i in range(berths.size() - 1, -1, -1):
            var ship := berths[i]
            if ship != pending_case:
                ship["remaining"] -= 1
            if ship["remaining"] == 0:
                berths.remove_at(i)
                completed += 1
                var extra := int(ship.get("extra_duty", 0))
                recovered_duty += extra
                duty += int(ship["duty"]) + extra
                rice += int(ship["rice"])
                _log("Traded: %s (+%d duty)." % [ship["name"], int(ship["duty"]) + extra])
            elif minute_of_day >= int(ship["departure"]) or closed():
                berths.remove_at(i)
                _lose(ship, "Trade deadline" if not closed() else "Closing bell")
        for i in range(waiting.size() - 1, -1, -1):
            if minute_of_day >= int(waiting[i]["departure"]) or closed():
                _lose(waiting.pop_at(i), "No berth before departure" if not closed() else "Closing bell")
        if closed():
            _log("The harbour is closed.")
            flags["rice_target_met" if rice >= int(scenario["rice_target"]) else "rice_target_missed"] = true
            _queue_stories(events, flags, -1)
        else:
            _arrivals()


func _arrivals() -> void:
    var ships: Array = scenario["ships"]
    while next_ship < ships.size() and int(ships[next_ship]["arrival"]) <= minute_of_day:
        var ship: Dictionary = ships[next_ship].duplicate(true)
        next_ship += 1
        if waiting.size() >= ANCHORAGE_CAPACITY:
            _lose(ship, "Anchorage full")
        else:
            for slot in ANCHORAGE_CAPACITY:
                if ship_at_anchor(slot).is_empty():
                    ship["anchor_slot"] = slot
                    break
            ship["remaining"] = int(ship["minutes"])
            waiting.append(ship)
            _log("Arrived: %s." % ship["name"])


func _lose(ship: Dictionary, reason: String) -> void:
    lost += 1
    flags["ship_lost"] = true
    _log("%s: %s lost (%d duty%s foregone)." % [
        reason, ship["name"], int(ship["duty"]) + int(ship.get("extra_duty", 0)),
        " and %d rice sacks" % int(ship["rice"]) if int(ship["rice"]) > 0 else ""
    ])


func _log(message: String) -> void:
    log_lines.push_front("%s  %s" % [clock(minute_of_day), message])


func _read_data(path: String) -> Dictionary:
    if not FileAccess.file_exists(path):
        push_error("Missing Stage A data: " + path)
        return {}
    var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
    if not data is Dictionary:
        push_error("Expected a JSON object at " + path)
        return {}
    return data

extends RefCounted

const BERTH_CAPACITY := 2
const ANCHORAGE_CAPACITY := 3
const INSPECTION_DIR := "res://data/inspections"
const EVENT_DIR := "res://data/events"

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
var events: Array[Dictionary] = []
var evening_queue: Array[Dictionary] = []
var evening_index := -1
var evening_outcome := {}

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
    events.clear()
    for filename in DirAccess.get_files_at(EVENT_DIR):
        if filename.ends_with(".json"):
            var event := _read_data(EVENT_DIR.path_join(filename))
            if not event.is_empty():
                events.append(event)
    return true


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
    evening_queue.clear()
    evening_index = -1
    evening_outcome = {}
    _arrivals()


func berth(ship_id: String, inspect: bool) -> void:
    if closed() or not pending_case.is_empty() or berths.size() >= BERTH_CAPACITY:
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
    var ship := pending_case
    pending_case = {}
    var truth: Dictionary = inspection_for(ship)["hidden_truth"]
    var supported: bool = ruling_id == truth["ruling_id"] and reason_id == truth["reason_id"]
    if ruling_id == "hold":
        berths.erase(ship)
        if supported:
            held += 1
            _log("Cargo held: %s." % ship["name"])
            ruling_note = truth["success"]
        else:
            _lose(ship, "Cargo held")
            ruling_note = truth["hold"]
    elif ruling_id == "clear":
        ruling_note = truth["success"] if supported else truth["clear"]
    elif supported:
        ship["extra_duty"] = int(truth["extra_duty"])
        ruling_note = truth["success"]
    else:
        ruling_note = truth["unsupported"]
    _record_ruling(ship, ruling_id)
    _log(ruling_note)


func _record_ruling(ship: Dictionary, ruling_id: String) -> void:
    var case_id: String = ship["inspection_case"]
    flags["%s_%s" % [case_id, ruling_id]] = true
    match ruling_id:
        "clear":
            flags[case_id + "_cleared"] = true
        "hold":
            flags[case_id + "_held"] = true
        "minor_fault", "major_fraud":
            flags["any_ruling_amended"] = true


func event_matches(event: Dictionary) -> bool:
    if event.has("day"):
        var target: Variant = event["day"]
        if not (target is float or target is int) or target != day_number:
            return false
    elif not _trigger_matches(event.get("trigger", "")):
        return false
    var requirements: Variant = event.get("requires", [])
    if not requirements is Array:
        return false
    for flag in requirements:
        if not flags.has(flag):
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


func start_evening() -> void:
    if evening_index == -1 and not evening_queue.is_empty():
        evening_index = 0


func current_event() -> Dictionary:
    if evening_index >= 0 and evening_index < evening_queue.size():
        return evening_queue[evening_index]
    return {}


func choose_evening(choice_id: String) -> void:
    if not evening_outcome.is_empty():
        return
    for choice in current_event().get("choices", []):
        if choice["id"] == choice_id:
            var effects: Dictionary = choice["effects"]
            duty += int(effects.get("duty", 0))
            supply += int(effects.get("supply", 0))
            reputation += int(effects.get("reputation", 0))
            evening_outcome = choice
            return


func continue_evening() -> void:
    var event := current_event()
    if event.is_empty() or (not event.get("choices", []).is_empty() and evening_outcome.is_empty()):
        return
    evening_outcome = {}
    evening_index += 1


func begin_next_day() -> void:
    if not closed() or (not evening_queue.is_empty() and evening_index < evening_queue.size()):
        return
    day_number += 1
    _opening_supply = supply
    _opening_reputation = reputation
    reset()


func advance(minutes: int) -> void:
    if pending_case.is_empty():
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
            for event in events:
                if event_matches(event):
                    evening_queue.append(event)
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

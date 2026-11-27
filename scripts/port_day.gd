extends RefCounted

const BERTH_CAPACITY := 2
const ANCHORAGE_CAPACITY := 3
const INSPECTION_DIR := "res://data/inspections"

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
var duty := 0
var rice := 0
var recovered_duty := 0
var ruling_note := ""


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
        loaded[case_id] = inspection
    inspections = loaded
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
    duty = 0
    rice = 0
    recovered_duty = 0
    ruling_note = ""
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
        return


func rule(ruling_id: String, reason_id: String) -> void:
    if pending_case.is_empty() or ruling_id.is_empty() or reason_id.is_empty():
        return
    var ship := pending_case
    pending_case = {}
    var truth: Dictionary = inspection_for(ship)["hidden_truth"]
    if ruling_id == truth["ruling_id"] and reason_id == truth["reason_id"]:
        ship["extra_duty"] = int(truth["extra_duty"])
        ruling_note = truth["success"]
    elif ruling_id == "hold":
        berths.erase(ship)
        _lose(ship, "Cargo held")
        ruling_note = truth["hold"]
    elif ruling_id == "clear":
        ruling_note = truth["clear"]
    else:
        ruling_note = truth["unsupported"]
    _log(ruling_note)


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

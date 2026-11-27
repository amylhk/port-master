extends RefCounted

const BERTH_CAPACITY := 2
const ANCHORAGE_CAPACITY := 3
const RICE_SACKS_PER_RELIEF_DUTY := 2.0
const INSPECTION_DIR := "res://data/inspections"
const EVENT_DIR := "res://data/events"
const BRIEFING_DIR := "res://data/briefings"
const DEPARTURE_DIR := "res://data/departures"
const OFFER_DIR := "res://data/offers"
const MERCHANT_DIR := "res://data/merchants"
const DEPUTY_DIR := "res://data/deputies"
const FACTION_DIR := "res://data/factions"
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
    "marks_weight_route": ["marks", "measurements", "testimony", "contents"],
    "piece_count": ["measurements", "contents"],
    "wrong_dacing": ["measurements", "testimony"],
    "pedir_messenger": ["testimony", "contents"],
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
var rice_relief_cost := 0
var recovered_duty := 0
var ruling_note := ""
var day_number := 1
var supply := 0
var reputation := 0
var merchant_trust := {}
var faction_standing := {}
var flags := {}
var campaign_flags := {}
var briefing_flags := {}
var events: Array[Dictionary] = []
var briefings: Array[Dictionary] = []
var departures: Array[Dictionary] = []
var offers: Array[Dictionary] = []
var merchants := {}
var deputies := {}
var story_queue: Array[Dictionary] = []
var story_index := 0
var story_outcome := {}
var active_offer := {}
var _finished_offers := {}
var _offer_ship_departures := {}

var _schedule: Array[Dictionary] = []
var _opening_anchorage: Array[Dictionary] = []
var _opening_supply := 0
var _opening_reputation := 0
var _opening_trust := {}
var _opening_campaign_flags := {}
var _day_trigger := RegEx.create_from_string("^day\\s*(>=|<=|==|!=|>|<)\\s*([0-9]+)$")
var _condition := RegEx.create_from_string("^(duty|supply|reputation|merchant_trust|faction_standing)(?:\\.([a-z0-9_]+))?(>=|<=|==|>|<)([+-]?[0-9]+)\\z")


func load_data(scenario_path := "res://data/port_day.json", inspection_dir := INSPECTION_DIR) -> bool:
    inspections.clear()
    scenario = _read_data(scenario_path)
    manual = _read_data("res://data/manual/manual_stage_a.json")
    if scenario.is_empty() or manual.is_empty():
        return false

    _schedule = [scenario]
    var ships: Array = scenario["ships"].duplicate()
    for entry: Dictionary in scenario.get("following_days", []):
        var scheduled := {
            "start_minute": scenario["start_minute"],
            "end_minute": scenario["end_minute"],
            "art": scenario.get("art", {}),
            "briefing": "Review today's arrivals, cargoes and tide deadlines before assigning berths.",
        }
        scheduled.merge(entry, true)
        _schedule.append(scheduled)
        ships.append_array(scheduled["ships"])
    var loaded := {}
    for ship in ships:
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
    departures = _load_stories(DEPARTURE_DIR)
    offers = _load_stories(OFFER_DIR)
    merchants = _load_index(MERCHANT_DIR)
    deputies = _load_index(DEPUTY_DIR)
    faction_standing.clear()
    for faction in _load_stories(FACTION_DIR):
        faction_standing[faction["id"]] = 0
    return true


func _load_stories(directory: String) -> Array[Dictionary]:
    var stories: Array[Dictionary] = []
    for filename in DirAccess.get_files_at(directory):
        if filename.ends_with(".json"):
            var story := _read_data(directory.path_join(filename))
            if not story.is_empty():
                stories.append(story)
    return stories


func _load_index(directory: String) -> Dictionary:
    var index := {}
    for item in _load_stories(directory):
        index[item["id"]] = item
    return index


func reset() -> void:
    scenario = _schedule[day_number - 1]
    minute_of_day = int(scenario["start_minute"])
    waiting = _opening_anchorage.duplicate(true)
    berths.clear()
    log_lines.clear()
    pending_case = {}
    next_ship = 0
    completed = 0
    lost = 0
    held = 0
    duty = 0
    rice = 0
    rice_relief_cost = 0
    recovered_duty = 0
    ruling_note = ""
    supply = _opening_supply
    reputation = _opening_reputation
    merchant_trust = _opening_trust.duplicate()
    campaign_flags = _opening_campaign_flags.duplicate()
    active_offer.clear()
    _finished_offers.clear()
    _offer_ship_departures.clear()
    for ship in scenario["ships"]:
        _offer_ship_departures[ship["id"]] = int(ship["departure"])
    for ship in waiting:
        _offer_ship_departures[ship["id"]] = int(ship["departure"])
    flags.clear()
    _queue_stories(briefings, briefing_flags, 0)
    for ship in waiting:
        _log("Still at anchor: %s." % ship["name"])
    _arrivals()


func berth(ship_id: String, inspect: bool) -> void:
    _berth_ship(ship_id, inspect)


func _berth_ship(ship_id: String, inspect: bool, extra_time := 0) -> void:
    if closed() or not current_story().is_empty() or not pending_case.is_empty() or berths.size() >= BERTH_CAPACITY:
        return
    for i in waiting.size():
        var ship := waiting[i]
        if ship["id"] != ship_id:
            continue
        if not can_finish(ship, inspect, extra_time):
            return
        var inspection := inspection_for(ship)
        waiting.remove_at(i)
        for slot in BERTH_CAPACITY:
            if ship_at_berth(slot).is_empty():
                ship["berth_slot"] = slot
                break
        berths.append(ship)
        _log("%s took a berth." % ship["name"])
        if inspect:
            pending_case = ship
            var duration := int(inspection["minutes"]) + extra_time
            _log("Detailed Inspection occupied a berth for %d min." % duration)
            _advance_clock(duration)
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
    _resolve_ruling(ruling_id, method_id in _citation_methods(truth), method_id)


func _citation_methods(truth: Dictionary) -> Array:
    var authored: Variant = truth.get("citation_method")
    for method in CITATION_METHODS:
        if method["id"] == authored:
            return [authored]
    return LEGACY_CITATIONS.get(truth["reason_id"], ["contents"])


func _resolve_ruling(ruling_id: String, evidence_matches: bool, method_id: String) -> void:
    var ship := pending_case
    pending_case = {}
    var inspection := inspection_for(ship)
    var truth: Dictionary = inspection["hidden_truth"]
    var ruling_matches: bool = ruling_id == truth["ruling_id"]
    var supported := ruling_matches and evidence_matches
    var outcome := ruling_id
    if ruling_id == "hold":
        if supported and truth.get("hold_at_berth", false):
            ship["held_at_berth"] = true
        else:
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
    flags[ship["inspection_case"] + "_inspected"] = true
    _record_ruling(ship, outcome)
    if not supported:
        ruling_note += "\n\n" + _ruling_feedback(inspection, ruling_matches, evidence_matches, method_id)
    _log(ruling_note)


func _record_ruling(ship: Dictionary, ruling_id: String) -> void:
    var case_id: String = ship["inspection_case"]
    flags["%s_%s" % [case_id, ruling_id]] = true
    if ruling_id == "clear":
        flags[case_id + "_cleared"] = true


func story_matches(story: Dictionary, required_flags: Dictionary, check_conditions := true) -> bool:
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
    return not check_conditions or _conditions_match(story)


func _conditions_match(story: Dictionary) -> bool:
    var conditions: Variant = story.get("conditions", [])
    if not conditions is Array:
        return false
    for value in conditions:
        if not value is String:
            return false
        var parts := _condition.search(value)
        if parts == null:
            return false
        var stat := parts.get_string(1)
        var id := parts.get_string(2)
        var actual := 0
        match stat:
            "merchant_trust":
                if not merchants.has(id):
                    return false
                actual = int(merchant_trust.get(id, 0))
            "faction_standing":
                if not faction_standing.has(id):
                    return false
                actual = int(faction_standing[id])
            _:
                if not id.is_empty():
                    return false
                actual = int(get(stat))
        if not _compare(actual, parts.get_string(3), int(parts.get_string(4))):
            return false
    return true


func _trigger_matches(trigger: Variant) -> bool:
    if not trigger is String:
        return false
    var parts := _day_trigger.search(trigger)
    if parts == null:
        return false
    return _compare(day_number, parts.get_string(1), int(parts.get_string(2)))


func _compare(actual: int, operator: String, target: int) -> bool:
    match operator:
        ">=": return actual >= target
        "<=": return actual <= target
        "==": return actual == target
        "!=": return actual != target
        ">": return actual > target
        "<": return actual < target
    return false


func _queue_stories(stories: Array[Dictionary], required_flags: Dictionary, first_index: int) -> void:
    story_queue.clear()
    story_index = first_index
    story_outcome = {}
    for story in stories:
        if story_matches(story, required_flags, false):
            story_queue.append(story)
    _skip_unmatched_stories()


func _skip_unmatched_stories() -> void:
    while story_index >= 0 and story_index < story_queue.size():
        if _conditions_match(story_queue[story_index]):
            return
        story_index += 1


func start_evening() -> void:
    if closed() and story_index == -1 and not story_queue.is_empty():
        story_index = 0
        _skip_unmatched_stories()


func current_story() -> Dictionary:
    if not active_offer.is_empty():
        return active_offer
    if story_index >= 0 and story_index < story_queue.size():
        return story_queue[story_index]
    return {}


func choose_story(choice_id: String) -> void:
    if not story_outcome.is_empty():
        return
    var story := current_story()
    for choice in story.get("choices", []):
        if choice["id"] == choice_id:
            var effects: Dictionary = choice["effects"]
            duty += int(effects.get("duty", 0))
            supply += int(effects.get("supply", 0))
            reputation += int(effects.get("reputation", 0))
            if effects.has("merchant_trust"):
                var merchant_id: String = story["merchant_id"]
                merchant_trust[merchant_id] = int(merchant_trust.get(merchant_id, 0)) + int(effects["merchant_trust"])
            story_outcome = choice
            return


func continue_story() -> void:
    var story := current_story()
    if story.is_empty() or (not story.get("choices", []).is_empty() and story_outcome.is_empty()):
        return
    story_outcome = {}
    if not active_offer.is_empty():
        _finished_offers[story["id"]] = true
        active_offer = {}
        return
    if story.has("chain_id"):
        var step_flag := "%s_step_%d" % [story["chain_id"], int(story["step"])]
        flags[step_flag] = true
        campaign_flags[step_flag] = true
    story_index += 1
    _skip_unmatched_stories()


func available_offers() -> Array[Dictionary]:
    var available: Array[Dictionary] = []
    if closed() or not current_story().is_empty() or not pending_case.is_empty():
        return available
    var required_flags := briefing_flags.duplicate()
    required_flags.merge(campaign_flags)
    required_flags.merge(flags)
    for offer in offers:
        if offer.has("ship_id") and minute_of_day >= int(_offer_ship_departures.get(offer["ship_id"], 0)):
            continue
        if not _finished_offers.has(offer["id"]) and story_matches(offer, required_flags):
            available.append(offer)
    return available


func open_offer(offer_id: String) -> void:
    for offer in available_offers():
        if offer["id"] == offer_id:
            active_offer = offer
            return


func delegate_berth(deputy_id: String) -> void:
    if (not deputies.has(deputy_id) or closed() or not current_story().is_empty()
            or not pending_case.is_empty() or berths.size() >= BERTH_CAPACITY):
        return
    var candidates := waiting.filter(func(ship: Dictionary) -> bool: return can_finish(ship, false))
    if candidates.is_empty():
        return
    var deputy: Dictionary = deputies[deputy_id]
    var skill := int(deputy["skills"]["berth"])
    var result := _delegation_result(skill)
    var ship: Dictionary = candidates[0]
    if result == "good":
        for candidate in candidates:
            if candidate["departure"] < ship["departure"]:
                ship = candidate
    match deputy["flaw"]["id"]:
        "old_favours":
            for candidate in candidates:
                if _ship_trust(candidate["id"]) > _ship_trust(ship["id"]):
                    ship = candidate
                    result = "mixed"
        "rice_before_all":
            for candidate in candidates:
                if int(candidate["rice"]) > int(ship["rice"]):
                    ship = candidate
                    result = "mixed"
    _deputy_line(deputy, "berth", "assign")
    if result == "bad":
        _advance_clock(15)
    else:
        berth(ship["id"], false)
    _deputy_line(deputy, "berth", result)


func delegate_inspection(deputy_id: String, ship_id: String) -> void:
    if not deputies.has(deputy_id) or not pending_case.is_empty():
        return
    var deputy: Dictionary = deputies[deputy_id]
    _berth_ship(ship_id, true, inspection_delay(deputy_id))
    if pending_case.get("id") != ship_id:
        return
    _deputy_line(deputy, "inspection", "assign")
    var skill := int(deputy["skills"]["inspection"])
    var flaw: String = deputy["flaw"]["id"]
    if ((flaw == "kin_and_countrymen" and ship_id in ["pasai_swift", "bengal_dawn"])
            or (flaw == "accepts_presents" and _ship_trust(ship_id) > 0)):
        skill -= 2
    var result := _delegation_result(skill)
    var truth: Dictionary = inspection_for(pending_case)["hidden_truth"]
    if result == "good":
        rule(truth["ruling_id"], truth["reason_id"])
    else:
        var ship := pending_case
        pending_case = {}
        flags[ship["inspection_case"] + "_inspected"] = true
        _record_ruling(ship, "clear")
        if result == "bad":
            reputation -= 1
    _deputy_line(deputy, "inspection", result)


func inspection_delay(deputy_id: String) -> int:
    return 15 if deputies[deputy_id]["flaw"]["id"] == "weighs_everything" else 0


func delegate_purchase(deputy_id: String) -> void:
    if not deputies.has(deputy_id) or active_offer.is_empty() or not story_outcome.is_empty():
        return
    var choices: Array = active_offer.get("choices", [])
    if choices.is_empty():
        return
    var deputy: Dictionary = deputies[deputy_id]
    var skill := int(deputy["skills"]["purchasing"])
    var flaw: String = deputy["flaw"]["id"]
    var merchant_id: String = active_offer["merchant_id"]
    if ((flaw == "kin_and_countrymen" and merchant_id in ["idris_pasai", "jalal_sonargaon"])
            or (flaw == "accepts_presents" and int(merchant_trust.get(merchant_id, 0)) > 0)):
        skill -= 2
    var result := _delegation_result(skill)
    var choice: Dictionary = choices[0]
    for candidate in choices:
        if _purchase_value(candidate["effects"], result, flaw) > _purchase_value(choice["effects"], result, flaw):
            choice = candidate
    _deputy_line(deputy, "purchasing", "assign")
    choose_story(choice["id"])
    _deputy_line(deputy, "purchasing", result)


func _purchase_value(effects: Dictionary, result: String, flaw: String) -> int:
    if flaw == "rice_before_all":
        return int(effects.get("supply", 0))
    match result:
        "good":
            return 2 * int(effects.get("supply", 0)) + int(effects.get("duty", 0)) + int(effects.get("reputation", 0))
        "mixed":
            return int(effects.get("duty", 0))
        _:
            return -int(effects.get("duty", 0))


func _ship_trust(ship_id: String) -> int:
    var trust := 0
    for merchant_id in merchant_trust:
        if ship_id in merchants.get(merchant_id, {}).get("ship_ids", []):
            trust = maxi(trust, int(merchant_trust[merchant_id]))
    return trust


func _delegation_result(skill: int) -> String:
    if skill >= 4:
        return "good"
    return "mixed" if skill >= 2 else "bad"


func _deputy_line(deputy: Dictionary, task: String, result: String) -> void:
    var lines: Array = deputy["delegation_lines"][task][result]
    _log("%s: %s" % [deputy["name"], lines[0]])


func begin_next_day() -> void:
    if not has_next_day() or not closed() or (not story_queue.is_empty() and story_index < story_queue.size()):
        return
    day_number += 1
    briefing_flags.clear()
    for flag in BRIEFING_FLAG_SOURCES:
        if flags.has(BRIEFING_FLAG_SOURCES[flag]):
            briefing_flags[flag] = true
    if flags.has("ships_held_over"):
        briefing_flags["ships_held_over"] = true
    _opening_anchorage = waiting.duplicate(true)
    _opening_supply = supply
    _opening_reputation = reputation
    _opening_trust = merchant_trust.duplicate()
    for flag in flags:
        if flag.begins_with("case_"):
            campaign_flags[flag] = true
    _opening_campaign_flags = campaign_flags.duplicate()
    reset()


func has_next_day() -> bool:
    return day_number < _schedule.size()


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
        var methods := PackedStringArray()
        for method in _citation_methods(truth):
            methods.append(_choice_label(CITATION_METHODS, method))
        var caption := "Supporting method" if methods.size() == 1 else "Supporting methods"
        diagnosis += "\n%s: %s" % [caption, ", ".join(methods)]
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


func can_finish(ship: Dictionary, inspect: bool, extra_time := 0) -> bool:
    var duration := int(ship["minutes"]) + extra_time
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


func ship_at_berth(slot: int) -> Dictionary:
    for ship in berths:
        if ship["berth_slot"] == slot:
            return ship
    return {}


func closed() -> bool:
    return minute_of_day >= int(scenario["end_minute"])


func rice_shortfall() -> int:
    return maxi(0, int(scenario["rice_target"]) - rice)


func all_ships_resolved() -> bool:
    return next_ship >= scenario["ships"].size() and waiting.is_empty() and berths.all(
        func(ship: Dictionary) -> bool: return ship.get("held_at_berth", false))


static func clock(minutes: int) -> String:
    @warning_ignore("integer_division")
    return "%02d:%02d" % [minutes / 60, minutes % 60]


func _advance_clock(minutes: int) -> void:
    for step in mini(minutes, int(scenario["end_minute"]) - minute_of_day):
        minute_of_day += 1
        for i in range(berths.size() - 1, -1, -1):
            var ship := berths[i]
            if ship.get("held_at_berth", false):
                if closed():
                    berths.remove_at(i)
                continue
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
        if not closed():
            for i in range(waiting.size() - 1, -1, -1):
                if minute_of_day >= int(waiting[i]["departure"]):
                    _lose(waiting.pop_at(i), "No berth before departure")
        if closed():
            if not waiting.is_empty():
                flags["ships_held_over"] = true
                _log("%d ship(s) remain at anchor." % waiting.size())
            _log("The harbour is closed.")
            var shortfall := rice_shortfall()
            rice_relief_cost = ceili(shortfall / RICE_SACKS_PER_RELIEF_DUTY)
            duty -= rice_relief_cost
            flags["rice_target_met" if shortfall == 0 else "rice_target_missed"] = true
            _queue_stories(events, flags, -1)
            var departure_flags := campaign_flags.duplicate()
            departure_flags.merge(briefing_flags)
            departure_flags.merge(flags)
            for departure in departures:
                var step_flag := "%s_step_%d" % [departure["chain_id"], int(departure["step"])]
                if not campaign_flags.has(step_flag) and story_matches(departure, departure_flags, false):
                    story_queue.append(departure)
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
    _offer_ship_departures.erase(ship["id"])
    flags["ship_lost"] = true
    _log("%s: %s lost (%d duty%s foregone)." % [
        reason, ship["name"], int(ship["duty"]) + int(ship.get("extra_duty", 0)),
        " and %d rice sacks" % int(ship["rice"]) if int(ship["rice"]) > 0 else ""
    ])


func _log(message: String) -> void:
    log_lines.push_front("%s  %s" % [clock(minute_of_day), message])


func _read_data(path: String) -> Dictionary:
    if not FileAccess.file_exists(path):
        push_error("Missing port data: " + path)
        return {}
    var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
    if not data is Dictionary:
        push_error("Expected a JSON object at " + path)
        return {}
    return data

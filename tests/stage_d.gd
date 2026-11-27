extends SceneTree

const PortDay = preload("res://scripts/port_day.gd")
const Harbour = preload("res://scenes/harbour.tscn")
const MAIN_STEPS := {
    6: "sequeira_five_sails", 7: "sequeira_empty_moorings",
    8: "araujo_letters_out", 9: "tun_mutahir_closed_credit",
    11: "albuquerque_roadstead", 12: "waterfront_fires", 13: "first_assault_bridge",
    15: "second_assault_bridge", 16: "last_quay_roll",
}

var failures := 0


func _initialize() -> void:
    call_deferred("_run")


func _run() -> void:
    var harbour = Harbour.instantiate()
    root.add_child(harbour)
    var day: PortDay = harbour.day
    _expect(day.history.size() == 22 and day.factions.size() == 12 and day.characters.size() == 38,
        "main scene loads the Writer's history, factions and character roster")
    _expect(day.person("ong_kuan").get("id") == "ong_kuan" and day.person("nina_chatu").get("id") == "nina_chatu",
        "person lookup resolves merchant and character IDs")
    _press(harbour, "People & factions")
    _expect(_has_texture(harbour, "sultan_ahmad_shah", "portraits"), "the cast directory shows a character portrait")
    _press(harbour, "Return to campaign")
    _campaign(harbour, "aftermath_inland_exile")
    for fate in ["aftermath_upeh_reckoning", "aftermath_fortress_quay", "aftermath_strait_passage"]:
        harbour.day = PortDay.new()
        if harbour.day.load_data():
            harbour.day.reset()
            _campaign(harbour, fate)
        else:
            _expect(false, "reload data for " + fate)
    for clearance in ["declaration", "manifest"]:
        harbour.day = PortDay.new()
        if harbour.day.load_data():
            harbour.day.reset()
            _campaign(harbour, "aftermath_strait_passage", clearance)
        else:
            _expect(false, "reload data for " + clearance)
    _art_fallback(harbour)
    if failures == 0:
        print("Stage D checks passed: linked history, ruling branches, four reachable fates, priority, replay, art and cast.")
    quit(1 if failures else 0)


func _campaign(harbour: Control, fate: String, unverified_clearance := "") -> void:
    var day: PortDay = harbour.day
    var clearing := fate == "aftermath_fortress_quay"
    var inland := fate == "aftermath_inland_exile"
    var upeh := fate == "aftermath_upeh_reckoning" or inland
    var rulings := inland or clearing
    var choices := {
        "sequeira_five_sails": "keep_the_turn" if rulings else "reserve_landings",
        "first_assault_bridge": "split_merchant_rice" if upeh else "reserve_for_store",
        "second_assault_bridge": "keep_desk_open" if clearing or not unverified_clearance.is_empty() else "send_duplicates",
        "last_quay_roll": "leave_with_roll" if inland else "stay_at_landing",
        "kaveri_open_account": "record_the_count",
        "white_border_on_the_mat": "routine_assessment",
        "finale_cambay_flight": "leave_watchman_receipt",
    }
    if not unverified_clearance.is_empty():
        choices["ev_boatman_tip"] = "send_away"
    for number in range(1, 19):
        _expect(day.day_number == number, "reached day %d of %s" % [number, fate])
        _finish(day, choices)
        if number == 1 and rulings:
            day.berth("rice", false)
            day.berth("porcelain", true)
            day.rule("major_fraud", "marks_weight_route")
            day.advance(15)
            day.berth("resin", true)
            day.rule("hold", "pedir_messenger")
            day.advance(120)
            day.berth("cloth", true)
            day.rule("clear" if clearing else "hold", "piece_count")
        if number == 1 and not unverified_clearance.is_empty():
            day.advance(120)
            day.berth("cloth", unverified_clearance != "declaration")
            if unverified_clearance != "declaration":
                day.rule_with_method("clear", unverified_clearance)
            _expect(day.flags.has("case_002_cleared"), "Kaveri actually cleared by " + unverified_clearance)
        if number == 15 and clearing:
            day.advance(70)
            day.berth("north_bank_jong", false)
        if number <= 15:
            day.advance(600)
        else:
            _expect(day.closed() and day.scenario["ships"].is_empty(), "the finale adds no fictional harbour calls")
        day.start_evening()
        if number == 16:
            harbour._render()
            _expect(_has_texture(harbour, "last_quay_roll"), "day 16 shows the fall illustration")
        if number == 17:
            harbour._render()
            _expect(_has_texture(harbour, "last_quay_roll"), "day 17 reuses the fall illustration")
            if rulings:
                for flag in ["case_001_major_fraud", "case_004_hold", "case_002_cleared" if clearing else "case_002_hold"]:
                    _expect(day.campaign_flags.has(flag), flag + " survives from the inspection to the finale")
        if number == 18:
            harbour._render()
            _expect(_has_texture(harbour, fate), "day 18 renders its own illustrated fate: " + fate)
            if inland:
                _expect(day.story_matches(day.history["aftermath_upeh_reckoning"], day.campaign_flags),
                    "inland exile outranks an also eligible Upeh reckoning")
        var played := _finish(day, choices)
        if MAIN_STEPS.has(number):
            _expect(MAIN_STEPS[number] in played, "played the shared history step on day %d" % number)
        if number == 10 or number == 14:
            var optional := "ismail_waxed_letter" if number == 10 else "ismail_shuttered_store"
            _expect(played.has(optional) == rulings, "the optional Ismail chain requires the supported hold")
        if number == 17:
            _expect("finale_cambay_flight" in played, "the Cambay flight plays")
            for id in ["finale_junk_convoy", "finale_ismail_barque"]:
                _expect(played.has(id) == rulings, id + " requires its matching record")
            if not unverified_clearance.is_empty():
                _expect(day.faction_standing["chatu_contacts"] == 2, "Chatu standing is high for " + unverified_clearance)
                _expect(not played.has("finale_chatu_banner") and day.duty == 0,
                    "Kaveri %s clearance must not earn Chatu's vouching or its +2 duty" % unverified_clearance)
            else:
                _expect(played.has("finale_chatu_banner") == clearing and played.has("finale_kaveri_departure") == inland,
                    "clearing or holding Kaveri changes the day 17 steps")
        if number == 18:
            _expect(played == [fate] and not day.has_next_day(), "expected only %s, got %s (%s)" % [fate, played, unverified_clearance])
            day.reset()
            day.start_evening()
            _expect(_finish(day, choices) == [fate], "replaying the final day restores the same branch")
        else:
            day.begin_next_day()


func _finish(day: PortDay, choices: Dictionary) -> Array[String]:
    var played: Array[String] = []
    while not day.current_story().is_empty():
        var story := day.current_story()
        played.append(story["id"])
        var options: Array = story.get("choices", [])
        if not options.is_empty():
            day.choose_story(choices.get(story["id"], options[0]["id"]))
        day.continue_story()
    return played


func _art_fallback(harbour: Control) -> void:
    var day: PortDay = harbour.day
    var story: Dictionary = day.history["aftermath_strait_passage"].duplicate()
    story["id"] = "unillustrated_fate"
    day.history[story["id"]] = story
    day.story_queue.assign([story])
    day.story_index = 0
    harbour._render()
    for label: Label in harbour.content.find_children("*", "Label", true, false):
        if label.text == story["body"]:
            return
    _expect(false, "the aftermath body is still shown without an illustration")


func _press(harbour: Control, caption: String) -> void:
    for button: Button in harbour.find_children("*", "Button", true, false):
        if button.text == caption:
            button.pressed.emit()
            return
    _expect(false, "missing button: " + caption)


func _has_texture(harbour: Control, id: String, folder := "finale") -> bool:
    for picture: TextureRect in harbour.find_children("*", "TextureRect", true, false):
        if picture.texture and picture.texture.resource_path == "res://assets/art/%s/%s.png" % [folder, id]:
            return true
    return false


func _expect(condition: bool, description: String) -> void:
    if not condition:
        failures += 1
        printerr("FAIL: " + description)

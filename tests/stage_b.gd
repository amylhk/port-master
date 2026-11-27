extends SceneTree

const PortDay = preload("res://scripts/port_day.gd")
const Harbour = preload("res://scenes/harbour.tscn")
const CASE_SHIPS := [
    "gresik_morning_star", "zhangzhou_evening_tide", "cambay_nur", "pasai_swift",
    "pegu_river_hen", "champa_river_lotus", "cambay_aman", "bengal_dawn", "cambay_safa",
    "ryukyu_white_tern", "tuban_moon", "rice", "three_reeds", "north_bank_jong",
]

var failures := 0


func _initialize() -> void:
    call_deferred("_run")


func _run() -> void:
    var day := PortDay.new()
    if not day.load_data():
        quit(1)
        return
    _schedule(day)
    _offers_and_deputies()
    _departures()
    await _evidence_plates()
    if failures == 0:
        print("Stage B checks passed: 15 linked days, 18 inspections, anchored carry-over, deputies, offers, conditions, and departure chains.")
    quit(1 if failures else 0)


func _schedule(day: PortDay) -> void:
    day.reset()
    _expect(day.inspections.size() == 18, "all authored cases are registered")
    var played_ships := {}
    var day_one_rice: Dictionary = day.scenario["ships"][0]
    _expect(day_one_rice["id"] == "rice" and day_one_rice["departure"] == 615, "day 1 retains its rice tide")
    for number in range(1, 16):
        _expect(day.day_number == number, "campaign advances to day %d" % number)
        _finish_stories(day)
        if number == 4:
            day.berth("tioman_coaster", false)
        for ship in day.scenario["ships"]:
            played_ships[ship["id"]] = true
            if number == 1 or ship["id"] != CASE_SHIPS[number - 2]:
                continue
            var case_id := "case_%03d" % (number + 3)
            _expect(ship.get("inspection_case") == case_id, "%s is attached to %s" % [case_id, ship["id"]])
            day.advance(int(ship["arrival"]) - day.minute_of_day)
            day.berth(ship["id"], true)
            _expect(day.pending_case.get("inspection_case") == case_id, "%s can be opened on schedule" % case_id)
            if not day.pending_case.is_empty():
                var truth: Dictionary = day.inspection_for(ship)["hidden_truth"]
                day.rule(truth["ruling_id"], truth["reason_id"])
                _expect(day.flags.has("%s_%s" % [case_id, truth["ruling_id"]]), "the supported ruling is recorded")
            if number == 12:
                _expect(ship["rice"] == 16, "Tuban Moon only lands sixteen sound sacks")
            if number == 13:
                _expect(ship["arrival"] == 540 and ship["departure"] == 660 and day_one_rice["departure"] == 615,
                    "the longer rice window is isolated to day 13")
        day.advance(600)
        _expect(day.closed(), "the day closes at 17:00")
        if number == 3:
            _expect(day.waiting.size() == 1 and day.waiting[0]["id"] == "tioman_coaster"
                and day.flags.has("ships_held_over"), "Pulau Star remains at anchor at the bell")
        _finish_evening(day)
        day.begin_next_day()
        if number == 3:
            _expect(day.briefing_flags.has("ships_held_over") and day.ship_at_anchor(0).get("id") == "tioman_coaster",
                "the overnight ship takes its own slot before the Cambay arrivals")
            _expect(day.story_queue.any(func(story: Dictionary) -> bool: return story["id"] == "anchorage_held_over"),
                "the overnight anchorage briefing is queued")
            _expect(day.waiting.size() == 3 and day.lost == 1, "an occupied anchorage prevents the fourth immediate arrival")
        if number == 4:
            _expect(not day.briefing_flags.has("ships_held_over"), "the carry-over flag clears when no ships remain at anchor")
    _expect(day.day_number == 15 and not day.has_next_day(), "day 15 is the last playable day")
    for merchant in day.merchants.values():
        for ship_id in merchant["ship_ids"]:
            _expect(played_ships.has(ship_id), "%s has a port call" % ship_id)


func _offers_and_deputies() -> void:
    var day := PortDay.new()
    if not day.load_data():
        _expect(false, "load purchasing and delegation data")
        return
    day.reset()
    _finish_stories(day)
    day.open_offer("jaka_wira_morning_rice")
    _expect(day.current_story().get("id") == "jaka_wira_morning_rice", "open a currently eligible offer")
    day.delegate_purchase("siti_aminah")
    _expect(day.supply == 8 and day.duty == -6 and day.merchant_trust.get("jaka_wira") == 1,
        "rice-first purchasing chooses the largest share and applies trust and port effects")
    day.choose_story("buy_all")
    day.continue_story()
    day.open_offer("jaka_wira_morning_rice")
    _expect(day.current_story().is_empty() and day.supply == 8, "a completed offer cannot be played again that day")
    day.delegate_berth("pak_mamat")
    _expect(day.ship_at_berth(0).get("id") == "rice", "the pilot berths the highest-trust eligible ship")
    day.delegate_inspection("kesavan", "porcelain")
    _expect(day.minute_of_day == 600 and day.pending_case.is_empty() and day.flags.has("case_001_major_fraud"),
        "a skilled but thorough deputy takes extra time and files the supported ruling")
    day.advance(600)
    _finish_evening(day)
    day.begin_next_day()
    _expect(day.merchant_trust.get("jaka_wira") == 1, "merchant trust carries across days")
    _expect(day.story_matches({"day": 2, "conditions": [
        "merchant_trust.jaka_wira>=1", "faction_standing.chatu_contacts==0", "supply>0", "duty<=0",
    ]}, {}), "conditions support named trust, standing and bare port stats")
    for condition in ["duty<-1", "reputation!=99", "duty.jaka_wira==0", "merchant_trust.unknown==0", "supply>= 0"]:
        _expect(not day.story_matches({"day": 2, "conditions": ["duty==0", condition]}, {}),
            "all conditions must hold; malformed or failing condition is skipped: " + condition)


func _departures() -> void:
    var day := PortDay.new()
    if not day.load_data():
        _expect(false, "load the departure chains")
        return
    for departure in day.departures:
        if departure["id"] == "salamat_waits_offshore":
            departure["conditions"] = ["merchant_trust.khoja_ismail>=2"]
    day.departures.push_front({
        "id": "blocked_account", "day": 2, "chain_id": "blocked_account", "step": 1,
        "conditions": ["merchant_trust.khoja_ismail<-1"],
    })
    day.reset()
    _finish_stories(day)
    day.berth("rice", false)
    day.advance(30)
    day.berth("resin", true)
    day.rule("hold", "pedir_messenger")
    day.advance(600)
    _finish_evening(day)
    day.begin_next_day()
    _expect(day.campaign_flags.has("case_004_hold") and not day.flags.has("case_004_hold"),
        "the canonical case flag persists for chains without leaking into daily flags")
    _finish_stories(day)
    day.advance(600)
    var played := _finish_evening(day)
    _expect("salamat_due_on_release" in played and "kaveri_open_account" not in played and "blocked_account" not in played,
        "evening skips departures with missing entry flags or unmet conditions")
    _expect(day.campaign_flags.has("salamat_account_step_1") and day.merchant_trust.get("khoja_ismail") == 2,
        "a played account sets its step flag and applies trust")
    day.begin_next_day()
    _finish_stories(day)
    day.advance(600)
    played = _finish_evening(day)
    _expect("salamat_waits_offshore" in played and day.campaign_flags.has("salamat_account_step_2"),
        "the conditioned step plays with enough trust and sets its flag even without a choice")
    day.begin_next_day()
    _finish_stories(day)
    day.advance(600)
    _expect("salamat_small_lots" in _finish_evening(day), "the final step can follow a no-choice departure")


func _evidence_plates() -> void:
    root.size = Vector2i(1280, 540)
    var harbour = Harbour.instantiate()
    root.add_child(harbour)
    var day: PortDay = harbour.day
    var deputy_panel_found := false
    for label: Label in harbour.content.find_children("*", "Label", true, false):
        if label.text == "DEPUTY ASSIGNMENT":
            deputy_panel_found = true
    _expect(deputy_panel_found, "the morning briefing offers deputy assignment")
    var imported_plates := 0
    for number in range(5, 19):
        var dossier: Dictionary = day.inspections["case_%03d" % number]
        for page in dossier["evidence"]:
            if page.has("image") and ResourceLoader.exists(page["image"], "Texture2D"):
                imported_plates += 1
    _expect(imported_plates == 28, "all twenty-eight Stage B evidence plates import as textures")
    _finish_stories(day)
    day.advance(600)
    _finish_evening(day)
    day.begin_next_day()
    _finish_stories(day)
    harbour._render()
    var star: Dictionary
    for ship in day.waiting:
        if ship["id"] == "gresik_morning_star":
            star = ship
    var sprite := "res://assets/art/ships/gresik_morning_star.png"
    _expect(harbour._ship_art(star) == (sprite if ResourceLoader.exists(sprite, "Texture2D") else ""),
        "new ships resolve their named texture without requiring it to play")
    await process_frame
    await process_frame
    harbour.scroll.scroll_vertical = 100
    _expect(harbour.scroll.scroll_vertical > 0, "the player can scroll down before opening the dossier")
    harbour._berth("gresik_morning_star", true)
    _expect(harbour.scroll.scroll_vertical == 0, "opening Detailed Inspection returns the view to the top")
    var evidence: Array = day.inspection_for(day.pending_case)["evidence"]
    for index in evidence.size():
        var page: Dictionary = evidence[index]
        if not page.has("image"):
            continue
        harbour.evidence_index = index
        harbour._render()
        var found := false
        for picture: TextureRect in harbour.content.find_children("*", "TextureRect", true, false):
            if picture.texture and picture.texture.resource_path == page["image"]:
                found = true
        _expect(found, "the inspection dossier shows the selected Morning Star evidence plate")
        page["image"] = "res://assets/inspection/missing-stage-b-plate.png"
        harbour._render()
        var text_visible := false
        for label: Label in harbour.content.find_children("*", "Label", true, false):
            if label.text == page["text"]:
                text_visible = true
        _expect(text_visible, "evidence text remains when its plate is missing")
        break
    var truth: Dictionary = day.inspection_for(day.pending_case)["hidden_truth"]
    day.rule(truth["ruling_id"], truth["reason_id"])
    harbour._render()
    await process_frame
    await process_frame
    harbour.scroll.scroll_vertical = 100
    _expect(harbour.scroll.scroll_vertical > 0, "the player can scroll down before closing the watch")
    harbour._advance(600)
    _expect(day.closed() and harbour.scroll.scroll_vertical == 0, "opening End of Day returns the view to the top")
    harbour.queue_free()


func _finish_evening(day: PortDay) -> Array[String]:
    day.start_evening()
    return _finish_stories(day)


func _finish_stories(day: PortDay) -> Array[String]:
    var played: Array[String] = []
    while not day.current_story().is_empty():
        var story := day.current_story()
        played.append(story["id"])
        var choices: Array = story.get("choices", [])
        if not choices.is_empty():
            day.choose_story(choices[0]["id"])
        day.continue_story()
    return played


func _expect(condition: bool, description: String) -> void:
    if not condition:
        failures += 1
        printerr("FAIL: " + description)

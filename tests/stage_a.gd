extends SceneTree

const Harbour = preload("res://scenes/harbour.tscn")

var failures := 0


func _initialize() -> void:
    call_deferred("_run")


func _run() -> void:
    root.size = Vector2i(1280, 960)
    var harbour = Harbour.instantiate()
    root.add_child(harbour)
    var day = harbour.day
    var inspection: Dictionary = day.inspection_for(day.ship_at_anchor(2))
    if day.scenario.is_empty() or inspection.is_empty() or day.manual.is_empty():
        _expect(false, "main scene loads the day, case, and manual")
        quit(1)
        return
    _expect(inspection["title"] == "The jars from Guangzhou", "main scene loads the authored inspection")
    _expect(day.manual["entries"].size() == 11, "main scene loads all authored manual entries")
    _check_art(harbour, day)

    _expect(day.waiting.size() == 3, "morning harbour has three waiting ships")
    harbour._berth("rice", false)
    _expect(day.ship_at_anchor(0).is_empty() and day.ship_at_anchor(1).get("id") == "pepper",
        "assigning one ship keeps the other ship in its original row")
    harbour._berth("pepper", false)
    harbour._advance(60)
    _expect(day.rice == 24 and day.duty == 30, "two berths unload in parallel")
    _expect(day.ship_at_anchor(0).get("id") == "resin" and day.ship_at_anchor(2).get("id") == "porcelain",
        "a scheduled arrival fills a free slot without moving other ships")
    harbour._berth("porcelain", true)
    _expect(day.pending_case.is_empty(), "serving both early ships misses the inspection window")
    harbour._berth("porcelain", false)
    harbour._advance(60)
    _expect(day.completed == 3 and day.duty == 42, "cleared porcelain trades exactly on the deadline")

    harbour._restart()
    harbour._berth("rice", false)
    harbour._berth("porcelain", true)
    _expect(day.minute_of_day == 585 and day.berths[0]["remaining"] == 15, "one fixed inspection cost advances the other berth")
    _expect(day.waiting.size() == 2 and day.pending_case["remaining"] == 60, "scheduled arrival proceeds while porcelain awaits ruling")
    _expect(harbour.ruling_index == -1 and harbour.reason_index == -1, "ruling starts unanswered")
    var scroll := harbour.find_children("*", "ScrollContainer", true, false)[0] as ScrollContainer
    harbour.evidence_index = inspection["evidence"].size()
    harbour._render()
    await process_frame
    await process_frame
    _expect(not scroll.get_h_scroll_bar().visible, "the reference manual fits within a 1280px-wide window")
    harbour.ruling_index = 1
    harbour.reason_index = 3
    harbour._rule()
    _expect(day.recovered_duty == 0, "the weighing fee is credited only when trade completes")
    harbour._advance(60)
    _expect(day.rice == 24 and day.lost == 1 and day.duty == 38 and day.recovered_duty == 18, "correct proof recovers duty at the cost of the pepper tide")
    harbour._advance(420)
    _expect(day.closed() and day.waiting.is_empty() and day.berths.is_empty(), "the closing ledger follows a finite port day")

    harbour._restart()
    harbour._berth("pepper", false)
    harbour._berth("porcelain", true)
    day.rule("major_fraud", "foreign_seal")
    harbour._advance(60)
    _expect(day.rice == 0 and day.duty == 34 and day.recovered_duty == 0 and day.lost == 1, "ruling fraud with the wrong evidence recovers nothing")

    harbour._restart()
    harbour._berth("porcelain", true)
    day.rule("hold", "foreign_seal")
    _expect(day.lost == 1 and day.berths.is_empty(), "an unjustified hold forfeits the porcelain sale")

    harbour._restart()
    harbour._advance(30)
    _expect(day.waiting.size() == 3 and day.lost == 1, "a full anchorage forfeits the next arrival")
    root.size = Vector2i(460, 960)
    await process_frame
    await process_frame
    _expect(scroll.get_h_scroll_bar().visible, "the harbour remains horizontally scrollable at 460px")
    root.size = Vector2i(1280, 960)
    await _test_story_inspection(harbour, scroll)
    _test_late_inspections(harbour)
    _test_scheduled_inspections(harbour)
    if failures == 0:
        print("Loaded manual: %d entries; case %s (%s): %d evidence pages" % [
            day.manual["entries"].size(), inspection["id"], inspection["title"], inspection["evidence"].size(),
        ])
        print("Stage A checks passed: capacity, deadlines, trade-offs, inspection registration and proof, and closing ledger.")
    quit(1 if failures else 0)


func _test_story_inspection(harbour, scroll: ScrollContainer) -> void:
    var day = harbour.day
    harbour._restart()
    harbour._berth("rice", false)
    harbour._advance(30)
    harbour._berth("resin", false)
    _expect(day.ruling_note == "Frankincense cleared on the declaration alone.",
        "skipping the story case names the selected cargo")

    harbour._restart()
    harbour._berth("rice", false)
    harbour._advance(30)
    harbour._berth("resin", true)
    var story: Dictionary = day.inspection_for(day.pending_case)
    _expect(story.get("id") == "case_004", "the Frankincense Trader opens the authored story case")
    await process_frame
    await process_frame
    _expect(not scroll.get_h_scroll_bar().visible, "the story dossier fits within a 1280px-wide window")
    var previous_lost: int = day.lost
    day.rule("hold", "pedir_messenger")
    _expect(day.held == 1 and day.lost == previous_lost and day.berths.is_empty(),
        "the story hold resolves the ship without losing the sale or blocking a berth")
    harbour._advance(420)
    _expect("Supported holds: 1" in _label_texts(harbour.content) and day.duty == 8 and day.recovered_duty == 0,
        "the ledger records the supported hold separately and credits only the rice sale")


func _test_late_inspections(harbour) -> void:
    var day = harbour.day
    harbour._restart()
    harbour._berth("rice", false)
    harbour._berth("pepper", false)
    harbour._advance(120)
    harbour._berth("tin", true)
    _expect(day.inspection_for(day.pending_case).get("id") == "case_003" and day.minute_of_day == 690,
        "the tin trader opens the Minor Fault case for 30 minutes")
    day.rule("minor_fault", "wrong_dacing")
    harbour._berth("cloth", true)
    _expect(day.inspection_for(day.pending_case).get("id") == "case_002" and day.minute_of_day == 725,
        "the cloth trader opens the Clean case for 35 minutes")
    day.rule("clear", "piece_count")
    harbour._advance(60)
    _expect(day.completed == 4 and day.duty == 54 and day.recovered_duty == 1,
        "the minor fault adds one duty and the correct clear releases cloth at declared duty")


func _test_scheduled_inspections(harbour) -> void:
    var day = harbour.day
    var fixture_dir := "user://stage-a-%d-%d" % [OS.get_process_id(), Time.get_ticks_usec()]
    var schedule_path := fixture_dir.path_join("port_day.json")
    var first_case_path := fixture_dir.path_join("case_001.json")
    var second_case_path := fixture_dir.path_join("case_002.json")
    var schedule: Dictionary = day.scenario.duplicate(true)
    schedule["ships"] = [
        {"id": "plain", "name": "Plain trader", "cargo": "Rice", "arrival": 540, "departure": 660, "minutes": 60, "duty": 8, "rice": 24},
        {"id": "first", "name": "First trader", "cargo": "Porcelain", "arrival": 540, "departure": 660, "minutes": 60, "duty": 12, "rice": 0, "inspection_case": "case_001"},
        {"id": "second", "name": "Second trader", "cargo": "Tin", "arrival": 540, "departure": 657, "minutes": 60, "duty": 10, "rice": 0, "inspection_case": "case_002"},
    ]
    var second_case := {
        "id": "case_002", "title": "Second inspection", "subtitle": "Test dossier", "minutes": 12,
        "evidence": [{"id": "second_page", "label": "01  Test page", "title": "Second evidence", "text": "Test evidence."}],
        "rulings": [
            {"id": "amend_test", "label": "Amend test duty"},
            {"id": "clear", "label": "Clear as declared"},
            {"id": "hold", "label": "Hold the cargo"},
        ],
        "reasons": [{"id": "second_page", "label": "Cite the test page"}],
        "hidden_truth": {
            "ruling_id": "amend_test", "reason_id": "second_page", "extra_duty": 3,
            "success": "Second ruling accepted.", "clear": "Cleared.", "hold": "Held.", "unsupported": "Unsupported.",
        },
    }
    var fixture_written := DirAccess.make_dir_absolute(fixture_dir) == OK \
        and DirAccess.copy_absolute("res://data/inspections/case_001.json", first_case_path) == OK \
        and _write_json(schedule_path, schedule) and _write_json(second_case_path, second_case)
    _expect(fixture_written, "write an isolated schedule with two case files")
    if fixture_written:
        var loaded: bool = day.load_data(schedule_path, fixture_dir)
        _expect(loaded, "load both scheduled inspection files")
        if loaded:
            harbour._restart()
            harbour._berth("plain", true)
            _expect(day.berths.is_empty(), "ships with no case cannot be inspected")
            harbour._berth("first", true)
            _expect(day.minute_of_day == 585, "first inspection uses its own duration")
            day.rule("clear", "foreign_seal")
            harbour._berth("second", true)
            _expect(day.minute_of_day == 597 and day.pending_case.get("id") == "second",
                "second inspection uses its own duration for the deadline and clock")
            if not day.pending_case.is_empty():
                var captions := _label_texts(harbour.content)
                _expect("Second inspection" in captions and "Second evidence" in captions,
                    "the dossier displays the second case's title and evidence")
                harbour.ruling_index = 0
                harbour.reason_index = 0
                harbour._rule()
                _expect(day.ruling_note == "Second ruling accepted.", "the second case uses its own choices and hidden truth")
                harbour._advance(60)
                _expect(day.recovered_duty == 3, "the second case's duty is credited at unloading")
            _test_reserved_rulings(day)

        for field in ["rulings", "reasons"]:
            var invalid_case := second_case.duplicate()
            invalid_case[field] = []
            if _write_json(second_case_path, invalid_case):
                print("Expecting an empty-%s error for case_002.json:" % field)
                _expect(not day.load_data(schedule_path, fixture_dir), "reject a case with empty %s" % field)
            else:
                _expect(false, "write a case with empty %s" % field)

        schedule["ships"][2]["inspection_case"] = "case_missing"
        if _write_json(schedule_path, schedule):
            print("Expecting a missing-data error for case_missing.json:")
            _expect(not day.load_data(schedule_path, fixture_dir), "reject a schedule that names a missing case")
        else:
            _expect(false, "write the schedule with a missing case")

    for path in [schedule_path, first_case_path, second_case_path, fixture_dir]:
        if FileAccess.file_exists(path) or DirAccess.dir_exists_absolute(path):
            DirAccess.remove_absolute(path)


func _test_reserved_rulings(day) -> void:
    for ruling in ["clear", "hold"]:
        day.reset()
        var truth: Dictionary = day.inspection_for(day.ship_at_anchor(2))["hidden_truth"]
        truth["ruling_id"] = ruling
        day.berth("second", true)
        day.rule(ruling, "second_page")
        day.advance(60)
        _expect(day.ruling_note == "Second ruling accepted.", "supported %s uses the success feedback" % ruling)
        if ruling == "clear":
            _expect(day.duty == 10 and day.recovered_duty == 0, "supported clear trades at declared duty")
        else:
            _expect(day.completed == 0 and day.held == 1 and day.lost == 0 and day.duty == 0,
                "supported hold prevents trade without loss")


func _write_json(path: String, value: Dictionary) -> bool:
    var file := FileAccess.open(path, FileAccess.WRITE)
    if file == null:
        return false
    file.store_string(JSON.stringify(value))
    return file.get_error() == OK


func _label_texts(node: Node) -> Array[String]:
    var captions: Array[String] = []
    for label in node.find_children("*", "Label", true, false):
        captions.append(label.text)
    return captions


func _check_art(harbour, day) -> void:
    var paths: Array = day.scenario["art"].values()
    for ship in day.scenario["ships"]:
        paths.append_array([ship["image"], ship["cargo_image"]])
    for inspection in day.inspections.values():
        paths.append_array(inspection.get("art", {}).values())
        for page in inspection["evidence"]:
            if page.has("image"):
                paths.append(page["image"])
    for path in paths:
        _expect(ResourceLoader.exists(path, "Texture2D"), "Stage A art resolves: " + path)
    _expect(harbour.find_children("*", "TextureRect", true, false).size() >= 8, "port day shows the harbour, ship and cargo art")
    var holder := Control.new()
    var fallback = harbour._art(holder, "res://assets/art/ships/missing.png", Vector2(10, 10), "Porcelain")
    _expect(fallback is Label and fallback.text == "Porcelain", "a missing art path falls back to text")
    _expect(harbour._art(holder, "", Vector2(10, 10)) == null, "art without a path or fallback adds nothing")
    holder.free()


func _expect(condition: bool, message: String) -> void:
    if not condition:
        failures += 1
        push_error("FAILED: " + message)

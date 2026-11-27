extends SceneTree
## Native drag/drop and the complete new Day 1 loop, plus rule-boundary checks.

const DayOne = preload("res://scenes/day_one.tscn")
var failures := 0


func _initialize() -> void:
    call_deferred("_run")


func _run() -> void:
    root.size = Vector2i(1280, 720)
    var game = DayOne.instantiate()
    root.add_child(game)
    await process_frame
    _expect(ProjectSettings.get_setting("application/run/main_scene") == "res://scenes/day_one.tscn", "F5 opens the hands-on Day 1 scene")
    _expect(game.day.waiting.size() == 3 and game.day.current_story().is_empty(), "the opening is playable without dismissing a briefing")
    _expect(game.find_children("*", "OptionButton", true, false).is_empty(), "no core action uses a dropdown")
    _expect(game.day.day_number == 1 and game.day.minute_of_day == 540, "Day 1 begins at 09:00")

    # Exercise Godot's real GUI drag routing, not only the controller's callback.
    await _drag(Vector2(245, 550), Vector2(575, 350))
    _expect(game.day.ship_at_berth(1).get("id") == "rice" and game.day.ship_at_berth(0).is_empty(), "a dragged rice ship occupies the exact right-hand berth")
    _expect(game.day.minute_of_day == 540, "berthing does not secretly advance the clock")
    if game.day.berths.is_empty():
        # Keep diagnostics meaningful if the native drag assertion fails.
        game.assign_berth("rice", 1, false)
    var before: int = game.day.waiting.size()
    game.request_berth("pepper", 1)
    _expect(game.day.waiting.size() == before and game.proposed_ship.is_empty(), "occupied drops never move a second ship")
    game.request_berth("porcelain", 0)
    _expect(game.proposed_ship == "porcelain" and game.day.pending_case.is_empty(), "dropping case cargo offers unload or inspect before committing")
    game.assign_berth("porcelain", 0, true)
    _expect(game.day.pending_case.get("id") == "porcelain" and game.day.minute_of_day == 585, "inspection opens the existing case and charges its fixed 45 minutes")
    _expect(game.day.ship_at_berth(1)["remaining"] == 15 and game.day.waiting.size() == 2, "the other berth and scheduled arrivals work during inspection")
    _expect(game.viewed == {"manifest": true}, "opened cargo and measurements are not revealed in advance")
    game.choose_stamp("major_fraud")
    game.choose_method("contents")
    game.apply_stamp()
    _expect(game.method.is_empty() and not game.day.pending_case.is_empty(), "unexamined evidence cannot be cited")
    game.show_evidence(3)
    game.choose_method("contents")
    game.apply_stamp()
    _expect(not game.day.pending_case.is_empty(), "the tutorial requires checking the manual before stamping")
    game.open_manual()
    _expect(game.manual_open and game.manual_seen, "the manual opens as an object on the desk")
    for page in range(game.day.manual["entries"].size()):
        game.manual_page = page
        game.render()
    game.manual_open = false
    game.apply_stamp()
    _expect(game.day.pending_case.is_empty() and game.feedback_open, "stamping files the ruling and shows its consequence")
    _expect(game.day.flags.has("case_001_major_fraud") and game.day.ruling_note == game.day.inspections["case_001"]["hidden_truth"]["success"], "the supported stamp preserves the authored outcome")
    _expect(game.last_feedback == game.day.ruling_note, "successful feedback retains the full explanation of the evidence and fees")
    game.feedback_open = false
    game.advance(75)
    _expect(game.day.rice == 24 and game.day.recovered_duty == 18 and game.day.completed == 2, "rice and inspected porcelain finish with their original consequences")
    game.assign_berth("resin", 0, false)
    game.assign_berth("tin", 1, false)
    game.advance(60)
    game.assign_berth("cloth", 0, false)
    game.advance(60)
    game.close_watch()
    _expect(game.day.closed() and game.day.completed == 5 and game.day.lost == 1, "a complete Day 1 reaches its closing screen")
    _expect(not _button_exists(game, "Begin day 2") and not _button_exists(game, "Continue to evening"), "later days and office systems stay out of the playable flow")
    game.restart()
    _expect(game.day.day_number == 1 and game.day.minute_of_day == 540 and game.day.waiting.size() == 3 and game.inspections_filed == 0, "replay restores a clean Day 1")
    game.advance(30)
    game.request_berth("porcelain", 1)
    game.assign_berth("porcelain", 1, true)
    _expect(game.day.pending_case.is_empty() and game.day.ship_at_berth(1).is_empty(), "the inspection deadline cannot be bypassed through a stale action")
    game.request_berth("missing_ship", 0)
    game.request_berth("rice", -2)
    _expect(game.day.berths.is_empty(), "invalid ship and berth data never mutate the port")
    game.restart()
    game.day.berth("rice", false, -2)
    game.day.berth("rice", false, 2)
    _expect(game.day.berths.is_empty() and game.day.waiting.size() == 3, "the model rejects out-of-range explicit slots before removing a ship")
    game.day.berth("rice", false, 1)
    game.day.berth("pepper", false, 1)
    _expect(game.day.berths.size() == 1 and game.day.ship_at_berth(1)["id"] == "rice", "the model rejects occupied explicit slots")
    game.queue_free()
    await process_frame
    await _other_cases()
    if failures == 0:
        print("Day 1 checks passed: native drag/drop, exact berth, fixed clock, inspection tools/manual/stamps, original outcomes, closing and replay.")
    quit(1 if failures else 0)


func _other_cases() -> void:
    for example in [["resin", 60, "hold", "contents"], ["tin", 70, "minor_fault", "testimony"], ["cloth", 120, "clear", "measurements"]]:
        var game = DayOne.instantiate()
        root.add_child(game)
        game.assign_berth("rice", 0, false)
        game.assign_berth("pepper", 1, false)
        game.advance(example[1])
        game.assign_berth(example[0], 1, true)
        _expect(not game.day.pending_case.is_empty(), "%s opens its original case" % example[0])
        if not game.day.pending_case.is_empty():
            var case_id: String = game.day.pending_case["inspection_case"]
            for index in 4:
                game.show_evidence(index)
                game._evidence_turn(1)
                game._evidence_turn(-1)
            game.manual_seen = true
            game.choose_method(example[3])
            game.choose_stamp(example[2])
            game.apply_stamp()
            _expect(game.day.flags.has(case_id + "_" + example[2]), "%s preserves its supported ruling" % example[0])
            _expect(game.last_feedback == game.day.inspections[case_id]["hidden_truth"]["success"], "%s retains every paragraph of the authored finding" % example[0])
        game.queue_free()
        await process_frame


func _drag(from: Vector2, to: Vector2) -> void:
    var motion := InputEventMouseMotion.new()
    motion.position = from
    root.push_input(motion)
    await process_frame
    var press := InputEventMouseButton.new()
    press.position = from
    press.button_index = MOUSE_BUTTON_LEFT
    press.pressed = true
    root.push_input(press)
    await process_frame
    for step in range(1, 8):
        motion = InputEventMouseMotion.new()
        motion.position = from.lerp(to, step / 7.0)
        motion.relative = (to - from) / 7.0
        motion.button_mask = MOUSE_BUTTON_MASK_LEFT
        root.push_input(motion)
        await process_frame
    press = InputEventMouseButton.new()
    press.position = to
    press.button_index = MOUSE_BUTTON_LEFT
    press.pressed = false
    root.push_input(press)
    await process_frame


func _button_exists(node: Node, caption: String) -> bool:
    for button in node.find_children("*", "Button", true, false):
        if button.text == caption:
            return true
    return false


func _expect(condition: bool, message: String) -> void:
    if not condition:
        failures += 1
        push_error("FAILED: " + message)

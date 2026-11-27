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
    var localized_title: String = ProjectSettings.get_setting("application/config/name")
    _expect(game._title_with_system_fonts(localized_title, []) == "Gangwuzhang: Maliujia 1511 - Di Yi Ri", "a native title without CJK fonts uses romanization instead of boxes")
    _expect(game._title_with_system_fonts(localized_title, ["res://assets/fonts/NotoSansTC.ttf"]) == localized_title, "a title font with CJK glyphs keeps the Traditional Chinese caption")
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
    var before: Array = game.day.waiting.duplicate()
    await _drag(Vector2(1025, 550), Vector2(575, 350))
    _expect(game.day.waiting == before and game.day.berths.size() == 1, "occupied drops never move a second ship")
    _expect(game.day.ship_at_berth(1).get("id") == "rice" and game.day.minute_of_day == 540, "an occupied drop leaves the berth and clock unchanged")
    _expect(_label_exists(game, "此泊位已有船隻，請使用另一泊位。"), "an occupied drop shows the reason and points to the open berth")
    await _drag(Vector2(1025, 550), Vector2(215, 350))
    _expect(game.day.ship_at_berth(0).get("id") == "porcelain" and game.day.pending_case.is_empty() and game.day.minute_of_day == 540, "dropping case cargo berths it at once without a choice dialog")
    _expect(game.day.ship_at_berth(0).get("inspection_open", false), "a berthed case ship stays open for inspection")
    _expect(game.notice.is_empty(), "a successful retry clears the refusal")
    var marker := _accessible_button(game, "驗貨")
    _expect(marker != null and not marker.disabled, "the berthed ship shows a clickable 驗貨 marker")
    _expect(_label_containing(game, "請按船旁的「驗貨」標記"), "the assistant says where to click to inspect")
    _expect(game._harbour_hint() == game._hint_text("inspect_berthed", ""), "the harbour hint points to the berth marker")
    if marker != null:
        marker.pressed.emit()
    else:
        game.inspect_berth(0)
    _expect(game.day.pending_case.get("id") == "porcelain" and game.day.minute_of_day == 585, "inspection opens the existing case and charges its fixed 45 minutes")
    _expect(game.day.ship_at_berth(1)["remaining"] == 15 and game.day.waiting.size() == 2, "the other berth and scheduled arrivals work during inspection")
    _expect(game.viewed == {"manifest": true}, "opened cargo and measurements are not revealed in advance")
    var stamp_buttons := 0
    var manual_found := false
    for button in game.find_children("*", "Button", true, false):
        if button.accessibility_name == "驗貨手冊":
            _expect(button.tooltip_text.is_empty(), "hovering the manual does not cover its caption")
            for label in button.find_children("*", "Label", true, false):
                manual_found = manual_found or label.text.begins_with("驗貨手冊\n")
        if button.tooltip_text in game.STAMPS.values():
            stamp_buttons += 1
            for label in button.find_children("*", "Label", true, false):
                _expect(label.text == button.tooltip_text, "stamp faces and tooltips show only the plain action, never a ruling description")
    _expect(stamp_buttons == 4, "the desk offers four plain-name stamps without verdict hints")
    _expect(manual_found, "the manual has a visible Traditional Chinese caption and accessible name")
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
    _expect(not game.manual_full and game.manual_pages().size() == 4, "the manual opens on its short Day 1 digest")
    for page in range(game.manual_pages().size()):
        game.manual_page = page
        game.render()
        await process_frame
        var digest := game.find_children("*", "ScrollContainer", true, false)
        _expect(not digest.is_empty() and not (digest[-1] as ScrollContainer).get_v_scroll_bar().visible, "digest page %d fits without scrolling" % (page + 1))
    game.manual_page = 1
    game.render()
    _expect(_text_shown(game, "向左的魚：彭亨商人恩吉哈姆扎（已停權"), "the digest keeps the authored register")
    _press_text(game, "閱讀完整手冊（11頁）")
    _expect(game.manual_full, "the full 11-page manual stays one click away")
    for page in range(game.day.manual["entries"].size()):
        game.manual_full_page = page
        game.render()
    _press_text(game, "返回摘要")
    _expect(not game.manual_full, "the full manual returns to the digest")
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
    marker = _accessible_button(game, "驗貨")
    _expect(marker != null and marker.disabled and _label_containing(game, "已來不及在潮汐前驗貨"), "a late case ship shows the marker as too late and the assistant says so")
    game.inspect_berth(1)
    game.day.inspect_berthed("porcelain")
    _expect(game.day.pending_case.is_empty() and game.day.minute_of_day == 570, "the inspection deadline cannot be bypassed through a stale action")
    game.request_berth("missing_ship", 0)
    game.request_berth("rice", -2)
    _expect(game.day.berths.size() == 1, "invalid ship and berth data never mutate the port")
    game.advance(15)
    _expect(game.day.flags.has("case_001_clear") and not game.day.ship_at_berth(1).get("inspection_open", false) and game.day.ship_at_berth(1)["remaining"] == 45, "moving the clock unloads an uninspected ship on its declaration")
    _expect(_accessible_button(game, "驗貨") == null, "the marker leaves once unloading begins")
    game.restart()
    game.assign_berth("rice", 0, false)
    game.assign_berth("pepper", 1, false)
    game.advance(70)
    game.request_berth("resin", 0)
    game.request_berth("tin", 1)
    game.inspect_berth(0)
    _expect(game.day.pending_case.get("id") == "resin" and game.day.flags.has("case_003_clear"), "inspecting one berth unloads the other waiting case on its declaration")
    game.restart()
    game.request_berth("porcelain", 0)
    game.selected_ship = "rice"
    game.inspect_berth(0)
    _expect(game.day.pending_case.is_empty() and not game.notice.is_empty() and game.day.ship_at_berth(0).get("inspection_open", false), "clicking the marker while placing a ship reports the occupied berth instead of inspecting")
    _expect(game.selected_ship.is_empty(), "a rejected placement on the marker drops the selection so the next click inspects")
    game.inspect_berth(0)
    _expect(game.day.pending_case.get("id") == "porcelain", "the marker inspects once nothing is being placed")
    game.restart()
    game.day.berth("rice", false, -2)
    game.day.berth("rice", false, 2)
    _expect(game.day.berths.is_empty() and game.day.waiting.size() == 3, "the model rejects out-of-range explicit slots before removing a ship")
    game.day.berth("rice", false, 1)
    game.day.berth("pepper", false, 1)
    _expect(game.day.berths.size() == 1 and game.day.ship_at_berth(1)["id"] == "rice", "the model rejects occupied explicit slots")
    game.assign_berth("pepper", 0, false)
    await process_frame
    await _drag(Vector2(1025, 550), Vector2(575, 350))
    _expect(game.day.berths.size() == 2 and game.day.waiting.size() == 1, "a drop when both berths are full leaves the remaining ship waiting")
    _expect(game.notice == "兩個泊位均已佔用，請推進至下次港鐘。", "a full harbour points to the next bell rather than another berth")
    game.queue_free()
    await process_frame
    await _other_cases()
    await _wrong_rulings()
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


func _wrong_rulings() -> void:
    for example in [["porcelain", 0, "clear", "罰款"], ["resin", 60, "clear", "扣留"], ["tin", 70, "clear", "更正"], ["cloth", 120, "minor_fault", "放行"]]:
        var game = DayOne.instantiate()
        root.add_child(game)
        if example[1] > 0:
            game.assign_berth("rice", 0, false)
            game.assign_berth("pepper", 1, false)
            game.advance(example[1])
        game.assign_berth(example[0], 1, true)
        _expect(not game.day.pending_case.is_empty(), "%s opens for wrong-ruling feedback" % example[0])
        if not game.day.pending_case.is_empty():
            var inspection: Dictionary = game.day.inspection_for(game.day.pending_case)
            var explanation: String = inspection["hidden_truth"]["feedback_by_method"]["manifest"]
            var correction := "正確判決：應蓋「%s」" % example[3]
            game.choose_method("manifest")
            game.choose_stamp(example[2])
            game.apply_stamp()
            _expect(not game.feedback_open and not game.day.pending_case.is_empty(), "%s reveals no feedback before filing" % example[0])
            game.open_manual()
            game.manual_open = false
            game.apply_stamp()
            _expect(game.feedback_open and game.day.pending_case.is_empty(), "%s displays feedback after filing" % example[0])
            _expect(game.last_feedback.ends_with(correction + "\n" + explanation), "%s names the correct stamp and keeps the evidence explanation" % example[0])
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


func _accessible_button(node: Node, caption: String) -> Button:
    for button in node.find_children("*", "Button", true, false):
        if button.accessibility_name == caption and button.is_visible_in_tree():
            return button
    return null


func _label_containing(node: Node, fragment: String) -> bool:
    for label in node.find_children("*", "Label", true, false):
        if label.text.contains(fragment):
            return true
    return false


func _text_shown(node: Node, part: String) -> bool:
    for label in node.find_children("*", "Label", true, false):
        if (label as Label).text.contains(part):
            return true
    return false


func _press_text(node: Node, caption: String) -> void:
    for button in node.find_children("*", "Button", true, false):
        if (button as Button).text == caption:
            (button as Button).pressed.emit()
            return
    _expect(false, "button %s exists" % caption)


func _label_exists(node: Node, caption: String) -> bool:
    for label in node.find_children("*", "Label", true, false):
        if label.text == caption:
            return true
    return false


func _expect(condition: bool, message: String) -> void:
    if not condition:
        failures += 1
        push_error("FAILED: " + message)

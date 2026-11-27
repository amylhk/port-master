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
    await _drag(_anchor_point(game, 0), _berth_point(game, 1))
    _expect(game.day.ship_at_berth(1).get("id") == "rice" and game.day.ship_at_berth(0).is_empty(), "a dragged rice ship occupies the exact right-hand berth")
    _expect(game.day.minute_of_day == 540, "berthing does not secretly advance the clock")
    if game.day.berths.is_empty():
        # Keep diagnostics meaningful if the native drag assertion fails.
        game.assign_berth("rice", 1, false)
    var before: Array = game.day.waiting.duplicate()
    await _drag(_anchor_point(game, 2), _berth_point(game, 1))
    _expect(game.day.waiting == before and game.day.berths.size() == 1, "occupied drops never move a second ship")
    _expect(game.day.ship_at_berth(1).get("id") == "rice" and game.day.minute_of_day == 540, "an occupied drop leaves the berth and clock unchanged")
    _expect(_label_exists(game, "此泊位已有船隻，請使用另一泊位。"), "an occupied drop shows the reason and points to the open berth")
    await _drag(_anchor_point(game, 2), _berth_point(game, 0))
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
    _expect(game.viewed.is_empty(), "no citation is unlocked before its source is examined")
    var stamp_buttons := 0
    var stamp_order: Array[String] = []
    var manual_found := false
    for button in game.find_children("*", "Button", true, false):
        if button.accessibility_name == "驗貨手冊":
            _expect(button.tooltip_text.is_empty(), "hovering the manual does not cover its caption")
            for label in button.find_children("*", "Label", true, false):
                manual_found = manual_found or label.text.begins_with("驗貨手冊\n")
        if button.tooltip_text in game.STAMPS.values():
            stamp_buttons += 1
            stamp_order.append(button.tooltip_text)
            for label in button.find_children("*", "Label", true, false):
                _expect(label.text == button.tooltip_text, "stamp faces and tooltips show only the plain action, never a ruling description")
    _expect(stamp_buttons == 4, "the desk offers four plain-name stamps without verdict hints")
    var digest_order: Array[String] = []
    for line in game.manual_pages()[-1]["lines"]:
        digest_order.append(str(line).get_slice("：", 0))
    _expect(stamp_order == digest_order, "the desk stamps follow the same order as the manual digest")
    _expect(manual_found, "the manual has a visible Traditional Chinese caption and accessible name")
    game.choose_stamp("major_fraud")
    game.choose_method("contents")
    game.apply_stamp()
    _expect(game.method.is_empty() and not game.day.pending_case.is_empty(), "unexamined evidence cannot be cited")
    _expect(_accessible_button(game, "開封前排陶甕") != null and _accessible_button(game, "開封後排陶甕") != null and _accessible_button(game, "開封第7包生絲") != null, "each package starts closed and can be opened individually")
    _expect(not _text_shown(game, "30隻青花小碗") and not _text_shown(game, "肉豆蔻，約18斤"), "closed packages reveal none of their findings")
    _press_accessible(game, "開封前排陶甕")
    _expect(_text_shown(game, "30隻青花小碗") and not _text_shown(game, "肉豆蔻，約18斤"), "opening the front jar reveals only that jar's contents")
    _expect(_accessible_button(game, "查看前排陶甕") != null and _accessible_button(game, "開封後排陶甕") != null and _accessible_button(game, "開封第7包生絲") != null, "opening one package leaves its neighbours closed")
    _press_text(game, "查看完整證據")
    _expect(game.detail_open and not game.detail_text.contains("肉豆蔻"), "the full reading cannot reveal a closed package")
    _press_text(game, "返回驗貨桌")
    _press_accessible(game, "開封後排陶甕")
    _press_text(game, "查看完整證據")
    _expect(game.detail_open and not game.detail_text.contains("天猛公") and game.detail_text.contains("肉豆蔻，約18斤"), "full desk evidence keeps the observations without suggesting a referral")
    _expect(game.day.inspections["case_001"]["evidence"][3]["text"].contains("天猛公"), "neutral presentation leaves the authored case unchanged")
    _press_text(game, "返回驗貨桌")
    _expect(not game.viewed.has("contents"), "cargo is not ready to cite while a package remains closed")
    _press_accessible(game, "開封第7包生絲")
    _expect(_text_shown(game, "生絲已乾") and not _text_shown(game, "肉豆蔻，約18斤"), "opening the silk does not combine findings")
    _press_accessible(game, "查看後排陶甕")
    _expect(game.viewed.has("contents") and _text_shown(game, "肉豆蔻，約18斤") and not game.feedback_open, "revisiting a package retains its findings without returning a verdict")
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
    _expect(game.day.rice == 22 and game.day.recovered_duty == 18 and game.day.completed == 2, "only the sound rice is usable and inspected porcelain still recovers its fees")
    _expect(not _label_containing(game, "請趕在10:15離港潮前卸下全數24袋米"), "the completed rice task no longer shows its urgent reminder")
    _expect(_label_containing(game, "卸貨時發現2袋濕米"), "the colleague reports the wet rice upon unloading")
    _press_text(game, "港口同僚")
    _expect(game.notes_open and game.notes_id == "day_01_turn_of_the_monsoon", "the full Day 1 briefing remains accessible after rice delivery")
    _press_text(game, "返回港口")
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
    game.assign_berth("rice", 0, false)
    game.assign_berth("pepper", 1, false)
    game.advance(70)
    game.request_berth("resin", 0)
    game.request_berth("tin", 1)
    game.day.ship_at_berth(0)["departure"] = game.day.minute_of_day + 61
    game.render()
    _expect(not game.day.can_inspect_berthed(game.day.ship_at_berth(0)) and game.day.can_inspect_berthed(game.day.ship_at_berth(1)), "the first case is too late but the second can still be inspected")
    _expect(_label_containing(game, game.day.ship_at_berth(1)["name"] + "已靠泊位2"), "the colleague points to the inspectable second case rather than advising a clock advance")
    _expect(game._harbour_hint() == game._hint_text("inspect_berthed", ""), "the top hint also offers inspection while any case remains eligible")
    game.restart()
    game.day.berth("rice", false, -2)
    game.day.berth("rice", false, 2)
    _expect(game.day.berths.is_empty() and game.day.waiting.size() == 3, "the model rejects out-of-range explicit slots before removing a ship")
    game.day.berth("rice", false, 1)
    game.day.berth("pepper", false, 1)
    _expect(game.day.berths.size() == 1 and game.day.ship_at_berth(1)["id"] == "rice", "the model rejects occupied explicit slots")
    game.assign_berth("pepper", 0, false)
    await process_frame
    await _drag(_anchor_point(game, 2), _berth_point(game, 1))
    _expect(game.day.berths.size() == 2 and game.day.waiting.size() == 1, "a drop when both berths are full leaves the remaining ship waiting")
    _expect(game.notice == "兩個泊位均已佔用，請推進至下次港鐘。", "a full harbour points to the next bell rather than another berth")
    game.queue_free()
    await process_frame
    await _other_cases()
    await _wrong_rulings()
    await _harbour_status_routing()
    await _berthed_hull_routing()
    await _expired_rice_reminder()
    await _manual_across_cases()
    await _rice_spot_check()
    await _duty_score()
    await _closing_help_focus()
    await _citation_locks()
    if failures == 0:
        print("Day 1 checks passed: native drag/drop, inspection and stamps, rice spot checks, immediate HUD and duty outcomes, closing and replay.")
    quit(1 if failures else 0)


func _manual_across_cases() -> void:
    var game = DayOne.instantiate()
    root.add_child(game)
    game.assign_berth("porcelain", 0, true)
    game.open_manual()
    _press_text(game, "合上手冊")
    for index in game.CRATE_NAMES["case_001"].size():
        game.open_crate(index)
    game.choose_method("contents")
    game.choose_stamp("major_fraud")
    game.apply_stamp()
    _expect(game.day.pending_case.is_empty(), "the first case files after reading the manual")
    _press_text(game, "返回港口")
    game.assign_berth("resin", 1, true)
    _expect(game.day.pending_case.get("id") == "resin", "a second case opens in the same watch")
    _expect(game.manual_seen, "a manual read earlier in the watch remains read on the second case")
    game.choose_method("contents")
    game.choose_stamp("hold")
    game.apply_stamp()
    _expect(game.day.pending_case.get("id") == "resin", "the second case still requires its own inspected evidence")
    for index in game.CRATE_NAMES["case_004"].size():
        game.open_crate(index)
    game.choose_method("contents")
    _expect(game.find_children("*", "Button", true, false).any(func(button: Button) -> bool: return button.text == "蓋印：扣留" and not button.disabled), "the second-case filing button enables without reopening the manual")
    game.apply_stamp()
    _expect(game.day.pending_case.is_empty() and game.day.flags.has("case_004_hold"), "the second supported filing needs no manual reopen")
    game.restart()
    _expect(not game.manual_seen, "a fresh watch resets the manual tutorial gate")
    game.queue_free()
    await process_frame


func _rice_spot_check() -> void:
    var game = DayOne.instantiate()
    root.add_child(game)
    _expect(_label_exists(game, "國庫  0") and _label_exists(game, "存糧  12 袋") and _label_exists(game, "盡忠職守  0"), "only Day 1's three metrics start on the HUD")
    _press_accessible(game, "盡忠職守說明")
    _expect(game.detail_open and _text_shown(game, "正確蓋印") and _text_shown(game, "準時卸貨") and _text_shown(game, "不滿離港") and _text_shown(game, "略過驗貨不會扣分"), "the HUD explains duty gains and losses without showing a case")
    _press_text(game, "關閉說明")
    _expect(not game.detail_open and game.day.minute_of_day == 540 and game.day.watch_score == 0, "closing duty help does not change the watch")
    game.request_berth("rice", 0)
    game.inspect_berth(0)
    _expect(game.day.minute_of_day == 540 and game.stamp.is_empty(), "entering rice inspection is free and the chit is blank")
    _expect(not _text_shown(game, "沾上水氣") and _accessible_button(game, "開封四號袋") != null, "closed sacks do not disclose their contents")
    var closed_paint := _sack_paint(game, "開封一號袋")
    _expect(closed_paint != null and closed_paint.resource_path == "res://assets/art/inspection/rice_sack_closed.png", "closed sacks use the imported painting")
    _press_accessible(game, "開封一號袋")
    _expect(game.day.minute_of_day == 545 and game.viewed.has("contents") and _text_shown(game, "粒粒分明"), "one clean sack costs five minutes and can already be cited")
    var open_paint := _sack_paint(game, "查看一號袋")
    _expect(open_paint != null and open_paint.resource_path == "res://assets/art/inspection/rice_sack_open.png" and _sack_paint(game, "開封二號袋") == closed_paint, "only the opened sack switches paintings")
    game.rice_sack_paint.erase(true)
    game.render()
    _expect(_accessible_button(game, "查看一號袋") != null and _sack_paint(game, "查看一號袋") == null and _sack_paint(game, "開封二號袋") == closed_paint, "a missing opened painting falls back without affecting the closed sacks")
    game.rice_sack_paint[true] = open_paint
    _press_accessible(game, "盡忠職守說明")
    _expect(game.detail_open and not game.detail_text.contains("濕米") and game.stamp.is_empty(), "duty help does not hint at the desk's ruling")
    _press_text(game, "關閉說明")
    _expect(not game.detail_open and game.day.pending_case.get("id") == "rice" and game.day.minute_of_day == 545, "closing duty help returns to the same inspection")
    _press_accessible(game, "查看一號袋")
    _expect(game.day.minute_of_day == 545 and not _text_shown(game, "沾上水氣"), "revisiting the sack is free and does not reveal other sacks")
    _press_accessible(game, "開封二號袋")
    _expect(game.day.minute_of_day == 550 and _text_shown(game, "沾上水氣"), "only the newly opened wet sack reveals its condition")
    game.open_manual()
    _press_text(game, "合上手冊")
    game.choose_method("contents")
    game.choose_stamp("major_fraud")
    game.apply_stamp()
    _expect(game.day.watch_score == 3 and game.day.watch_stock == 12 and game.day.duty == 0, "a supported fine scores immediately; stock and tax wait for unload")
    _press_text(game, "返回港口")
    game.assign_berth("porcelain", 1, true)
    _expect(game.day.minute_of_day == 595 and game.day.pending_case.get("id") == "porcelain" and game.day.ship_at_berth(0)["remaining"] == 15, "two samples leave enough time to inspect 金豐號 while the rice unloads")
    for index in game.CRATE_NAMES["case_001"].size():
        game.open_crate(index)
    game.choose_stamp("major_fraud")
    game.choose_method("contents")
    game.apply_stamp()
    _press_text(game, "返回港口")
    var score_before: int = game.day.watch_score
    game.advance(14)
    _expect(game.day.watch_stock == 12 and game.day.duty == 0, "the sorted stock does not post a minute before unloading")
    game.advance(1)
    _expect(game.day.watch_stock == 34 and game.day.rice == 22 and game.day.watch_score == score_before + 1 and game.day.duty == 6, "sorted rice posts usable stock and reduced tax at unload, with on-time credit")
    _expect(_label_containing(game, "22袋乾米已入庫") and _label_exists(game, "存糧  34 袋"), "the colleague and HUD update on the same bell")
    game.restart()
    game.assign_berth("rice", 0, true)
    game.open_crate(1)
    game.manual_seen = true
    game.choose_method("contents")
    game.choose_stamp("hold")
    game.apply_stamp()
    _expect(game.day.flags.has("day_1_rice_hold") and game.day.watch_score == 3, "refusal also scores with observed evidence")
    _press_text(game, "返回港口")
    game.advance(60)
    _expect(game.day.duty == 6 and game.day.watch_stock == 34 and game.day.watch_score == 4, "refusing only the damp sacks preserves the dry delivery at reduced tax")
    game.restart()
    game.assign_berth("rice", 0, true)
    for index in 4:
        game.open_crate(index)
    _expect(game.day.minute_of_day == 560 and _label_containing(game, "已來不及在潮汐前卸貨"), "a fourth sack makes a timely unload impossible")
    game.manual_seen = true
    game.choose_method("contents")
    game.choose_stamp("clear")
    game.apply_stamp()
    _expect(not game.last_feedback.contains("濕米") and game.day.watch_score == 0, "clearing a sampled load does not report the unloading consequence early")
    _press_text(game, "返回港口")
    game.advance(54)
    var before_tide: int = game.day.watch_score
    game.advance(1)
    _expect(game.day.minute_of_day == 615 and game.day.duty == 0 and game.day.watch_stock == 12 and game.day.watch_score == before_tide - 4 and game.day.flags.has_all(["rice_unhappy_departure", "pepper_unhappy_departure"]), "the overchecked rice ship and the waiting pepper ship each leave at the tide without paying tax")
    game.queue_free()
    await process_frame


func _duty_score() -> void:
    var game = DayOne.instantiate()
    root.add_child(game)
    game.assign_berth("rice", 0, false)
    game.assign_berth("pepper", 1, false)
    game.advance(59)
    _expect(game.day.watch_stock == 12 and game.day.watch_score == 0, "neither skip adjusts stock or score before unloading")
    game.advance(1)
    _expect(game.day.watch_stock == 10 and game.day.watch_score == -1 and game.day.duty == 22, "wet cargo costs three and both on-time ships earn one; skipping clean cargo has no penalty")
    _expect(_label_containing(game, "卸貨時發現2袋濕米") and _label_exists(game, "盡忠職守  -1"), "wet-rice feedback and the new score are visible immediately")
    game.advance(60)
    _expect(game.day.flags.has("porcelain_unhappy_departure") and game.day.watch_score == -3 and game.day.duty == 22, "an unberthed ship costs two points and pays no tax")
    for stamp in ["major_fraud", "hold"]:
        game.restart()
        game.advance(120)
        var before: int = game.day.watch_score
        game.assign_berth("cloth", 0, true)
        game.manual_seen = true
        _press_text(game, "查閱完整貨單")
        _press_text(game, "返回驗貨桌")
        game.choose_method("manifest")
        game.choose_stamp(stamp)
        game.apply_stamp()
        _expect(game.day.watch_score == before - 4 and game.day.flags.has("cloth_unhappy_departure") and game.day.berths.is_empty() and game.day.duty == 0, "a wrongful %s costs stamp and departure points and forfeits an honest ship's tax" % stamp)
    for stamp in ["major_fraud", "hold"]:
        game.restart()
        game.assign_berth("rice", 0, false)
        game.assign_berth("pepper", 1, false)
        game.advance(70)
        game.assign_berth("tin", 0, true)
        var before: int = game.day.watch_score
        var duty_before: int = game.day.duty
        game.manual_seen = true
        game.show_evidence(2)
        game.choose_method("testimony")
        game.choose_stamp(stamp)
        game.apply_stamp()
        _expect(game.day.watch_score == before - 4 and game.day.flags.has("tin_unhappy_departure") and game.day.berths.is_empty(), "the tin ship's honest declaration error does not justify %s" % stamp)
        _press_text(game, "返回港口")
        game.advance(45)
        _expect(game.day.duty == duty_before, "the wrongfully sanctioned tin ship never unloads and pays no tax")
    game.queue_free()
    await process_frame


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
            for index in 3:
                game.show_evidence(index)
                game._evidence_turn(1)
                game._evidence_turn(-1)
            _expect(game.opened_crates.is_empty() and not game.viewed.has("contents"), "%s starts with all packages closed" % example[0])
            if case_id == "case_003":
                _press_accessible(game, "開封其餘的籃子")
                _expect(not _text_shown(game, "秤量裸錠") and not _text_shown(game, "仍是8小巴哈"), "the other baskets do not reveal the shipment's net weight while the muddy basket is closed")
                _press_text(game, "查看完整證據")
                _expect(game.detail_open and not game.detail_text.contains("仍是8小巴哈"), "the full reading also withholds the combined weight")
                _press_text(game, "返回驗貨桌")
                _press_accessible(game, "開封沾泥的籃子")
                _expect(_text_shown(game, "仍是8小巴哈"), "opening the last basket reveals the shipment's original net weight")
            for index in game.CRATE_NAMES[case_id].size():
                game.open_crate(index)
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
            _press_text(game, "查閱完整貨單")
            _press_text(game, "返回驗貨桌")
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


func _citation_locks() -> void:
    var game = DayOne.instantiate()
    root.add_child(game)
    game.assign_berth("rice", 0, true)
    for caption in game.METHODS:
        _expect(_disabled_button(game, caption), "%s starts locked on the rice desk" % caption)
        _press_text(game, caption)
        _expect(game.method.is_empty(), "%s cannot be cited before examination" % caption)
    _expect(not _text_shown(game, "均為乾米"), "the unopened manifest is not visible in the findings")
    game.open_manual()
    _press_text(game, "合上手冊")
    for stamp in ["major_fraud", "hold", "minor_fault"]:
        game.choose_stamp(stamp)
        game.apply_stamp()
        _expect(game.day.pending_case.get("id") == "rice" and not game.feedback_open, "%s cannot be filed without a citation" % stamp)
    game.choose_stamp("clear")
    _press_text(game, "蓋印：放行")
    _expect(game.day.flags.has("day_1_rice_clear") and game.opened_crates.is_empty() and game.method.is_empty(), "rice can be cleared on the declaration without opening or citing anything")
    _press_text(game, "返回港口")
    game.advance(60)
    _expect(game.day.watch_stock == 10, "blind clearance still carries the wet-rice risk")
    game.restart()
    game.assign_berth("rice", 0, true)
    game.open_crate(0)
    game.choose_method("contents")
    game.open_crate(1)
    _expect(game.cited_sack == 0 and _text_shown(game, "已引用：一號袋") and _disabled_button(game, "貨單"), "an opened sack can be cited without unlocking an unopened source or moving the existing citation")
    game.day.rule_with_method("major_fraud", "contents", 3)
    _expect(game.day.pending_case.get("id") == "rice", "the model rejects a citation to a still-closed sack")
    game.manual_seen = true
    game.choose_stamp("major_fraud")
    game.apply_stamp()
    _expect(game.day.watch_score == 0 and game.day.flags.has("day_1_rice_clear"), "a fine citing a dry sack cannot borrow proof from an opened wet sack")
    game.restart()
    game.assign_berth("porcelain", 0, true)
    _press_text(game, "聽取船長陳述")
    _press_text(game, "返回驗貨桌")
    _expect(_disabled_button(game, "證詞") and _disabled_button(game, "貨單"), "the introductory statement does not substitute for either source")
    _press_text(game, "查驗封印與過磅")
    var seal_plate_visible := false
    for picture: TextureRect in game.find_children("*", "TextureRect", true, false):
        if picture.texture != null and picture.texture.resource_path == "res://assets/inspection/lot-seven-exterior.png" and picture.is_visible_in_tree():
            seal_plate_visible = true
    _expect(seal_plate_visible and not _disabled_button(game, "重量") and not _disabled_button(game, "封印"), "the porcelain exterior plate immediately uncovers its weights and seal marks")
    _press_text(game, "封印")
    _expect(game.method == "marks" and not game.detail_open, "visible porcelain seals can be cited without opening the full reading")
    _press_text(game, "查看完整證據")
    _press_text(game, "返回驗貨桌")
    _expect(not _disabled_button(game, "封印") and _disabled_button(game, "證詞") and _disabled_button(game, "貨單"), "the full exterior reading preserves seal access without unlocking other sources")
    _press_text(game, "詢問船員")
    _press_text(game, "查閱完整貨單")
    _press_text(game, "返回驗貨桌")
    _expect(not _disabled_button(game, "證詞") and not _disabled_button(game, "貨單") and _disabled_button(game, "貨物"), "testimony and manifest unlock independently of cargo")
    game.queue_free()
    await process_frame


func _disabled_button(node: Node, caption: String) -> bool:
    for button: Button in node.find_children("*", "Button", true, false):
        if button.text == caption:
            return button.disabled
    _expect(false, "button %s exists" % caption)
    return false


func _harbour_status_routing() -> void:
    var game = DayOne.instantiate()
    root.add_child(game)
    game.assign_berth("rice", 0, false)
    await process_frame
    var status: Control = game.surface.get_node("Berth0/UnloadingStatus")
    var other: Control = game.surface.get_node("Berth1")
    _expect(not status.get_global_rect().intersects(other.get_global_rect()), "berth 1's unloading status never covers berth 2's drop target")
    await _drag(_anchor_point(game, 1), status.get_global_rect().get_center())
    _expect(game.day.ship_at_berth(1).is_empty() and game.day.waiting.size() == 2, "dropping on berth 1's status cannot silently berth a ship at berth 2")
    game.queue_free()
    await process_frame


func _berthed_hull_routing() -> void:
    var game = DayOne.instantiate()
    root.add_child(game)
    game.request_berth("porcelain", 1)
    await process_frame
    var target: Control = game.surface.get_node("Berth1")
    var hull: Control = target.find_children("*", "TextureRect", false, false)[0]
    var other: Control = game.surface.get_node("Berth0")
    _expect(not hull.get_global_rect().intersects(other.get_global_rect()), "a docked hull never draws inside the other berth's drop target")
    await _drag(_anchor_point(game, 0), hull.get_global_rect().position + Vector2(115, 20))
    _expect(game.day.ship_at_berth(0).is_empty() and game.day.ship_at_berth(1).get("id") == "porcelain" and game.day.waiting.size() == 2, "dropping onto an occupied hull cannot dock the incoming ship at the other berth")
    game.queue_free()
    await process_frame


func _anchor_point(game: Control, slot: int) -> Vector2:
    return game.surface.position + game.ANCHOR_POS[slot] + Vector2(115, 75)


func _berth_point(game: Control, slot: int) -> Vector2:
    return game.surface.position + game.BERTH_POS[slot] + Vector2(140, 83)


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


func _closing_help_focus() -> void:
    var game = DayOne.instantiate()
    root.add_child(game)
    game.advance(int(game.day.scenario["end_minute"]) - game.day.minute_of_day)
    _press_accessible(game, "盡忠職守說明")
    var close: Button
    var replay: Button
    for button: Button in game.find_children("*", "Button", true, false):
        if button.text == "關閉說明":
            close = button
        elif button.text == "重玩第一日":
            replay = button
    _expect(close != null and replay != null, "closing-screen duty help and replay controls exist")
    if close != null and replay != null:
        _expect(replay.disabled and replay.focus_mode == Control.FOCUS_NONE and root.gui_get_focus_owner() == close, "duty help starts with keyboard focus and disables the controls behind it")
        await _gui_key(KEY_TAB, true)
        _expect(root.gui_get_focus_owner() == close, "Shift+Tab cannot focus the replay button behind duty help")
        await _gui_key(KEY_ENTER)
        _expect(game.day.closed() and not game.detail_open, "Enter closes duty help without replaying the completed watch")
        _press_text(game, "重玩第一日")
        _expect(not game.day.closed(), "replay is available again after closing duty help")
    game.queue_free()
    await process_frame


func _gui_key(key: Key, shift := false) -> void:
    var event := InputEventKey.new()
    event.keycode = key
    event.shift_pressed = shift
    event.pressed = true
    root.push_input(event)
    await process_frame
    event.pressed = false
    root.push_input(event)
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


func _sack_paint(node: Node, caption: String) -> Texture2D:
    var button := _accessible_button(node, caption)
    return button.get_child(0).get("paint") if button != null else null


func _press_accessible(node: Node, caption: String) -> void:
    var button := _accessible_button(node, caption)
    _expect(button != null, "button %s exists" % caption)
    if button != null:
        button.pressed.emit()


func _expired_rice_reminder() -> void:
    var game = DayOne.instantiate()
    root.add_child(game)
    _expect(_label_containing(game, "請趕在10:15離港潮前卸下全數24袋米"), "the rice reminder is present before the opening tide")
    game.advance(75)
    _expect(game.day.minute_of_day == 615 and game.day.rice == 0, "the missed-rice path reaches its 10:15 departure tide")
    _expect(not _label_containing(game, "請趕在10:15離港潮前卸下全數24袋米") and _label_containing(game, "米船已離港"), "the expired reminder changes to the departed status")
    _press_text(game, "港口同僚")
    _expect(game.notes_open and game.notes_id == "day_01_turn_of_the_monsoon", "the colleague still opens the full briefing after the tide")
    game.queue_free()
    await process_frame


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
        if (button as Button).text == caption or _label_containing(button, caption):
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

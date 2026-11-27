extends Control

const PortDay = preload("res://scripts/port_day.gd")
const INK := Color("#e9e3d2")
const MUTED := Color("#acc1bd")
const GOLD := Color("#f2c884")
const SEA := Color("#17323a")
const SLATE := Color("#203a42")
const LINE := Color("#3b575a")
const PAPER_INK := Color("#2a1e17")
const PAPER_RED := Color("#7a2f22")
const VIEW_SIZE := Vector2(1280, 720)
const VIEW_TOP := 230.0
const VIEW_HEIGHT := 410.0
const SHIP_SIZE := Vector2(204, 153)
const BERTH_SLOTS := [Vector2(105, 252), Vector2(455, 254)]
const ANCHOR_SLOTS := [Vector2(815, 295), Vector2(150, 445), Vector2(535, 458)]

var day := PortDay.new()
var content: VBoxContainer
var scroll: ScrollContainer
var screen := ""
var selected_deputy := ""
var evidence_index := 0
var ruling_index := -1
var reason_index := -1
var recorded_measurements: Dictionary = {}
var screen_art: TextureRect
var screen_tint: ColorRect
var missing_art := {}


func _ready() -> void:
    var backdrop := ColorRect.new()
    backdrop.color = Color("#101f27")
    backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(backdrop)
    screen_art = TextureRect.new()
    screen_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    screen_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
    screen_art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(screen_art)
    screen_tint = ColorRect.new()
    screen_tint.color = Color(0.06, 0.1, 0.12, 0.55)
    screen_tint.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(screen_tint)
    scroll = ScrollContainer.new()
    scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(scroll)
    var margin := MarginContainer.new()
    margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _pad(margin, 28, 18)
    scroll.add_child(margin)
    content = VBoxContainer.new()
    content.add_theme_constant_override("separation", 12)
    margin.add_child(content)
    var ui_theme := Theme.new()
    ui_theme.default_font_size = 16
    ui_theme.set_color("font_color", "Label", INK)
    for button_class in ["Button", "OptionButton"]:
        ui_theme.set_color("font_color", button_class, INK)
        ui_theme.set_color("font_disabled_color", button_class, MUTED.darkened(0.25))
        ui_theme.set_stylebox("normal", button_class, _box(SLATE, LINE, 7, 4))
        ui_theme.set_stylebox("hover", button_class, _box(Color("#31545b"), GOLD, 7, 4))
        ui_theme.set_stylebox("pressed", button_class, _box(Color("#355b61"), GOLD, 7, 4))
        ui_theme.set_stylebox("disabled", button_class, _box(SEA, LINE, 7, 4))
    theme = ui_theme
    if day.load_data():
        _restart()
    else:
        _label(content, "The port day could not load. See the Godot output for the missing data.", 19)


func _restart() -> void:
    day.reset()
    _render()


func _render() -> void:
    for child in content.get_children():
        content.remove_child(child)
        child.queue_free()
    var inspecting := not day.pending_case.is_empty()
    screen_art.texture = _texture(_case_art("desk")) if inspecting else null
    screen_tint.visible = screen_art.texture != null
    var header := HBoxContainer.new()
    content.add_child(header)
    var heading := _panel(header, _scenario_art("banner"))
    heading.get_parent().size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _label(heading, "PORT MASTER  /  MELAKA 1511", 14, GOLD)
    var story := day.current_story()
    var heading_text := "The harbour watch"
    if inspecting:
        heading_text = "Detailed Inspection"
    elif not story.is_empty():
        if not day.active_offer.is_empty():
            heading_text = "State purchasing"
        else:
            heading_text = "Evening at the port" if day.closed() else "Morning briefing"
    elif day.closed():
        heading_text = "End of Day"
    if heading_text != screen:
        screen = heading_text
        scroll.scroll_vertical = 0
        scroll.scroll_horizontal = 0
    _label(heading, heading_text, 30)
    var watch := _panel(header)
    _label(watch, "%s  /  DAY %02d" % [PortDay.clock(day.minute_of_day), day.day_number], 19, GOLD)
    if inspecting:
        _render_inspection()
    elif not story.is_empty():
        _render_story(story)
    elif day.closed():
        _render_settlement()
    else:
        _render_harbour()


func _render_harbour() -> void:
    if not day.ruling_note.is_empty():
        var result := _panel(content)
        _label(result, "LATEST INSPECTION RESULT", 13, GOLD)
        _label(result, day.ruling_note, 16, INK, true)
    _render_view()
    if day.story_queue.is_empty():
        var paper := _texture(_scenario_art("panel")) != null
        var brief := _panel(content, _scenario_art("panel"))
        _label(brief, "MORNING BRIEF  /  QUAY OFFICE", 13, PAPER_RED if paper else GOLD)
        _label(brief, day.scenario["briefing"], 16, PAPER_INK if paper else INK, true)
    var controls := HBoxContainer.new()
    controls.add_theme_constant_override("separation", 8)
    content.add_child(controls)
    var stats := _label(controls, _score_line(), 16, GOLD)
    stats.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _button(controls, "+15 min", _advance.bind(15))
    _button(controls, "+60 min", _advance.bind(60))
    if day.all_ships_resolved():
        _button(controls, "Close watch", _advance.bind(int(day.scenario["end_minute"]) - day.minute_of_day))

    var board := HBoxContainer.new()
    board.add_theme_constant_override("separation", 12)
    content.add_child(board)
    var moored := _panel(board)
    moored.get_parent().custom_minimum_size.x = 248
    _label(moored, "BERTHS   %d / %d" % [day.berths.size(), PortDay.BERTH_CAPACITY], 15, GOLD)
    for slot in PortDay.BERTH_CAPACITY:
        var ship := day.ship_at_berth(slot)
        if ship.is_empty():
            _label(moored, "Berth %d · Available" % (slot + 1), 16, MUTED)
            continue
        var berthed := HBoxContainer.new()
        berthed.add_theme_constant_override("separation", 8)
        moored.add_child(berthed)
        _art(berthed, ship.get("cargo_image", ""), Vector2(40, 40))
        var berth_text := VBoxContainer.new()
        berth_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        berthed.add_child(berth_text)
        _label(berth_text, ship["name"], 17, INK, true)
        _label(berth_text, "Held at berth until closing" if ship.get("held_at_berth", false) else "%d min unloading · %s tide" % [
            ship["remaining"], PortDay.clock(int(ship["departure"]))
        ], 14, MUTED, true)
    var next_arrival := ""
    if day.next_ship < day.scenario["ships"].size():
        var ship: Dictionary = day.scenario["ships"][day.next_ship]
        next_arrival = "NEXT INBOUND  %s\n%s" % [PortDay.clock(int(ship["arrival"])), ship["name"]]
    if not next_arrival.is_empty():
        _label(moored, next_arrival, 14, GOLD, true)

    var anchorage := _panel(board)
    anchorage.get_parent().size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _label(anchorage, "ANCHORAGE   %d / %d" % [day.waiting.size(), PortDay.ANCHORAGE_CAPACITY], 15, GOLD)
    for slot in PortDay.ANCHORAGE_CAPACITY:
        var ship := day.ship_at_anchor(slot)
        var row := HBoxContainer.new()
        row.custom_minimum_size.y = 76
        row.add_theme_constant_override("separation", 8)
        anchorage.add_child(row)
        if ship.is_empty():
            _label(row, "Anchorage %d · Available" % (slot + 1), 16, MUTED)
            continue
        _art(row, _ship_art(ship), Vector2(88, 66))
        _art(row, ship.get("cargo_image", ""), Vector2(44, 66))
        var details := VBoxContainer.new()
        details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        row.add_child(details)
        _label(details, ship["name"], 17)
        _label(details, "%s  ·  %d duty  ·  %d min  ·  %s tide" % [
            ship["cargo"], ship["duty"], ship["minutes"], PortDay.clock(int(ship["departure"]))
        ], 14, MUTED, true)
        var actions := VBoxContainer.new()
        actions.custom_minimum_size.x = 146
        row.add_child(actions)
        var inspection := day.inspection_for(ship)
        var assign := _button(actions, "Berth & clear" if not inspection.is_empty() else "Assign berth",
            _berth.bind(ship["id"], false))
        _set_disabled_reason(assign, _label(actions, "", 13, GOLD, true), _berth_block(ship, false))
        if not inspection.is_empty():
            var inspect := _button(actions, "Inspect  +%d min" % inspection["minutes"],
                _berth.bind(ship["id"], true))
            _set_disabled_reason(inspect, _label(actions, "", 13, GOLD, true), _berth_block(ship, true),
                "Takes a berth and advances the clock before unloading. Other ships keep working.")
            if not selected_deputy.is_empty():
                var delegate := _button(actions, "Delegate inspection", func() -> void:
                    day.delegate_inspection(selected_deputy, ship["id"])
                    _render()
                )
                delegate.disabled = day.berths.size() >= PortDay.BERTH_CAPACITY or not day.can_finish(
                    ship, true, day.inspection_delay(selected_deputy))
    _render_deputies(true)
    _render_offers()
    _render_log()


func _render_deputies(at_quay: bool) -> void:
    var staff := _panel(content)
    _label(staff, "DEPUTY ASSIGNMENT", 15, GOLD)
    var picker := OptionButton.new()
    picker.add_item("Choose a deputy")
    picker.selected = 0
    var ids := day.deputies.keys()
    for index in ids.size():
        picker.add_item(day.deputies[ids[index]]["name"])
        if ids[index] == selected_deputy:
            picker.select(index + 1)
    picker.item_selected.connect(func(index: int) -> void:
        selected_deputy = ids[index - 1] if index > 0 else ""
        _render()
    )
    staff.add_child(picker)
    if not selected_deputy.is_empty():
        var deputy: Dictionary = day.deputies[selected_deputy]
        _render_cast(staff, deputy)
        var skills: Dictionary = deputy["skills"]
        var duties := HBoxContainer.new()
        duties.add_theme_constant_override("separation", 16)
        staff.add_child(duties)
        for task in ["berth", "inspection", "purchasing"]:
            var duty_row := HBoxContainer.new()
            duties.add_child(duty_row)
            _art(duty_row, _optional_texture_path("res://assets/art/icons/%s.png" % task), Vector2(32, 32))
            _label(duty_row, "%s %d" % [task.capitalize(), skills[task]], 15, GOLD)
        _label(staff, deputy["flaw"]["text"], 15, MUTED, true)
        if at_quay:
            var assign := _button(staff, "Delegate berth assignment", func() -> void:
                day.delegate_berth(selected_deputy)
                _render()
            )
            assign.disabled = day.berths.size() >= PortDay.BERTH_CAPACITY or not day.waiting.any(
                func(ship: Dictionary) -> bool: return day.can_finish(ship, false))


func _render_offers() -> void:
    var offers := day.available_offers()
    if not offers.is_empty():
        var merchants := _panel(content)
        _label(merchants, "MERCHANT OFFERS", 15, GOLD)
        for offer in offers:
            _button(merchants, offer["title"], func() -> void:
                day.open_offer(offer["id"])
                _render()
            )


func _render_cast(parent: Node, person: Dictionary) -> void:
    var cast := HBoxContainer.new()
    cast.add_theme_constant_override("separation", 12)
    parent.add_child(cast)
    var frame := _panel(cast)
    var path := "res://assets/art/portraits/%s.png" % person["id"]
    _art(frame, _optional_texture_path(path), Vector2(96, 96), person["name"])
    var details := VBoxContainer.new()
    details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    cast.add_child(details)
    _label(details, person["name"], 18, GOLD, true)
    _label(details, person.get("role", person.get("origin", "")), 15, MUTED, true)
    _label(details, person["bio"], 15, INK, true)


func _berth_block(ship: Dictionary, inspect: bool) -> String:
    if day.berths.size() >= PortDay.BERTH_CAPACITY:
        return "Both berths are occupied."
    if not day.can_finish(ship, inspect):
        var deadline := "closing" if day.scenario["end_minute"] < ship["departure"] else "departure"
        var action := "inspect and unload" if inspect else "unload"
        return "Not enough time to %s before %s." % [action, deadline]
    return ""


func _render_inspection() -> void:
    var inspection := day.inspection_for(day.pending_case)
    var dossier_row := _panel(content)
    var dossier_head := HBoxContainer.new()
    dossier_head.add_theme_constant_override("separation", 12)
    dossier_row.add_child(dossier_head)
    _art(dossier_head, _ship_art(day.pending_case), Vector2(160, 120))
    var dossier := VBoxContainer.new()
    dossier.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    dossier_head.add_child(dossier)
    _label(dossier, inspection["subtitle"], 14, GOLD, true)
    _label(dossier, inspection["title"], 24)
    var inspection_minutes := int(inspection["minutes"])
    _label(dossier, "%d min elapsed. Other berth work and scheduled arrivals continued; unloading starts after your ruling." % inspection_minutes,
        15, MUTED, true)
    var evidence: Array = inspection["evidence"]
    var tabs := HBoxContainer.new()
    tabs.add_theme_constant_override("separation", 8)
    dossier_row.add_child(tabs)
    for i in evidence.size():
        _evidence_tab(tabs, evidence[i]["label"], i)
    _evidence_tab(tabs, "%02d  Reference manual" % (evidence.size() + 1), evidence.size())

    var pages := HBoxContainer.new()
    pages.add_theme_constant_override("separation", 12)
    content.add_child(pages)
    var reading := _panel(pages)
    reading.get_parent().size_flags_horizontal = Control.SIZE_EXPAND_FILL
    if evidence_index == evidence.size():
        _label(reading, day.manual["title"], 20, GOLD, true)
        for entry in day.manual["entries"]:
            _label(reading, entry["title"], 16, GOLD, true)
            _label(reading, entry["text"], 16, INK, true)
    else:
        var clue: Dictionary = evidence[evidence_index]
        if clue["id"] in ["ev_exterior", "ev_tally", "ev_opened"]:
            var heading := "Opened:" if clue["id"] == "ev_opened" else "Weights:"
            recorded_measurements[clue["id"]] = _finding_excerpt(clue["text"], heading)
        var spread := HBoxContainer.new()
        spread.add_theme_constant_override("separation", 12)
        reading.add_child(spread)
        var page := VBoxContainer.new()
        page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        spread.add_child(page)
        _label(page, clue["title"], 20, GOLD)
        _label(page, clue["text"], 17, INK, true)
        var picture := _art(spread, clue.get("image", ""), Vector2(400, 200))
        if picture:
            picture.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
    if not recorded_measurements.is_empty():
        _render_findings(pages)

    var decision := _panel(content)
    _label(decision, "FILE A RULING  /  ONE FINAL DECISION", 14, GOLD)
    var submit := Button.new()
    var hint := Label.new()
    _choice(decision, "Choose a ruling", inspection["rulings"], ruling_index,
        func(index: int) -> void:
            ruling_index = index - 1
            _set_disabled_reason(submit, hint, _ruling_block())
    )
    _choice(decision, "Cite your evidence", PortDay.CITATION_METHODS, reason_index,
        func(index: int) -> void:
            reason_index = index - 1
            _set_disabled_reason(submit, hint, _ruling_block())
    )
    submit.text = "File ruling & return to the quay"
    submit.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
    decision.add_child(submit)
    submit.pressed.connect(_rule)
    hint.add_theme_font_size_override("font_size", 13)
    hint.add_theme_color_override("font_color", GOLD)
    hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    decision.add_child(hint)
    _set_disabled_reason(submit, hint, _ruling_block())


func _finding_excerpt(text: String, heading: String) -> String:
    var readings := PackedStringArray()
    for paragraph in text.split("\n\n", false):
        if paragraph.begins_with(heading):
            readings.append(paragraph)
    return text if readings.is_empty() else "\n\n".join(readings)


func _render_findings(parent: Node) -> void:
    var notes := _panel(parent)
    var panel := notes.get_parent() as Control
    panel.custom_minimum_size.x = 330
    panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
    _label(notes, "RECORDED MEASUREMENTS", 14, GOLD)
    var scroll := ScrollContainer.new()
    scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    scroll.custom_minimum_size.y = 280
    notes.add_child(scroll)
    var measurements := _label(scroll, "\n\n".join(recorded_measurements.values()), 14, INK, true)
    measurements.size_flags_horizontal = Control.SIZE_EXPAND_FILL


func _ruling_block() -> String:
    if ruling_index < 0 and reason_index < 0:
        return "Choose a ruling and cite evidence before filing."
    if ruling_index < 0:
        return "Choose a ruling before filing."
    if reason_index < 0:
        return "Cite evidence before filing."
    return ""


func _set_disabled_reason(button: Button, hint: Label, reason: String, enabled_tooltip := "") -> void:
    button.disabled = not reason.is_empty()
    button.tooltip_text = reason if button.disabled else enabled_tooltip
    hint.text = reason
    hint.visible = button.disabled


func _render_view() -> void:
    var holder := Control.new()
    holder.clip_contents = true
    holder.custom_minimum_size.y = VIEW_HEIGHT * maxf(content.size.x, 640.0) / VIEW_SIZE.x
    content.add_child(holder)
    var stage := Control.new()
    stage.size = VIEW_SIZE
    holder.add_child(stage)
    holder.resized.connect(_fit_view.bind(holder, stage))
    var backdrop := _art(stage, _scenario_art("backdrop"), VIEW_SIZE)
    if backdrop:
        (backdrop as TextureRect).stretch_mode = TextureRect.STRETCH_SCALE
    else:
        var water := ColorRect.new()
        water.color = SLATE
        water.size = VIEW_SIZE
        stage.add_child(water)
    for i in PortDay.BERTH_CAPACITY:
        var ship := day.ship_at_berth(i)
        var status := "AVAILABLE" if ship.is_empty() else ("HELD" if ship.get("held_at_berth", false) else "UNLOADING")
        _plate(stage, BERTH_SLOTS[i] + Vector2(19, -20), "BERTH %d  •  %s" % [i + 1, status])
        if not ship.is_empty():
            _view_ship(stage, ship, BERTH_SLOTS[i])
    for slot in PortDay.ANCHORAGE_CAPACITY:
        var ship := day.ship_at_anchor(slot)
        if not ship.is_empty():
            _view_ship(stage, ship, ANCHOR_SLOTS[slot])


func _fit_view(holder: Control, stage: Control) -> void:
    var view_scale := holder.size.x / VIEW_SIZE.x
    stage.scale = Vector2(view_scale, view_scale)
    stage.position = Vector2(0, -VIEW_TOP * view_scale)
    holder.custom_minimum_size.y = VIEW_HEIGHT * view_scale


func _view_ship(stage: Control, ship: Dictionary, pos: Vector2) -> void:
    var sprite := _art(stage, _ship_art(ship), SHIP_SIZE, ship["cargo"])
    if sprite:
        sprite.position = pos + Vector2(12, 0)
    var badge := _art(stage, ship.get("cargo_image", ""), Vector2(52, 52))
    if badge:
        badge.position = pos + Vector2(178, 96)
    var tag := PanelContainer.new()
    tag.add_theme_stylebox_override("panel", _box(Color(0.96, 0.93, 0.85, 0.92), PAPER_INK, 8, 2))
    tag.position = pos + Vector2(24, 146)
    stage.add_child(tag)
    _label(tag, ship["name"], 13, PAPER_INK)


func _plate(stage: Control, pos: Vector2, caption: String) -> void:
    var plate := _panel(stage, _scenario_art("berth_marker"))
    var frame: Control = plate.get_parent()
    frame.position = pos
    frame.custom_minimum_size = Vector2(168, 40)
    var paper := _texture(_scenario_art("berth_marker")) != null
    _label(plate, caption, 12, PAPER_INK if paper else INK).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER


func _render_settlement() -> void:
    var report := _panel(content)
    _label(report, "CLOSING LEDGER", 15, GOLD)
    _label(report, _score_line(), 22)
    _label(report, "Supply %d   ·   Reputation %d" % [day.supply, day.reputation], 18)
    _label(report, "Recovered inspection duty: %d" % day.recovered_duty, 18)
    if day.held > 0:
        _label(report, "Supported holds: %d" % day.held, 18)
    if not day.waiting.is_empty():
        _label(report, "Ships still at anchor: %d" % day.waiting.size(), 18)
    var shortfall := day.rice_shortfall()
    if int(day.scenario["rice_target"]) > 0:
        _label(report, "Rice target met." if shortfall == 0 else "Market shortage: %d rice sacks." % shortfall, 17)
    if day.rice_relief_cost > 0:
        _label(report, "Emergency rice relief: -%d duty" % day.rice_relief_cost, 17, GOLD)
    if not day.ruling_note.is_empty():
        _label(report, day.ruling_note, 16, MUTED, true)
    if not day.story_queue.is_empty() and day.story_index == -1:
        _button(report, "Continue to evening", func() -> void:
            day.start_evening()
            _render()
        ).size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
    else:
        if day.has_next_day():
            _button(report, "Begin day %d" % (day.day_number + 1), func() -> void:
                day.begin_next_day()
                _render()
            ).size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
        else:
            _label(report, "End of the Stage B schedule", 18, GOLD)
        _button(report, "Replay the day", _restart).size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
    _render_log(true)


func _render_story(story: Dictionary) -> void:
    var panel := _panel(content)
    var phase := "EVENING EVENT" if day.closed() else "QUAY OFFICE"
    var is_offer := not day.active_offer.is_empty()
    if is_offer:
        _label(panel, "STATE PURCHASE OFFER", 15, GOLD)
    else:
        if story.has("chain_id"):
            phase = "DEPARTURE & TAX ACCOUNT"
        _label(panel, "%s  /  %d OF %d" % [phase, day.story_index + 1, day.story_queue.size()], 15, GOLD)
    _label(panel, story["title"], 24, INK, true)
    var merchant_id: String = story.get("merchant_id", "")
    if day.merchants.has(merchant_id):
        _render_cast(panel, day.merchants[merchant_id])
    _label(panel, story["body"], 17, INK, true)
    if not day.story_outcome.is_empty():
        _label(panel, day.story_outcome["label"], 18, GOLD, true)
        _label(panel, day.story_outcome["outcome_text"], 17, INK, true)
        var effects: Dictionary = day.story_outcome["effects"]
        _label(panel, "Duty %+d   ·   Supply %+d   ·   Reputation %+d" % [
            int(effects.get("duty", 0)), int(effects.get("supply", 0)), int(effects.get("reputation", 0))
        ], 16, GOLD, true)
        if effects.has("merchant_trust"):
            _label(panel, "Merchant trust %+d" % int(effects["merchant_trust"]), 16, GOLD, true)
    var choices: Array = story.get("choices", [])
    if choices.is_empty() or not day.story_outcome.is_empty():
        _button(panel, "Continue", func() -> void:
            day.continue_story()
            _render()
        ).size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
    else:
        for choice in choices:
            _button(panel, choice["label"], _choose_story.bind(choice["id"])).size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
        if is_offer:
            if not selected_deputy.is_empty():
                _button(panel, "Delegate purchase", func() -> void:
                    day.delegate_purchase(selected_deputy)
                    _render()
                ).size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
            _button(panel, "Return without deciding", func() -> void:
                day.active_offer = {}
                _render()
            ).size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
    if not day.closed() and not is_offer:
        _render_deputies(false)


func _choose_story(choice_id: String) -> void:
    day.choose_story(choice_id)
    _render()


func _render_log(full := false) -> void:
    var log := _panel(content)
    _label(log, "QUAY LOG  /  LATEST FIRST", 13, GOLD)
    for i in (day.log_lines.size() if full else mini(5, day.log_lines.size())):
        _label(log, day.log_lines[i], 14, MUTED, true)


func _score_line() -> String:
    return "Duty %d   ·   Rice %d / %d sacks   ·   Traded %d   ·   Lost %d" % [
        day.duty, day.rice, day.scenario["rice_target"], day.completed, day.lost
    ]


func _berth(ship_id: String, inspect: bool) -> void:
    day.berth(ship_id, inspect)
    if not day.pending_case.is_empty():
        evidence_index = 0
        ruling_index = -1
        reason_index = -1
        recorded_measurements.clear()
    _render()


func _advance(minutes: int) -> void:
    day.advance(minutes)
    _render()


func _rule() -> void:
    if day.pending_case.is_empty() or not _ruling_block().is_empty():
        return
    var inspection := day.inspection_for(day.pending_case)
    day.rule_with_method(inspection["rulings"][ruling_index]["id"], PortDay.CITATION_METHODS[reason_index]["id"])
    _render()


func _evidence_tab(parent: Node, caption: String, index: int) -> void:
    var button := _button(parent, caption, func() -> void:
        evidence_index = index
        _render()
    )
    button.toggle_mode = true
    button.button_pressed = evidence_index == index


func _choice(parent: Node, prompt: String, options: Array, selected: int, callback: Callable) -> void:
    var picker := OptionButton.new()
    picker.add_item(prompt)
    picker.set_item_disabled(0, true)
    for option in options:
        picker.add_item(option["label"])
    picker.selected = selected + 1
    picker.item_selected.connect(callback)
    parent.add_child(picker)


func _button(parent: Node, caption: String, callback: Callable) -> Button:
    var button := Button.new()
    button.text = caption
    button.pressed.connect(callback)
    parent.add_child(button)
    return button


func _label(parent: Node, caption: String, size: int, color := INK, wrap := false) -> Label:
    var label := Label.new()
    label.text = caption
    label.add_theme_font_size_override("font_size", size)
    label.add_theme_color_override("font_color", color)
    if wrap:
        label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    parent.add_child(label)
    return label


func _scenario_art(key: String) -> String:
    return str(day.scenario.get("art", {}).get(key, ""))


func _case_art(key: String) -> String:
    return str(day.inspection_for(day.pending_case).get("art", {}).get(key, ""))


func _ship_art(ship: Dictionary) -> String:
    var path := _optional_texture_path("res://assets/art/ships/%s.png" % ship["id"])
    return ship.get("image", "") if path.is_empty() else path


func _optional_texture_path(path: String) -> String:
    return path if ResourceLoader.exists(path, "Texture2D") else ""


func _texture(path: String) -> Texture2D:
    if path.is_empty():
        return null
    if not ResourceLoader.exists(path, "Texture2D"):
        if not missing_art.has(path):
            missing_art[path] = true
            push_warning("Missing port art, using text: " + path)
        return null
    return load(path) as Texture2D


## Adds the texture at `path` fitted into `size`, or `fallback` text in its place. Returns null when neither is shown.
func _art(parent: Node, path: String, size: Vector2, fallback := "") -> Control:
    var texture := _texture(path)
    if texture:
        var picture := TextureRect.new()
        picture.texture = texture
        picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        picture.custom_minimum_size = size
        picture.size = size
        parent.add_child(picture)
        return picture
    if fallback.is_empty():
        return null
    var label := _label(parent, fallback, 16, MUTED, true)
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    label.custom_minimum_size = size
    label.size = size
    return label


func _panel(parent: Node, art := "") -> VBoxContainer:
    var panel := PanelContainer.new()
    var texture := _texture(art)
    if texture:
        var style := StyleBoxTexture.new()
        style.texture = texture
        var edge := mini(24, texture.get_height() / 4)
        style.texture_margin_left = edge
        style.texture_margin_right = edge
        style.texture_margin_top = edge
        style.texture_margin_bottom = edge
        style.content_margin_left = 28
        style.content_margin_right = 28
        style.content_margin_top = 16
        style.content_margin_bottom = 16
        panel.add_theme_stylebox_override("panel", style)
    else:
        panel.add_theme_stylebox_override("panel", _box(SEA, LINE, 14, 9))
    parent.add_child(panel)
    var column := VBoxContainer.new()
    column.add_theme_constant_override("separation", 4)
    panel.add_child(column)
    return column


func _pad(margin: MarginContainer, x: int, y: int) -> void:
    margin.add_theme_constant_override("margin_left", x)
    margin.add_theme_constant_override("margin_right", x)
    margin.add_theme_constant_override("margin_top", y)
    margin.add_theme_constant_override("margin_bottom", y)


func _box(fill: Color, border: Color, x: int, y: int) -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = fill
    style.border_color = border
    style.set_border_width_all(1)
    style.set_corner_radius_all(6)
    style.content_margin_left = x
    style.content_margin_right = x
    style.content_margin_top = y
    style.content_margin_bottom = y
    return style

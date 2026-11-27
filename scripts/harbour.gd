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
var evidence_index := 0
var ruling_index := -1
var reason_index := -1
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
    var scroll := ScrollContainer.new()
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
    var event := day.current_event()
    var heading_text := "The harbour watch"
    if inspecting:
        heading_text = "Detailed Inspection"
    elif not event.is_empty():
        heading_text = "Evening at the port"
    _label(heading, heading_text, 30)
    var watch := _panel(header)
    _label(watch, "%s  /  DAY %02d" % [PortDay.clock(day.minute_of_day), day.day_number], 19, GOLD)
    if inspecting:
        _render_inspection()
    elif not event.is_empty():
        _render_evening(event)
    elif day.closed():
        _render_settlement()
    else:
        _render_harbour()


func _render_harbour() -> void:
    _render_view()
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
    for ship in day.berths:
        var berthed := HBoxContainer.new()
        berthed.add_theme_constant_override("separation", 8)
        moored.add_child(berthed)
        _art(berthed, ship.get("cargo_image", ""), Vector2(40, 40))
        var berth_text := VBoxContainer.new()
        berth_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        berthed.add_child(berth_text)
        _label(berth_text, ship["name"], 17, INK, true)
        _label(berth_text, "%d min unloading · %s tide" % [
            ship["remaining"], PortDay.clock(int(ship["departure"]))
        ], 14, MUTED, true)
    for slot in PortDay.BERTH_CAPACITY - day.berths.size():
        _label(moored, "Berth %d · Available" % (day.berths.size() + slot + 1), 16, MUTED)
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
        _art(row, ship.get("image", ""), Vector2(88, 66))
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
        var berth_open := day.berths.size() < PortDay.BERTH_CAPACITY
        var inspection := day.inspection_for(ship)
        _button(actions, "Berth & clear" if not inspection.is_empty() else "Assign berth",
            _berth.bind(ship["id"], false)).disabled = not berth_open or not day.can_finish(ship, false)
        if not inspection.is_empty():
            var inspect := _button(actions, "Inspect  +%d min" % inspection["minutes"],
                _berth.bind(ship["id"], true))
            inspect.disabled = not berth_open or not day.can_finish(ship, true)
            inspect.tooltip_text = "Takes a berth and advances the clock before unloading. Other ships keep working."
    _render_log()


func _render_inspection() -> void:
    var inspection := day.inspection_for(day.pending_case)
    var dossier_row := _panel(content)
    var dossier_head := HBoxContainer.new()
    dossier_head.add_theme_constant_override("separation", 12)
    dossier_row.add_child(dossier_head)
    _art(dossier_head, day.pending_case.get("image", ""), Vector2(160, 120))
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

    var reading := _panel(content)
    if evidence_index == evidence.size():
        _label(reading, day.manual["title"], 20, GOLD, true)
        for entry in day.manual["entries"]:
            _label(reading, entry["title"], 16, GOLD, true)
            _label(reading, entry["text"], 16, INK, true)
    else:
        var clue: Dictionary = evidence[evidence_index]
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

    var decision := _panel(content)
    _label(decision, "FILE A RULING  /  ONE FINAL DECISION", 14, GOLD)
    var submit := Button.new()
    _choice(decision, "Choose a ruling", inspection["rulings"], ruling_index,
        func(index: int) -> void:
            ruling_index = index - 1
            submit.disabled = ruling_index < 0 or reason_index < 0
    )
    _choice(decision, "Cite your evidence", inspection["reasons"], reason_index,
        func(index: int) -> void:
            reason_index = index - 1
            submit.disabled = ruling_index < 0 or reason_index < 0
    )
    submit.text = "File ruling & return to the quay"
    submit.disabled = ruling_index < 0 or reason_index < 0
    submit.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
    decision.add_child(submit)
    submit.pressed.connect(_rule)


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
        var status := "UNLOADING" if i < day.berths.size() else "AVAILABLE"
        _plate(stage, BERTH_SLOTS[i] + Vector2(19, -20), "BERTH %d  •  %s" % [i + 1, status])
        if i < day.berths.size():
            _view_ship(stage, day.berths[i], BERTH_SLOTS[i])
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
    var sprite := _art(stage, ship.get("image", ""), SHIP_SIZE, ship["cargo"])
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
    var shortfall := maxi(0, int(day.scenario["rice_target"]) - day.rice)
    _label(report, "Rice target met." if shortfall == 0 else "Market shortage: %d rice sacks." % shortfall, 17)
    if not day.ruling_note.is_empty():
        _label(report, day.ruling_note, 16, MUTED, true)
    if not day.evening_queue.is_empty() and day.evening_index == -1:
        _button(report, "Continue to evening", func() -> void:
            day.start_evening()
            _render()
        ).size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
    else:
        _button(report, "Begin day %d" % (day.day_number + 1), func() -> void:
            day.begin_next_day()
            _render()
        ).size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
        _button(report, "Replay the day", _restart).size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
    _render_log(true)


func _render_evening(event: Dictionary) -> void:
    var panel := _panel(content)
    _label(panel, "EVENING EVENT  /  %d OF %d" % [day.evening_index + 1, day.evening_queue.size()], 15, GOLD)
    _label(panel, event["title"], 24, INK, true)
    _label(panel, event["body"], 17, INK, true)
    if not day.evening_outcome.is_empty():
        _label(panel, day.evening_outcome["label"], 18, GOLD, true)
        _label(panel, day.evening_outcome["outcome_text"], 17, INK, true)
        var effects: Dictionary = day.evening_outcome["effects"]
        _label(panel, "Duty %+d   ·   Supply %+d   ·   Reputation %+d" % [
            int(effects.get("duty", 0)), int(effects.get("supply", 0)), int(effects.get("reputation", 0))
        ], 16, GOLD, true)
    var choices: Array = event.get("choices", [])
    if choices.is_empty() or not day.evening_outcome.is_empty():
        _button(panel, "Continue", func() -> void:
            day.continue_evening()
            _render()
        ).size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
    else:
        for choice in choices:
            _button(panel, choice["label"], _choose_evening.bind(choice["id"])).size_flags_horizontal = Control.SIZE_SHRINK_BEGIN


func _choose_evening(choice_id: String) -> void:
    day.choose_evening(choice_id)
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
    _render()


func _advance(minutes: int) -> void:
    day.advance(minutes)
    _render()


func _rule() -> void:
    var inspection := day.inspection_for(day.pending_case)
    day.rule(inspection["rulings"][ruling_index]["id"], inspection["reasons"][reason_index]["id"])
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


func _texture(path: String) -> Texture2D:
    if path.is_empty():
        return null
    if not ResourceLoader.exists(path, "Texture2D"):
        if not missing_art.has(path):
            missing_art[path] = true
            push_warning("Missing Stage A art, using text: " + path)
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

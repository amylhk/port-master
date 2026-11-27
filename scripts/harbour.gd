extends Control

const PortDay = preload("res://scripts/port_day.gd")
const INK := Color("#e9e3d2")
const MUTED := Color("#acc1bd")
const GOLD := Color("#f2c884")
const SEA := Color("#17323a")
const SLATE := Color("#203a42")
const LINE := Color("#3b575a")

var day := PortDay.new()
var content: VBoxContainer
var evidence_index := 0
var ruling_index := -1
var reason_index := -1


func _ready() -> void:
    var backdrop := ColorRect.new()
    backdrop.color = Color("#101f27")
    backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(backdrop)
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
    var header := HBoxContainer.new()
    content.add_child(header)
    var heading := VBoxContainer.new()
    heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    header.add_child(heading)
    _label(heading, "PORT MASTER  /  MELAKA 1511", 14, GOLD)
    var inspecting := not day.pending_case.is_empty()
    _label(heading, "Detailed Inspection" if inspecting else "The harbour watch", 30)
    var watch := _panel(header)
    _label(watch, "%s  /  DAY 01" % PortDay.clock(day.minute_of_day), 19, GOLD)
    if inspecting:
        _render_inspection()
    elif day.closed():
        _render_settlement()
    else:
        _render_harbour()


func _render_harbour() -> void:
    var brief := _panel(content)
    _label(brief, "MORNING BRIEF  /  QUAY OFFICE", 13, GOLD)
    _label(brief, day.scenario["briefing"], 16, INK, true)
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
        _label(moored, ship["name"], 17, INK, true)
        _label(moored, "%d min unloading · %s tide" % [
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
    var dossier := _panel(content)
    _label(dossier, inspection["subtitle"], 14, GOLD, true)
    _label(dossier, inspection["title"], 24)
    var inspection_minutes := int(inspection["minutes"])
    _label(dossier, "%d min elapsed. Other berth work and scheduled arrivals continued; unloading starts after your ruling." % inspection_minutes,
        15, MUTED, true)
    var evidence: Array = inspection["evidence"]
    var tabs := HBoxContainer.new()
    tabs.add_theme_constant_override("separation", 8)
    dossier.add_child(tabs)
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
        if clue.has("image") and ResourceLoader.exists(clue["image"], "Texture2D"):
            var picture := TextureRect.new()
            picture.texture = load(clue["image"]) as Texture2D
            picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
            picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
            picture.custom_minimum_size = Vector2(240, 120)
            spread.add_child(picture)

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


func _render_settlement() -> void:
    var report := _panel(content)
    _label(report, "CLOSING LEDGER", 15, GOLD)
    _label(report, _score_line(), 22)
    _label(report, "Recovered inspection duty: %d" % day.recovered_duty, 18)
    if day.held > 0:
        _label(report, "Supported holds: %d" % day.held, 18)
    var shortfall := maxi(0, int(day.scenario["rice_target"]) - day.rice)
    _label(report, "Rice target met." if shortfall == 0 else "Market shortage: %d rice sacks." % shortfall, 17)
    if not day.ruling_note.is_empty():
        _label(report, day.ruling_note, 16, MUTED, true)
    _button(report, "Replay the day", _restart).size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
    _render_log(true)


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


func _panel(parent: Node) -> VBoxContainer:
    var panel := PanelContainer.new()
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

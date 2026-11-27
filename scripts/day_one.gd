extends Control
## The Day 1 play surface. The older campaign prototype remains in harbour.tscn.

const PortDay = preload("res://scripts/port_day.gd")
const MANUAL_TITLE := "驗貨手冊"
const ROMANIZED_TITLE := "Gangwuzhang: Maliujia 1511 - Di Yi Ri"
const INK := Color("#f4ead0")
const MUTED := Color("#b9cfca")
const GOLD := Color("#f1c774")
const DARK := Color("#284c51")
const PAPER := Color("#f0e5ce")
const BROWN := Color("#38291e")
const GREEN := Color("#65be98")
const RED := Color("#dd8773")
const FULL_BERTHS_HINT := "兩個泊位均已佔用，請推進至下次港鐘。"
const BERTH_POS := [Vector2(64, 265), Vector2(426, 265)]
const ANCHOR_POS := [Vector2(120, 490), Vector2(510, 490), Vector2(900, 490)]
const METHODS := ["封印", "重量", "證詞", "貨物", "貨單"]
const METHOD_TITLES := {"marks": "比對商號標記與封印", "measurements": "比對數量與重量", "testimony": "核對證詞與紀錄", "contents": "檢查開封貨物", "manifest": "查閱貨單"}
const STAMPS := {"clear": "放行", "minor_fault": "更正", "major_fraud": "罰款", "hold": "扣留"}

class ShipToken extends Button:
    var ship: Dictionary
    var picture: TextureRect

    func _get_drag_data(_at_position: Vector2) -> Variant:
        var preview := TextureRect.new()
        preview.texture = picture.texture
        preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        preview.custom_minimum_size = Vector2(160, 120)
        preview.modulate.a = 0.85
        set_drag_preview(preview)
        return {"kind": "ship", "id": ship["id"]}

    func _process(_delta: float) -> void:
        if is_instance_valid(picture):
            picture.position.y = 3.0 + sin(Time.get_ticks_msec() / 650.0 + float(ship["arrival"])) * 2.0

class BerthTarget extends Panel:
    var slot: int
    var validate: Callable
    var request: Callable
    var drag_state := -2

    func _process(_delta: float) -> void:
        var data: Variant = get_viewport().gui_get_drag_data()
        var dragging: bool = get_viewport().gui_is_dragging() and data is Dictionary and data.get("kind") == "ship"
        var next_state := -1
        if dragging:
            next_state = 1 if validate.call(data.get("id", ""), slot).is_empty() else 0
        if next_state == drag_state:
            return
        drag_state = next_state
        var style := get_theme_stylebox("panel").duplicate() as StyleBoxFlat
        if dragging:
            var available := drag_state == 1
            style.border_color = Color("#65be98") if available else Color("#dd8773")
            style.bg_color = Color(0.08, 0.29, 0.28, 0.94) if available else Color(0.25, 0.12, 0.11, 0.94)
        else:
            style.border_color = Color("#f1c774")
            style.bg_color = Color(0.04, 0.14, 0.17, 0.88)
        add_theme_stylebox_override("panel", style)

    func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
        # Receive ship releases even when docking is blocked so the request can show why.
        return data is Dictionary and data.get("kind") == "ship" and data.get("id") is String

    func _drop_data(_at_position: Vector2, data: Variant) -> void:
        request.call(data["id"], slot)

var day := PortDay.new()
var surface: Control
var selected_ship := ""
var proposed_ship := ""
var proposed_slot := -1
var evidence_index := 0
var evidence_page := 0
var viewed := {}
var method := ""
var stamp := ""
var manual_seen := false
var manual_open := false
var manual_page := 0
var notes_open := false
var feedback_open := false
var notice := ""
var hints := {}
var inspections_filed := 0
var short_copy := {}
var detail_open := false
var detail_title := ""
var detail_text := ""
var notes_id := "port_day"
var last_feedback := ""


func _ready() -> void:
    var window_title: String = ProjectSettings.get_setting("application/config/name")
    if OS.has_feature("linux"):
        var font_paths := OS.get_system_font_path_for_text("sans-serif", window_title, "zh-tw")
        window_title = _title_with_system_fonts(window_title, font_paths)
    get_window().title = window_title
    get_window().content_scale_size = Vector2i(1280, 720)
    get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
    get_window().content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
    var game_theme := Theme.new()
    # Noto TC is variable: select a readable weight rather than its thin default.
    var game_font := FontVariation.new()
    game_font.base_font = load("res://assets/fonts/NotoSansTC.ttf")
    game_font.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"): 500.0}
    game_theme.default_font = game_font
    game_theme.default_font_size = 17
    game_theme.set_color("font_color", "Label", INK)
    for state in ["normal", "hover", "pressed", "focus", "disabled"]:
        var color := GOLD if state in ["hover", "focus", "pressed"] else Color("#547a79")
        game_theme.set_stylebox(state, "Button", _style(DARK.lightened(0.12) if state == "hover" else DARK, color, 2))
    game_theme.set_color("font_color", "Button", INK)
    game_theme.set_color("font_disabled_color", "Button", Color("#83908b"))
    theme = game_theme
    if FileAccess.file_exists("res://data/hints/day_1.json"):
        var data: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/hints/day_1.json"))
        if data is Array:
            for entry in data:
                if entry is Dictionary:
                    hints[str(entry.get("id", ""))] = str(entry.get("text", ""))
    if FileAccess.file_exists("res://data/short/day_1.json"):
        var data: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/short/day_1.json"))
        if data is Dictionary:
            short_copy = data
    if day.load_data():
        restart()
    else:
        _text(self, "港口資料載入失敗，請查看主控台的錯誤訊息。", Rect2(40, 40, 1100, 80), 24)


static func _title_with_system_fonts(title: String, paths: PackedStringArray) -> String:
    for path in paths:
        var font := FontFile.new()
        if font.load_dynamic_font(path) != OK:
            continue
        var covers_title := true
        for character in title:
            if not font.has_char(character.unicode_at(0)):
                covers_title = false
                break
        if covers_title:
            return title
    return ROMANIZED_TITLE


func restart() -> void:
    day.day_number = 1
    day.reset()
    # Briefings are available as optional port notes, never a wall before play.
    day.story_queue.clear()
    day.story_index = 0
    selected_ship = ""
    proposed_ship = ""
    proposed_slot = -1
    notice = ""
    feedback_open = false
    manual_open = false
    notes_open = false
    inspections_filed = 0
    detail_open = false
    render()


func render() -> void:
    if is_instance_valid(surface):
        remove_child(surface)
        surface.queue_free()
    surface = Control.new()
    surface.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(surface)
    if day.closed():
        _closing()
    elif not day.pending_case.is_empty():
        _desk()
    else:
        _harbour()
    if manual_open:
        _manual()
    if notes_open:
        _notes()
    if feedback_open:
        _feedback()
    if detail_open:
        _detail()


func _harbour() -> void:
    _image(surface, day.scenario["art"]["backdrop"], Rect2(0, 0, 1280, 720))
    _header("港口值勤", "第一日   /   " + PortDay.clock(day.minute_of_day))
    _hint(_harbour_hint())
    for slot in PortDay.BERTH_CAPACITY:
        _berth_target(slot)
    _morning_voice()
    _panel(surface, Rect2(110, 447, 600, 36), PAPER)
    _text(surface, "外港錨地   /   %d 艘等候（上限三艘）" % day.waiting.size(), Rect2(120, 450, 580, 30), 16, BROWN)
    for slot in PortDay.ANCHORAGE_CAPACITY:
        var ship := day.ship_at_anchor(slot)
        if ship.is_empty():
            var empty := _panel(surface, Rect2(ANCHOR_POS[slot], Vector2(260, 160)), Color(0.04, 0.18, 0.21, 0.4))
            _text(empty, "~  空置錨位  ~", Rect2(10, 55, 240, 40), 15, MUTED, true)
        else:
            _ship_token(ship, ANCHOR_POS[slot])
    _panel(surface, Rect2(0, 662, 1280, 58), DARK)
    _text(surface, "稻米入港  %d / %d 袋" % [day.rice, day.scenario["rice_target"]], Rect2(25, 675, 255, 30), 17, GOLD)
    _button(surface, "港務記事", Rect2(285, 672, 140, 38), func() -> void:
        notes_id = "port_day"
        notes_open = true
        render()
    )
    _button(surface, "推進十五分鐘", Rect2(697, 672, 165, 38), advance.bind(15))
    _button(surface, "下次港鐘  %s  >" % PortDay.clock(_next_bell_minute()), Rect2(878, 672, 244, 38), next_bell)
    _button(surface, "結束值勤", Rect2(1134, 672, 124, 38), close_watch).disabled = not day.all_ships_resolved()
    _panel(surface, Rect2(32, 148, 705, 34), PAPER)
    _text(surface, "只有推進港鐘或進行驗貨時，時間才會流逝。", Rect2(43, 150, 680, 30), 15, BROWN)
    if not selected_ship.is_empty():
        _text(surface, "已選取船隻。按下空泊位，或把船拖過去。", Rect2(728, 157, 500, 48), 16, GOLD)
    if not proposed_ship.is_empty():
        _boarding()


func _morning_voice() -> void:
    var copy: Dictionary = short_copy.get("briefings", {}).get("day_01_turn_of_the_monsoon", {})
    if copy.is_empty():
        return
    var bubble := _button(surface, "", Rect2(831, 236, 407, 163), func() -> void:
        notes_id = "day_01_turn_of_the_monsoon"
        notes_open = true
        render()
    )
    _style_paper_button(bubble)
    var portrait: String = copy.get("speaker_id", "")
    if not portrait.is_empty():
        _image(bubble, "res://assets/art/portraits/%s.png" % portrait, Rect2(10, 17, 100, 119))
    _text(bubble, copy.get("line", ""), Rect2(123, 12, 270, 116), 20, BROWN)
    _text(bubble, "按下聽取詳情", Rect2(123, 125, 270, 28), 13, BROWN)


func _harbour_hint() -> String:
    if not notice.is_empty():
        return notice
    if day.all_ships_resolved():
        return "港口已漸平靜，可以結束首次值勤。"
    if day.berths.size() == PortDay.BERTH_CAPACITY:
        return FULL_BERTHS_HINT
    if day.waiting.size() == PortDay.ANCHORAGE_CAPACITY and day.minute_of_day > 540:
        return _hint_text("anchorage_full", "錨地已滿，請安排等候的船隻靠泊。")
    if day.minute_of_day == 540 and day.berths.is_empty():
        return _hint_text("first_ship", "將船隻拖至空泊位，讓稻米供應市集。")
    for ship in day.waiting:
        if int(ship["departure"]) - day.minute_of_day <= 75:
            return _hint_text("tide_warning", "留意潮汐！船隻將於限時離港。")
    return _hint_text("berth_free", "有泊位空出，請拖入下一艘船。")


func _berth_target(slot: int) -> void:
    var ship := day.ship_at_berth(slot)
    var target := BerthTarget.new()
    target.slot = slot
    target.validate = drop_block
    target.request = request_berth
    target.position = BERTH_POS[slot]
    target.size = Vector2(310, 172)
    target.add_theme_stylebox_override("panel", _style(Color(0.04, 0.14, 0.17, 0.88), GOLD if ship.is_empty() else Color("#547a79"), 2))
    target.gui_input.connect(func(event: InputEvent) -> void:
        if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and not selected_ship.is_empty():
            request_berth(selected_ship, slot)
    )
    surface.add_child(target)
    _text(target, "泊位 %d" % (slot + 1), Rect2(14, 8, 282, 28), 17, GOLD)
    if ship.is_empty():
        _text(target, "+", Rect2(112, 30, 86, 62), 43, GOLD, true)
        _text(target, "將船隻拖至此處", Rect2(12, 107, 286, 30), 18, INK, true)
        _text(target, "亦可先選船，再按此泊位", Rect2(10, 140, 290, 22), 13, MUTED, true)
    else:
        _image(target, _ship_art(ship), Rect2(6, 33, 135, 100))
        _text(target, ship["name"], Rect2(142, 43, 159, 54), 17)
        _text(target, "扣留至收港" if ship.get("held_at_berth", false) else "尚餘 %d 分鐘" % ship["remaining"], Rect2(144, 100, 156, 30), 17, GREEN)
        var progress := ProgressBar.new()
        progress.position = Vector2(15, 144)
        progress.size = Vector2(280, 12)
        progress.max_value = int(ship["minutes"])
        progress.value = int(ship["minutes"]) - int(ship["remaining"])
        progress.show_percentage = false
        progress.mouse_filter = Control.MOUSE_FILTER_IGNORE
        target.add_child(progress)


func _ship_token(ship: Dictionary, pos: Vector2) -> void:
    var token := ShipToken.new()
    token.ship = ship
    token.position = pos
    token.size = Vector2(260, 160)
    token.tooltip_text = "拖至泊位，或先選船再按泊位。"
    token.mouse_default_cursor_shape = Control.CURSOR_DRAG
    if selected_ship == ship["id"]:
        token.add_theme_stylebox_override("normal", _style(DARK, GOLD, 3))
    token.pressed.connect(func() -> void:
        selected_ship = ship["id"]
        notice = ""
        render()
    )
    surface.add_child(token)
    token.picture = _image(token, _ship_art(ship), Rect2(3, 3, 155, 101))
    _image(token, ship.get("cargo_image", ""), Rect2(187, 12, 54, 54))
    _text(token, ship["name"], Rect2(10, 98, 240, 27), 17)
    var urgent: bool = int(ship["departure"]) - day.minute_of_day <= 75
    _text(token, "%s 離港  ·  卸貨 %d 分鐘" % [PortDay.clock(ship["departure"]), ship["minutes"]], Rect2(10, 129, 245, 24), 14, GOLD if urgent else MUTED)


func drop_block(ship_id: String, slot: int) -> String:
    if day.closed() or not day.pending_case.is_empty() or not proposed_ship.is_empty() or feedback_open or notes_open or manual_open or detail_open:
        return "請先完成目前的工作。"
    if slot < 0 or slot >= PortDay.BERTH_CAPACITY:
        return "請選擇其中一個泊位。"
    if not day.ship_at_berth(slot).is_empty():
        if day.berths.size() == PortDay.BERTH_CAPACITY:
            return FULL_BERTHS_HINT
        return "此泊位已有船隻，請使用另一泊位。"
    var ship := _waiting_ship(ship_id)
    if ship.is_empty():
        return "該船已不在錨地等候。"
    if not day.can_finish(ship, false):
        return "時間不足，無法在離港潮汐前完成卸貨。"
    return ""


func request_berth(ship_id: String, slot: int) -> void:
    var block := drop_block(ship_id, slot)
    if not block.is_empty():
        notice = block
        render()
        return
    notice = ""
    var ship := _waiting_ship(ship_id)
    if day.inspection_for(ship).is_empty():
        assign_berth(ship_id, slot, false)
    else:
        proposed_ship = ship_id
        proposed_slot = slot
        render()


func _boarding() -> void:
    var ship := _waiting_ship(proposed_ship)
    var inspection := day.inspection_for(ship)
    var panel := _modal(Rect2(340, 195, 600, 360))
    _image(panel, _ship_art(ship), Rect2(28, 25, 180, 125))
    _text(panel, "泊位 %d  /  %s 離港" % [proposed_slot + 1, PortDay.clock(ship["departure"])], Rect2(225, 27, 345, 32), 17, GOLD)
    _text(panel, ship["name"], Rect2(225, 69, 345, 60), 27)
    _text(panel, "%s  ·  卸貨需時 %d 分鐘" % [ship["cargo"], ship["minutes"]], Rect2(28, 168, 545, 40), 20)
    var copy: Dictionary = short_copy.get("ships", {}).get(ship["id"], {})
    if not copy.is_empty():
        _text(panel, copy.get("line", ""), Rect2(225, 119, 345, 44), 16, MUTED)
    _button(panel, "按申報卸貨", Rect2(27, 221, 262, 58), assign_berth.bind(proposed_ship, proposed_slot, false))
    var inspect := _button(panel, "詳細驗貨  ＋%d 分鐘" % inspection["minutes"], Rect2(307, 221, 266, 58), assign_berth.bind(proposed_ship, proposed_slot, true))
    inspect.disabled = not day.can_finish(ship, true)
    _text(panel, "無法在離港潮汐前完成驗貨及卸貨。" if inspect.disabled else "驗貨會佔用此泊位，另一泊位將繼續卸貨。", Rect2(28, 291, 545, 28), 15, GOLD)
    _button(panel, "取消", Rect2(225, 323, 150, 29), func() -> void:
        proposed_ship = ""
        proposed_slot = -1
        render()
    )


func assign_berth(ship_id: String, slot: int, inspect: bool) -> void:
    # Revalidate at the model boundary; no selection or stale prompt can bypass it.
    proposed_ship = ""
    proposed_slot = -1
    var block := drop_block(ship_id, slot)
    var ship := _waiting_ship(ship_id)
    if not block.is_empty() or (inspect and not day.can_finish(ship, true)):
        notice = block if not block.is_empty() else "已來不及在潮汐前完成驗貨。"
        render()
        return
    day.berth(ship_id, inspect, slot)
    selected_ship = ""
    notice = ""
    if inspect:
        evidence_index = 0
        evidence_page = 0
        viewed = {"manifest": true}
        method = ""
        stamp = ""
        manual_seen = false
        manual_page = 0
    render()


func advance(minutes: int) -> void:
    if not proposed_ship.is_empty() or feedback_open or manual_open or notes_open or detail_open or not day.pending_case.is_empty():
        return
    var lost_before := day.lost
    var completed_before := day.completed
    day.advance(minutes)
    notice = ""
    if day.lost > lost_before:
        notice = "有船錯過潮汐而離去，請留意離港時間。"
    elif day.completed > completed_before:
        notice = "貨物已卸妥，可以安排下一艘船靠泊。"
    selected_ship = ""
    render()


func next_bell() -> void:
    advance(maxi(1, _next_bell_minute() - day.minute_of_day))


func _next_bell_minute() -> int:
    var next := int(day.scenario["end_minute"])
    for ship in day.berths:
        if not ship.get("held_at_berth", false):
            next = mini(next, day.minute_of_day + int(ship["remaining"]))
    for ship in day.waiting:
        next = mini(next, int(ship["departure"]))
    var ships: Array = day.scenario["ships"]
    if day.next_ship < ships.size():
        next = mini(next, int(ships[day.next_ship]["arrival"]))
    return next


func close_watch() -> void:
    if day.all_ships_resolved():
        advance(int(day.scenario["end_minute"]) - day.minute_of_day)


func _desk() -> void:
    var inspection := day.inspection_for(day.pending_case)
    _image(surface, inspection.get("art", {}).get("desk", ""), Rect2(0, 0, 1280, 720))
    _header("驗貨桌  /  " + day.pending_case["name"], PortDay.clock(day.minute_of_day) + "   /   時間暫停")
    var instruction := "打開貨物、核對手冊，再選擇證據及判決印章。"
    if not manual_seen:
        instruction = _hint_text("check_manual", "請對照手冊，核實驗貨發現。") if viewed.has("contents") else _hint_text("open_cargo", "打開貨物，看看包裝內藏有甚麼。")
    elif method.is_empty():
        instruction = "先選擇引用的證據，再選判決印章。"
    elif not stamp.is_empty():
        instruction = "按下申報單蓋印：" + STAMPS[stamp]
    else:
        instruction = _hint_text("stamp", "選擇印章，再按下申報單蓋印。")
    _hint(instruction)
    # Physical tools live on the left; the declaration and findings share the desk.
    _panel(surface, Rect2(16, 151, 284, 552), PAPER)
    _text(surface, "驗貨工具", Rect2(28, 155, 260, 30), 16, BROWN)
    var cargo := _button(surface, "", Rect2(28, 192, 260, 171), show_evidence.bind(3))
    _style_paper_button(cargo)
    cargo.tooltip_text = "打開貨物"
    var cargo_path: String = day.pending_case.get("cargo_image", "")
    if day.pending_case["id"] == "porcelain":
        cargo_path = "res://assets/art/cargo/porcelain_jar_open.png" if viewed.has("contents") else "res://assets/art/cargo/porcelain_jar_closed.png"
    _image(cargo, cargo_path, Rect2(58, 1, 145, 128))
    _text(cargo, "打開貨物" if not viewed.has("contents") else "貨物已開封", Rect2(8, 133, 244, 30), 19, BROWN, true)
    _button(surface, "查驗封印與過磅", Rect2(28, 377, 260, 49), show_evidence.bind(1))
    _button(surface, "詢問船員", Rect2(28, 438, 260, 49), show_evidence.bind(2))
    var manual := _button(surface, "", Rect2(28, 505, 260, 117), open_manual)
    manual.accessibility_name = MANUAL_TITLE
    _image(manual, "res://assets/inspection/manual_open.png", Rect2(5, 3, 250, 110))
    _text(manual, MANUAL_TITLE + "\n按下翻閱規則", Rect2(10, 27, 240, 70), 20, BROWN, true)
    _text(surface, "驗貨已耗時 %d 分鐘。\n另一泊位的卸貨未曾中斷。" % inspection["minutes"], Rect2(28, 630, 260, 66), 14, BROWN)
    _declaration(inspection)
    _findings(inspection)
    _stamp_rack(inspection)


func _declaration(inspection: Dictionary) -> void:
    var paper := _panel(surface, Rect2(318, 161, 399, 360), PAPER)
    var declared: Dictionary = inspection["evidence"][0]
    _text(paper, "申報貨單", Rect2(20, 14, 359, 28), 18, BROWN)
    _text(paper, declared["title"], Rect2(20, 47, 359, 56), 24, BROWN)
    var text := str(declared["text"])
    var paragraphs := text.split("\n\n", false)
    var copy: Dictionary = short_copy.get("cases", {}).get(inspection["id"], {})
    var portrait: String = copy.get("speaker_id", "")
    if not portrait.is_empty():
        _image(paper, "res://assets/art/portraits/%s.png" % portrait, Rect2(20, 107, 86, 103))
    var inset := 112 if not portrait.is_empty() else 20
    _text(paper, copy.get("line", paragraphs[mini(1, paragraphs.size() - 1)]), Rect2(inset, 111, 379 - inset, 110), 17, BROWN)
    _button(paper, "聽取船長陳述", Rect2(20, 226, 359, 32), show_detail.bind(inspection["title"], inspection["subtitle"]))
    _button(paper, "查閱完整貨單", Rect2(20, 266, 359, 35), show_detail.bind(declared["title"], declared["text"]))
    var press := _button(paper, "在此蓋印" if stamp.is_empty() else "蓋印：" + STAMPS[stamp], Rect2(20, 308, 359, 38), apply_stamp)
    press.disabled = stamp.is_empty() or method.is_empty() or not manual_seen
    press.tooltip_text = "請先翻閱手冊，選擇證據及判決印章。" if press.disabled else "記錄判決並返回港口。"


func _findings(inspection: Dictionary) -> void:
    var evidence: Dictionary = inspection["evidence"][evidence_index]
    var panel := _panel(surface, Rect2(740, 161, 512, 360), PAPER)
    _text(panel, evidence["title"], Rect2(18, 12, 476, 50), 22, BROWN)
    var paragraphs := str(evidence["text"]).split("\n\n", false)
    evidence_page = clampi(evidence_page, 0, paragraphs.size() - 1)
    var short_line: String = short_copy.get("cases", {}).get(inspection["id"], {}).get("evidence", {}).get(evidence["id"], "")
    var has_art: bool = evidence.has("image") and (evidence_page == 0 or not short_line.is_empty())
    if has_art:
        _image(panel, evidence["image"], Rect2(17, 65, 478, 135))
    _reading(panel, short_line if not short_line.is_empty() else paragraphs[evidence_page], Rect2(18, 205 if has_art else 74, 476, 96 if has_art else 227), BROWN, 18)
    if short_line.is_empty():
        _button(panel, "<", Rect2(18, 312, 55, 34), _evidence_turn.bind(-1)).disabled = evidence_page == 0
        _text(panel, "%d / %d" % [evidence_page + 1, paragraphs.size()], Rect2(90, 312, 320, 34), 16, BROWN, true)
        _button(panel, ">", Rect2(439, 312, 55, 34), _evidence_turn.bind(1)).disabled = evidence_page == paragraphs.size() - 1
    else:
        _button(panel, "查看完整證據", Rect2(18, 312, 476, 34), show_detail.bind(evidence["title"], evidence["text"]))


func show_evidence(index: int) -> void:
    if day.pending_case.is_empty() or manual_open or detail_open:
        return
    evidence_index = clampi(index, 0, day.inspection_for(day.pending_case)["evidence"].size() - 1)
    evidence_page = 0
    match evidence_index:
        0: viewed["manifest"] = true
        1:
            viewed["marks"] = true
            viewed["measurements"] = true
        2: viewed["testimony"] = true
        3: viewed["contents"] = true
    render()


func _evidence_turn(direction: int) -> void:
    evidence_page += direction
    render()


func show_detail(title: String, body: String) -> void:
    detail_title = title
    detail_text = body
    detail_open = true
    render()


func _detail() -> void:
    var panel := _modal(Rect2(230, 145, 820, 510), PAPER)
    _text(panel, detail_title, Rect2(26, 18, 768, 56), 26, BROWN)
    _reading(panel, detail_text, Rect2(26, 87, 768, 330), BROWN, 21)
    _button(panel, "返回驗貨桌", Rect2(255, 446, 310, 43), func() -> void:
        detail_open = false
        render()
    )


func _stamp_rack(inspection: Dictionary) -> void:
    _panel(surface, Rect2(318, 535, 934, 168), DARK)
    _text(surface, "引用已核實的證據", Rect2(334, 542, 400, 26), 14, GOLD)
    for index in PortDay.CITATION_METHODS.size():
        var id: String = PortDay.CITATION_METHODS[index]["id"]
        var button := _button(surface, METHODS[index], Rect2(334 + index * 181, 574, 170, 35), choose_method.bind(id))
        button.disabled = not viewed.has(id)
        button.tooltip_text = METHOD_TITLES[id] + ("" if viewed.has(id) else "：請先使用相應的驗貨工具")
        if method == id:
            button.add_theme_stylebox_override("normal", _style(Color("#346052"), GOLD, 2))
    for index in inspection["rulings"].size():
        var ruling: Dictionary = inspection["rulings"][index]
        var id: String = ruling["id"]
        var button := _button(surface, "", Rect2(334 + index * 226, 626, 214, 61), choose_stamp.bind(id))
        _style_paper_button(button)
        button.tooltip_text = STAMPS[id]
        if stamp == id:
            button.add_theme_stylebox_override("normal", _style(Color("#dfccac"), GOLD, 3))
        var path: String = {"clear": "stamp_clear", "major_fraud": "stamp_fine", "hold": "stamp_hold"}.get(id, "")
        var has_face := not path.is_empty() and ResourceLoader.exists("res://assets/inspection/%s.png" % path, "Texture2D")
        if has_face:
            _image(button, "res://assets/inspection/%s.png" % path, Rect2(4, 2, 102, 55))
        _text(button, STAMPS[id], Rect2(108, 4, 100, 52) if has_face else Rect2(6, 4, 202, 52), 24, BROWN, true)


func choose_method(id: String) -> void:
    if viewed.has(id) and not manual_open and not detail_open:
        method = id
        render()


func choose_stamp(id: String) -> void:
    if not manual_open and not detail_open and not day.pending_case.is_empty() and day.inspection_for(day.pending_case)["rulings"].any(func(r: Dictionary) -> bool: return r["id"] == id):
        stamp = id
        render()


func apply_stamp() -> void:
    if day.pending_case.is_empty() or stamp.is_empty() or method.is_empty() or not viewed.has(method) or not manual_seen or manual_open or detail_open:
        return
    var inspection := day.inspection_for(day.pending_case)
    var truth: Dictionary = inspection["hidden_truth"]
    var ruling_matches: bool = stamp == truth["ruling_id"]
    var evidence_matches: bool = method in day._citation_methods(truth)
    day.rule_with_method(stamp, method)
    # The model's legacy diagnostic scaffolding is English; the played desk is not.
    last_feedback = day.ruling_note if ruling_matches and evidence_matches else day.ruling_note.split("\n\n")[0]
    if not (ruling_matches and evidence_matches):
        var diagnosis := "判決與引用的證據均不正確。"
        if ruling_matches:
            diagnosis = "判決正確，但引用的證據不足以支持。"
        elif evidence_matches:
            diagnosis = "證據切合案情，但判決不正確。"
        var explanation: String = truth.get("feedback_by_method", {}).get(method, "")
        last_feedback += "\n\n" + diagnosis + "\n正確判決：應蓋「%s」" % STAMPS[truth["ruling_id"]]
        if not explanation.is_empty():
            last_feedback += "\n" + explanation
    inspections_filed += 1
    feedback_open = true
    render()


func open_manual() -> void:
    manual_seen = true
    manual_open = true
    # Start on packing weights; all original rules remain in the book.
    if manual_page == 0:
        manual_page = 8
    render()


func _manual() -> void:
    var book := _modal(Rect2(170, 145, 940, 510), PAPER)
    _text(book, MANUAL_TITLE, Rect2(28, 18, 790, 35), 25, BROWN)
    _button(book, "合上手冊", Rect2(759, 17, 155, 36), func() -> void:
        manual_open = false
        render()
    )
    var entries: Array = day.manual["entries"]
    manual_page = clampi(manual_page, 0, entries.size() - 1)
    _text(book, entries[manual_page]["title"], Rect2(30, 74, 880, 40), 25, BROWN)
    _reading(book, entries[manual_page]["text"], Rect2(30, 127, 880, 310), BROWN, 20)
    _button(book, "< 上一頁", Rect2(30, 457, 160, 36), _manual_turn.bind(-1)).disabled = manual_page == 0
    _text(book, "%d / %d" % [manual_page + 1, entries.size()], Rect2(329, 457, 280, 36), 17, BROWN, true)
    _button(book, "下一頁 >", Rect2(750, 457, 160, 36), _manual_turn.bind(1)).disabled = manual_page == entries.size() - 1


func _manual_turn(direction: int) -> void:
    manual_page = clampi(manual_page + direction, 0, day.manual["entries"].size() - 1)
    render()


func _notes() -> void:
    var panel := _modal(Rect2(240, 180, 800, 350), PAPER)
    _text(panel, "晨間港務記事", Rect2(26, 20, 748, 40), 27, BROWN)
    var body: String = day.scenario["briefing"]
    for briefing in day.briefings:
        if briefing["id"] == notes_id:
            body = briefing["body"]
            break
    _reading(panel, body, Rect2(26, 75, 748, 185), BROWN, 22)
    _button(panel, "返回港口", Rect2(245, 284, 310, 43), func() -> void:
        notes_open = false
        render()
    )


func _feedback() -> void:
    var panel := _modal(Rect2(270, 171, 740, 400), PAPER)
    _text(panel, "判決已記錄  /  " + STAMPS.get(stamp, ""), Rect2(27, 21, 686, 42), 26, BROWN)
    _reading(panel, last_feedback, Rect2(27, 86, 686, 220), BROWN, 21)
    _button(panel, "返回港口", Rect2(215, 332, 310, 45), func() -> void:
        feedback_open = false
        notice = "判決已記錄，請繼續安排港口船隻。"
        render()
    )


func _closing() -> void:
    _image(surface, day.scenario["art"]["backdrop"], Rect2(0, 0, 1280, 720))
    _header("首次值勤結束", "第一日  /  17:00")
    var panel := _panel(surface, Rect2(220, 173, 840, 408), DARK)
    _text(panel, _hint_text("day_end", "收港鐘聲響遍馬六甲。"), Rect2(30, 27, 780, 55), 28, GOLD, true)
    var captions := ["完成卸貨", "稻米入港", "流失交易", "有效扣留", "淨收支"]
    var values := [str(day.completed), "%d / %d" % [day.rice, day.scenario["rice_target"]], str(day.lost), str(day.held), str(day.duty)]
    for index in captions.size():
        _text(panel, values[index], Rect2(30 + index * 156, 112, 150, 68), 36, INK, true)
        _text(panel, captions[index], Rect2(30 + index * 156, 182, 150, 35), 16, GOLD, true)
    _text(panel, "含驗貨補徵 %d；已扣缺米救濟 %d。" % [day.recovered_duty, day.rice_relief_cost], Rect2(30, 220, 780, 27), 15, MUTED, true)
    _text(panel, "已記錄 %d 次驗貨判決。%s" % [inspections_filed, "市集已有足夠稻米。" if day.rice_shortfall() == 0 else "市集仍需更多稻米。"], Rect2(30, 246, 780, 47), 21, INK, true)
    _button(panel, "重玩第一日", Rect2(260, 323, 320, 55), restart)
    _panel(surface, Rect2(280, 609, 720, 44), PAPER)
    _text(surface, "目前僅開放第一日，其餘日程與官署事務暫停。", Rect2(290, 615, 700, 32), 17, BROWN, true)


func _waiting_ship(id: String) -> Dictionary:
    for ship in day.waiting:
        if ship["id"] == id:
            return ship
    return {}


func _ship_art(ship: Dictionary) -> String:
    var named := "res://assets/art/ships/%s.png" % ship["id"]
    return named if ResourceLoader.exists(named) else str(ship.get("image", ""))


func _hint_text(id: String, fallback: String) -> String:
    return str(hints.get(id, fallback))


func _header(title: String, clock: String) -> void:
    _panel(surface, Rect2(0, 0, 1280, 77), DARK)
    _text(surface, "港務長   /   馬六甲 一五一一年", Rect2(26, 8, 800, 22), 13, GOLD)
    _text(surface, title, Rect2(26, 32, 900, 38), 26)
    _text(surface, clock, Rect2(926, 27, 326, 36), 19, GOLD, true)


func _hint(caption: String) -> void:
    var panel := _panel(surface, Rect2(24, 90, 1232, 51), Color("#254a49"))
    _text(panel, caption, Rect2(17, 8, 1198, 35), 22, GOLD)


func _modal(rect: Rect2, fill := DARK) -> Panel:
    var shade := ColorRect.new()
    shade.color = Color(0.01, 0.04, 0.05, 0.77)
    shade.size = Vector2(1280, 720)
    surface.add_child(shade)
    return _panel(surface, rect, fill)


func _panel(parent: Node, rect: Rect2, fill: Color) -> Panel:
    var panel := Panel.new()
    panel.position = rect.position
    panel.size = rect.size
    panel.add_theme_stylebox_override("panel", _style(fill, Color("#6f8071"), 1))
    parent.add_child(panel)
    return panel


func _text(parent: Node, caption: String, rect: Rect2, font_size := 18, color := INK, centered := false) -> Label:
    var label := Label.new()
    label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER if centered else HORIZONTAL_ALIGNMENT_LEFT
    label.add_theme_font_size_override("font_size", font_size)
    label.add_theme_color_override("font_color", color)
    label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    # Set wrapping before text/size: otherwise Label retains its unwrapped minimum width.
    label.custom_minimum_size.x = rect.size.x
    label.text = caption
    label.position = rect.position
    label.size = rect.size
    parent.add_child(label)
    return label


func _reading(parent: Node, caption: String, rect: Rect2, color: Color, font_size: int) -> void:
    var scroll := ScrollContainer.new()
    scroll.position = rect.position
    scroll.size = rect.size
    scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    parent.add_child(scroll)
    var label := Label.new()
    label.text = caption
    label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    label.add_theme_font_size_override("font_size", font_size)
    label.add_theme_color_override("font_color", color)
    scroll.add_child(label)


func _button(parent: Node, caption: String, rect: Rect2, callback: Callable) -> Button:
    var button := Button.new()
    button.text = caption
    button.position = rect.position
    button.size = rect.size
    button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
    button.pressed.connect(callback)
    parent.add_child(button)
    return button


func _style_paper_button(button: Button) -> void:
    for state in ["normal", "hover", "pressed", "focus"]:
        button.add_theme_stylebox_override(state, _style(PAPER if state == "normal" else PAPER.darkened(0.08), Color("#6f8071") if state == "normal" else GOLD, 2))


func _image(parent: Node, path: String, rect: Rect2) -> TextureRect:
    var picture := TextureRect.new()
    if not path.is_empty() and ResourceLoader.exists(path, "Texture2D"):
        picture.texture = load(path)
    picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    picture.position = rect.position
    picture.size = rect.size
    picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
    parent.add_child(picture)
    return picture


func _style(fill: Color, border: Color, width: int) -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = fill
    style.border_color = border
    style.set_border_width_all(width)
    style.set_corner_radius_all(7)
    return style

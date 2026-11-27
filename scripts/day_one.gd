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
const BERTH_POS := [Vector2(460, 218), Vector2(520, 378)]
const BERTH_SIZE := Vector2(280, 160)
const ANCHOR_POS := [Vector2(925, 152), Vector2(925, 317), Vector2(925, 482)]
const SHIP_SIZE := Vector2(230, 160)
const METHODS := ["封印", "重量", "證詞", "貨物", "貨單"]
const METHOD_TITLES := {"marks": "比對商號標記與封印", "measurements": "比對數量與重量", "testimony": "核對證詞與紀錄", "contents": "檢查開封貨物", "manifest": "查閱貨單"}
const STAMPS := {"clear": "放行", "minor_fault": "更正", "major_fraud": "罰款", "hold": "扣留"}
const RICE_SACK_ART := {
    false: "res://assets/art/inspection/rice_sack_closed.png",
    true: "res://assets/art/inspection/rice_sack_open.png",
}
const DUTY_HELP := "盡忠職守是衡量港務長值勤表現的分數。\n\n加分：查獲不合格貨物或走私、正確蓋印，以及安排船隻準時卸貨。\n\n扣分：放行不合格貨物、錯判而冤枉誠實商人，或有船隻不滿離港。\n\n貨物符合申報時，略過驗貨不會扣分。"
const CRATE_NAMES := {
    "case_001": ["前排陶甕", "後排陶甕", "第7包生絲"],
    "case_002": ["甲包", "乙包"],
    "case_003": ["沾泥的籃子", "其餘的籃子"],
    "case_004": ["第11箱", "第3箱", "無編號箱"],
}

class CratePicture extends Control:
    var opened: bool

    func _draw() -> void:
        _face([Vector2(8, 31), Vector2(46, 41), Vector2(46, 63), Vector2(8, 52)], Color("#a9794c"))
        _face([Vector2(46, 41), Vector2(66, 28), Vector2(66, 50), Vector2(46, 63)], Color("#89603d"))
        if opened:
            _face([Vector2(8, 31), Vector2(28, 18), Vector2(66, 28), Vector2(46, 41)], Color("#4e3929"))
            _face([Vector2(28, 18), Vector2(26, 3), Vector2(64, 13), Vector2(66, 28)], Color("#d4aa73"))
        else:
            _face([Vector2(8, 31), Vector2(28, 18), Vector2(66, 28), Vector2(46, 41)], Color("#d4aa73"))
        draw_line(Vector2(8, 41), Vector2(46, 51), Color("#6d4b33"), 1.0, true)

    func _face(points: PackedVector2Array, fill: Color) -> void:
        draw_colored_polygon(points, fill)
        points.append(points[0])
        draw_polyline(points, BROWN, 1.5, true)

class SackPicture extends Control:
    var opened: bool
    var paint: Texture2D

    func _draw() -> void:
        if paint != null:
            draw_texture_rect(paint, Rect2(-9, -7, 60, 70), false)
            return
        var outline := PackedVector2Array([
            Vector2(11, 17), Vector2(6, 10), Vector2(36, 10), Vector2(31, 17),
            Vector2(40, 31), Vector2(37, 47), Vector2(5, 47), Vector2(2, 32), Vector2(11, 17),
        ])
        draw_colored_polygon(outline, Color("#b08859"))
        draw_polyline(outline, BROWN, 1.5, true)
        if opened:
            draw_set_transform(Vector2(21, 13), 0, Vector2(1.0, 0.45))
            draw_circle(Vector2.ZERO, 15, BROWN, true, -1, true)
            for grain in [Vector2(-8, 2), Vector2(-2, -6), Vector2(4, 4), Vector2(8, -3), Vector2(0, 9)]:
                draw_circle(grain, 2.5, PAPER, true, -1, true)
        else:
            draw_line(Vector2(10, 17), Vector2(32, 17), BROWN, 2, true)

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
            picture.position.y = -8.0 + sin(Time.get_ticks_msec() / 900.0 + float(ship["arrival"])) * 2.0

class BerthTarget extends Control:
    var slot: int
    var validate: Callable
    var request: Callable
    var drag_state := -2
    var occupied := false
    var hovered := false

    func _ready() -> void:
        mouse_entered.connect(func() -> void:
            hovered = true
            queue_redraw()
        )
        mouse_exited.connect(func() -> void:
            hovered = false
            queue_redraw()
        )

    func _draw() -> void:
        if occupied and drag_state < 0:
            return
        var tint := Color("#efd59a")
        if drag_state >= 0:
            tint = Color("#7ad6ac") if drag_state == 1 else Color("#e49a87")
        var center := Vector2(140, 83)
        var points := PackedVector2Array()
        for index in 65:
            var angle := TAU * index / 64.0
            points.append(center + Vector2(cos(angle) * 116, sin(angle) * 43))
        if hovered or drag_state >= 0:
            draw_colored_polygon(points, Color(tint, 0.16))
        for index in range(0, 64, 4):
            draw_polyline(points.slice(index, index + 3), Color(tint, 0.9 if drag_state >= 0 or hovered else 0.55), 2.0, true)
        if not occupied:
            draw_line(center - Vector2(10, 0), center + Vector2(10, 0), tint, 2.0, true)
            draw_line(center - Vector2(0, 10), center + Vector2(0, 10), tint, 2.0, true)

    func _process(_delta: float) -> void:
        var data: Variant = get_viewport().gui_get_drag_data()
        var dragging: bool = get_viewport().gui_is_dragging() and data is Dictionary and data.get("kind") == "ship"
        var next_state := -1
        if dragging:
            next_state = 1 if validate.call(data.get("id", ""), slot).is_empty() else 0
        if next_state == drag_state:
            return
        drag_state = next_state
        queue_redraw()

    func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
        # Receive ship releases even when docking is blocked so the request can show why.
        return data is Dictionary and data.get("kind") == "ship" and data.get("id") is String

    func _drop_data(_at_position: Vector2, data: Variant) -> void:
        request.call(data["id"], slot)

var day := PortDay.new()
var surface: Control
var selected_ship := ""
var evidence_index := -1
var evidence_page := 0
var opened_crates := {}
var selected_crate := 0
var cited_sack := -1
var viewed := {}
var method := ""
var stamp := ""
var manual_seen := false
var manual_open := false
var manual_page := 0
var manual_full := false
var manual_full_page := 0
var notes_open := false
var feedback_open := false
var notice := ""
var hints := {}
var inspections_filed := 0
var short_copy := {}
var detail_open := false
var detail_title := ""
var detail_text := ""
var detail_close_caption := ""
var notes_id := "port_day"
var last_feedback := ""
var rice_sack_paint := {}


func _ready() -> void:
    var window_title: String = ProjectSettings.get_setting("application/config/name")
    if OS.has_feature("linux"):
        var font_paths := OS.get_system_font_path_for_text("sans-serif", window_title, "zh-tw")
        window_title = _title_with_system_fonts(window_title, font_paths)
    get_window().title = window_title
    get_window().content_scale_size = Vector2i(1280, 720)
    get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
    # Extend the painted sea instead of adding black bars on taller/wider windows.
    get_window().content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
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
    resized.connect(func() -> void: render.call_deferred())
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
    for opened in RICE_SACK_ART:
        var path: String = RICE_SACK_ART[opened]
        if ResourceLoader.exists(path, "Texture2D"):
            rice_sack_paint[opened] = load(path)
    if day.load_data("res://data/port_day.json", PortDay.INSPECTION_DIR, true):
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
    notice = ""
    feedback_open = false
    manual_open = false
    manual_seen = false
    notes_open = false
    inspections_filed = 0
    detail_open = false
    render()


func render() -> void:
    if is_instance_valid(surface):
        remove_child(surface)
        surface.queue_free()
    surface = Control.new()
    # Keep desk tools at a readable, consistent scale; center the 16:9 play area
    # within the expanded canvas while the harbour paint fills the whole window.
    surface.position = (get_viewport_rect().size - Vector2(1280, 720)) * 0.5
    surface.size = Vector2(1280, 720)
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
    _harbour_backdrop()
    _header("港口值勤", "第一日   /   " + PortDay.clock(day.minute_of_day))
    _hint(_harbour_hint())
    for slot in PortDay.BERTH_CAPACITY:
        _berth_target(slot)
    _morning_voice()
    _text(surface, "外港錨地  ·  %d / 3 艘" % day.waiting.size(), Rect2(726, 151, 190, 32), 15, BROWN, true)
    for slot in PortDay.ANCHORAGE_CAPACITY:
        var ship := day.ship_at_anchor(slot)
        if ship.is_empty():
            var empty := _image(surface, "res://assets/art/harbour/anchorage_marker.png", Rect2(ANCHOR_POS[slot] + Vector2(65, 20), Vector2(100, 100)))
            empty.modulate.a = 0.5
        else:
            _ship_token(ship, ANCHOR_POS[slot])
    _panel(surface, Rect2(0, 662, 1280, 58), DARK)
    _button(surface, "港務記事", Rect2(24, 672, 140, 38), func() -> void:
        notes_id = "port_day"
        notes_open = true
        render()
    )
    _button(surface, "推進十五分鐘", Rect2(697, 672, 165, 38), advance.bind(15))
    _button(surface, "下次港鐘  %s  >" % PortDay.clock(_next_bell_minute()), Rect2(878, 672, 244, 38), next_bell)
    _button(surface, "結束值勤", Rect2(1134, 672, 124, 38), close_watch).disabled = not day.all_ships_resolved()
    _panel(surface, Rect2(24, 611, 510, 33), PAPER).mouse_filter = Control.MOUSE_FILTER_IGNORE
    _text(surface, "只有推進港鐘或進行驗貨時，時間才會流逝。", Rect2(35, 611, 488, 33), 14, BROWN)


func _harbour_backdrop() -> void:
    var viewport_size := get_viewport_rect().size
    var backdrop := _image(surface, day.scenario["art"]["backdrop"], Rect2(-surface.position, viewport_size))
    backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED


func _morning_voice() -> void:
    var copy: Dictionary = short_copy.get("briefings", {}).get("day_01_turn_of_the_monsoon", {})
    if copy.is_empty():
        return
    var line: String = copy.get("line", "")
    var caption := "港口同僚  ·  按下聽取詳情"
    var action := func() -> void:
        notes_id = "day_01_turn_of_the_monsoon"
        notes_open = true
        render()
    var awaiting := day.awaiting_inspection()
    if day.rice_shortfall() == 0:
        line = "大人，稻米已全數卸妥，請繼續安排船隻靠泊。"
    elif not day.waiting.any(func(ship: Dictionary) -> bool: return ship["id"] == "rice") and not day.berths.any(func(ship: Dictionary) -> bool: return ship["id"] == "rice"):
        line = "大人，米船已離港，請繼續安排其餘船隻靠泊。"
    if not awaiting.is_empty():
        var ship: Dictionary = awaiting[0]
        for candidate in awaiting:
            if day.can_inspect_berthed(candidate):
                ship = candidate
                break
        var slot := int(ship["berth_slot"])
        if day.can_inspect_berthed(ship):
            var cargo_action := "抽驗米袋" if day.is_rice_spot_check(ship) else "開箱檢查"
            line = "大人，%s已靠泊位%d。請按船旁的「驗貨」標記%s。" % [ship["name"], slot + 1, cargo_action]
            caption = "按此驗貨；推進時間即按申報卸貨"
            action = inspect_berth.bind(slot)
        else:
            line = "大人，%s已來不及在潮汐前驗貨，推進時間便按申報卸貨。" % ship["name"]
    if not day.watch_rice_report.is_empty():
        if awaiting.is_empty():
            line = day.watch_rice_report
        else:
            var report := _panel(surface, Rect2(24, 307, 248, 104), PAPER)
            _text(report, "同僚", Rect2(12, 2, 224, 23), 12, BROWN)
            _text(report, day.watch_rice_report, Rect2(12, 24, 224, 73), 15, BROWN)
    var bubble := _button(surface, "", Rect2(24, 156, 350, 142), action)
    _style_paper_button(bubble)
    var portrait: String = copy.get("speaker_id", "")
    if not portrait.is_empty():
        _image(bubble, "res://assets/art/portraits/%s.png" % portrait, Rect2(8, 17, 84, 106))
    _text(bubble, line, Rect2(103, 10, 232, 94), 18, BROWN)
    _text(bubble, caption, Rect2(103, 108, 232, 24), 12, BROWN)


func _harbour_hint() -> String:
    if not notice.is_empty():
        return notice
    if not selected_ship.is_empty():
        return "已選取船隻，請按下空泊位，或將船拖往碼頭。"
    if day.all_ships_resolved():
        return "港口已漸平靜，可以結束首次值勤。"
    for ship in day.awaiting_inspection():
        if day.can_inspect_berthed(ship):
            return _hint_text("inspect_berthed", "按船旁「驗貨」標記開箱。")
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
    target.size = BERTH_SIZE
    target.occupied = not ship.is_empty()
    target.name = "Berth%d" % slot
    target.mouse_filter = Control.MOUSE_FILTER_STOP
    target.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
    target.accessibility_name = "泊位 %d" % (slot + 1)
    target.gui_input.connect(func(event: InputEvent) -> void:
        if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and not selected_ship.is_empty():
            request_berth(selected_ship, slot)
    )
    surface.add_child(target)
    var plaque := _panel(target, Rect2(5, 125, 270, 35), Color(0.12, 0.27, 0.28, 0.94))
    plaque.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _text(plaque, "泊位 %d" % (slot + 1), Rect2(9, 0, 78, 35), 16, GOLD)
    if ship.is_empty():
        _text(plaque, "將船拖往此處", Rect2(88, 0, 173, 35), 16, INK, true)
    else:
        # Hull and wake stay above the plaque and inside their own drop row.
        _image(target, _ship_art(ship), Rect2(25, 0, 230, 120))
        _text(plaque, ship["name"], Rect2(88, 0, 173, 35), 16, INK, true)
        if ship.get("inspection_open", false):
            _berth_inspection_marker(target, ship, slot)
            return
        # Keep berth 1's status outside berth 2's water target. A panel below
        # the pier would visually belong to berth 1 but route drops to berth 2.
        var status := _panel(target, Rect2(-175, 130, 170, 27), Color(0.12, 0.27, 0.28, 0.9))
        status.name = "UnloadingStatus"
        status.mouse_filter = Control.MOUSE_FILTER_IGNORE
        _text(status, "扣留至收港" if ship.get("held_at_berth", false) else "卸貨中 · 尚餘 %d 分鐘" % ship["remaining"], Rect2(5, 0, 160, 27), 13, INK, true)


## Crates on the quay, with the 驗貨 callout in clear water beside the hull.
func _berth_inspection_marker(target: Control, ship: Dictionary, slot: int) -> void:
    var area := target.size
    var crates_rect := Rect2(area.x * 0.04, area.y * 0.48, area.x * 0.24, area.y * 0.27)
    if ResourceLoader.exists("res://assets/art/harbour/berth_crates.png", "Texture2D"):
        _image(target, "res://assets/art/harbour/berth_crates.png", crates_rect)
    else:
        for index in 3:
            var offset: Vector2 = [Vector2(0, 0.45), Vector2(0.5, 0.45), Vector2(0.25, 0)][index]
            var crate := _panel(target, Rect2(crates_rect.position + offset * crates_rect.size, crates_rect.size * Vector2(0.5, 0.55)), Color("#9b6b3f"))
            crate.add_theme_stylebox_override("panel", _style(Color("#9b6b3f"), Color("#4d331f"), 2))
            crate.mouse_filter = Control.MOUSE_FILTER_IGNORE
        _image(target, ship.get("cargo_image", ""), Rect2(crates_rect.position + crates_rect.size * Vector2(0.25, 0), crates_rect.size * Vector2(0.5, 0.55)))
    var can_inspect := day.can_inspect_berthed(ship)
    var marker := _button(surface, "", Rect2(target.position + Vector2(area.x - 15, 20), Vector2(128, 96)), inspect_berth.bind(slot))
    marker.accessibility_name = "驗貨"
    marker.set_drag_forwarding(Callable(), target._can_drop_data, target._drop_data)
    marker.disabled = not can_inspect
    var inspection := day.inspection_for(ship)
    var rice_spot_check := day.is_rice_spot_check(ship)
    var duration := int(inspection.get("minutes_per_sack", inspection["minutes"]))
    marker.tooltip_text = "抽驗米袋，每袋耗時 %d 分鐘。" % duration if rice_spot_check else "開箱詳細驗貨，佔用此泊位 %d 分鐘。" % duration
    if not can_inspect:
        marker.tooltip_text = "已來不及在潮汐前完成驗貨。"
    for state in ["normal", "hover", "pressed", "focus"]:
        marker.add_theme_stylebox_override(state, _style(PAPER if state == "normal" else Color("#fff3d6"), GOLD, 3))
    marker.add_theme_stylebox_override("disabled", _style(Color("#8d8a80"), Color("#547a79"), 2))
    if ResourceLoader.exists("res://assets/art/harbour/inspect_marker.png", "Texture2D"):
        _image(marker, "res://assets/art/harbour/inspect_marker.png", Rect2(4, 2, 120, 66))
    else:
        _image(marker, "res://assets/art/icons/inspection.png", Rect2(7, 12, 42, 42))
        _text(marker, "驗貨", Rect2(49, 8, 73, 50), 24, BROWN, true)
    var timing := "每袋 ＋%d 分鐘" % duration if rice_spot_check else "＋%d 分鐘" % duration
    _text(marker, timing if can_inspect else "已來不及", Rect2(4, 68, 120, 24), 13, BROWN, true)
    if can_inspect:
        var pulse := marker.create_tween().set_loops()
        pulse.tween_property(marker, "modulate", Color(1.15, 1.05, 0.8), 0.7)
        pulse.tween_property(marker, "modulate", Color.WHITE, 0.7)


func inspect_berth(slot: int) -> void:
    if not selected_ship.is_empty():
        var placing := selected_ship
        selected_ship = ""
        request_berth(placing, slot)
        return
    var ship := day.ship_at_berth(slot)
    if ship.is_empty() or day.closed() or not day.pending_case.is_empty() or feedback_open or notes_open or manual_open or detail_open:
        return
    if not day.can_inspect_berthed(ship):
        notice = "已來不及在潮汐前完成驗貨。"
        render()
        return
    day.inspect_berthed(ship["id"])
    if day.pending_case.is_empty():
        return
    selected_ship = ""
    notice = ""
    _reset_desk()
    render()


func _reset_desk() -> void:
    evidence_index = -1
    evidence_page = 0
    opened_crates.clear()
    selected_crate = 0
    viewed.clear()
    cited_sack = -1
    method = ""
    stamp = ""
    manual_page = 0
    manual_full = false
    manual_full_page = 0


func _ship_token(ship: Dictionary, pos: Vector2) -> void:
    var token := ShipToken.new()
    token.ship = ship
    token.position = pos
    token.size = SHIP_SIZE
    token.name = "Ship_" + str(ship["id"])
    token.accessibility_name = ship["name"] + "，拖往泊位"
    token.tooltip_text = "拖至泊位，或先選船再按泊位。"
    token.mouse_default_cursor_shape = Control.CURSOR_DRAG
    for state in ["normal", "hover", "pressed", "focus"]:
        token.add_theme_stylebox_override(state, StyleBoxEmpty.new())
    token.pressed.connect(func() -> void:
        selected_ship = ship["id"]
        notice = ""
        render()
    )
    surface.add_child(token)
    # No card behind the hull: the actual ship is the draggable object on water.
    token.picture = _image(token, _ship_art(ship), Rect2(0, -8, 230, 144))
    var tag := _panel(token, Rect2(0, 124, 230, 40), Color(0.12, 0.27, 0.28, 0.94))
    tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
    if selected_ship == ship["id"]:
        tag.add_theme_stylebox_override("panel", _style(DARK, GOLD, 2))
    _image(tag, ship.get("cargo_image", ""), Rect2(5, 4, 30, 30))
    _text(tag, ship["name"], Rect2(42, 0, 180, 22), 15)
    var urgent: bool = int(ship["departure"]) - day.minute_of_day <= 75
    _text(tag, "%s 離港 · 卸貨 %d 分鐘" % [PortDay.clock(ship["departure"]), ship["minutes"]], Rect2(42, 21, 184, 18), 11, GOLD if urgent else MUTED)


func drop_block(ship_id: String, slot: int) -> String:
    if day.closed() or not day.pending_case.is_empty() or feedback_open or notes_open or manual_open or detail_open:
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
    day.dock(ship_id, slot)
    selected_ship = ""
    notice = ""
    render()


## Direct decision used by tests and shortcuts: unload on the declaration or inspect at once.
func assign_berth(ship_id: String, slot: int, inspect: bool) -> void:
    # Revalidate at the model boundary; no selection or stale prompt can bypass it.
    var block := drop_block(ship_id, slot)
    var ship := _waiting_ship(ship_id)
    if not block.is_empty() or (inspect and not day.can_finish(ship, true)):
        notice = block if not block.is_empty() else "已來不及在潮汐前完成驗貨。"
        render()
        return
    if inspect:
        day.dock(ship_id, slot)
        inspect_berth(slot)
        return
    day.berth(ship_id, false, slot)
    selected_ship = ""
    notice = ""
    render()


func advance(minutes: int) -> void:
    if feedback_open or manual_open or notes_open or detail_open or not day.pending_case.is_empty():
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
            next = mini(next, mini(day.minute_of_day + int(ship["remaining"]), int(ship["departure"])))
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
    var rice_spot_check := day.is_rice_spot_check(day.pending_case)
    _image(surface, inspection.get("art", {}).get("desk", ""), Rect2(0, 0, 1280, 720))
    _header("驗貨桌  /  " + day.pending_case["name"], PortDay.clock(day.minute_of_day) + ("   /   開袋耗時" if rice_spot_check else "   /   時間暫停"))
    var instruction := "逐一打開貨箱、核對手冊，再選擇證據及判決印章。"
    if not manual_seen:
        if viewed.has("contents"):
            instruction = _hint_text("check_manual", "請對照手冊，核實驗貨發現。")
        elif opened_crates.is_empty():
            instruction = _hint_text("open_cargo", "打開貨箱，查看內容。")
        else:
            instruction = "請逐一打開貨箱，查看各箱內容。"
    elif _can_file_stamp():
        instruction = "按下申報單蓋印：" + STAMPS[stamp]
    elif not stamp.is_empty():
        instruction = "請先查驗，再選擇要引用的證據。"
    elif method.is_empty():
        instruction = "請先查驗再引用證據；也可不引用證據，按申報放行。"
    else:
        instruction = _hint_text("stamp", "選擇印章，再按下申報單蓋印。")
    if rice_spot_check and stamp.is_empty():
        instruction = "每開一袋耗時五分鐘；請留意卸貨所需時間，再決定抽驗多少袋。"
    if not day.watch_rice_report.is_empty():
        instruction = day.watch_rice_report
    _hint(instruction)
    # Physical tools live on the left; the declaration and findings share the desk.
    _panel(surface, Rect2(16, 151, 284, 552), PAPER)
    _text(surface, "驗貨工具", Rect2(28, 155, 260, 30), 16, BROWN)
    _cargo_crates(inspection)
    var exterior_tool := "過磅" if inspection["id"] == "case_003" else "查驗封印與過磅"
    _button(surface, exterior_tool, Rect2(28, 377, 260, 49), show_evidence.bind(1))
    _button(surface, "詢問船員", Rect2(28, 438, 260, 49), show_evidence.bind(2))
    var manual := _button(surface, "", Rect2(28, 505, 260, 117), open_manual)
    manual.accessibility_name = MANUAL_TITLE
    _image(manual, "res://assets/inspection/manual_open.png", Rect2(5, 3, 250, 110))
    _text(manual, MANUAL_TITLE + "\n按下翻閱規則", Rect2(10, 27, 240, 70), 20, BROWN, true)
    var timing := "驗貨已耗時 %d 分鐘。\n另一泊位的卸貨未曾中斷。" % inspection["minutes"]
    var timing_color := BROWN
    if rice_spot_check:
        var finish := day.minute_of_day + int(day.pending_case["remaining"])
        var tide := int(day.pending_case["departure"])
        timing = "預計卸妥 %s ／ 離港潮 %s\n%s" % [
            PortDay.clock(finish), PortDay.clock(tide),
            "已來不及在潮汐前卸貨。" if finish > tide else "卸貨尚需 %d 分鐘。" % day.pending_case["remaining"],
        ]
        if finish > tide:
            timing_color = Color("#9b3529")
    _text(surface, timing, Rect2(28, 630, 260, 66), 14, timing_color)
    _declaration(inspection)
    _findings(inspection)
    _stamp_rack(inspection)


func _cargo_crates(inspection: Dictionary) -> void:
    var rice_spot_check := day.is_rice_spot_check(day.pending_case)
    var names: Array = inspection["sacks"].map(func(sack: Dictionary) -> String: return sack["label"]) if rice_spot_check else CRATE_NAMES[inspection["id"]]
    var pitch := 264.0 / names.size()
    for index in names.size():
        var opened := opened_crates.has(index)
        var button := _button(surface, "", Rect2(28 + index * pitch, 192, pitch - 4, 171), open_crate.bind(index))
        _style_paper_button(button)
        if evidence_index == 3 and selected_crate == index:
            button.add_theme_stylebox_override("normal", _style(Color("#dfccac"), GOLD, 3))
        button.accessibility_name = ("查看" if opened else "開封") + names[index]
        var picture = SackPicture.new() if rice_spot_check else CratePicture.new()
        picture.position = Vector2((pitch - (46 if rice_spot_check else 78)) * 0.5, 17)
        picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
        picture.opened = opened
        if rice_spot_check:
            picture.paint = rice_sack_paint.get(opened)
        button.add_child(picture)
        _text(button, names[index], Rect2(2, 90, pitch - 8, 39), 15, BROWN, true)
        _text(button, "已開封" if opened else "按下開封", Rect2(2, 131, pitch - 8, 28), 14, BROWN, true)


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
    var preview: String = copy.get("line", "請查閱完整貨單，核對船方申報。")
    if viewed.has("manifest"):
        preview = copy.get("line", paragraphs[mini(1, paragraphs.size() - 1)])
    _text(paper, preview, Rect2(inset, 111, 379 - inset, 110), 17, BROWN)
    _button(paper, "聽取船長陳述", Rect2(20, 226, 359, 32), show_detail.bind(inspection["title"], inspection["subtitle"]))
    _button(paper, "查閱完整貨單", Rect2(20, 266, 359, 35), show_evidence.bind(0, true))
    var press := _button(paper, "在此蓋印" if stamp.is_empty() else "蓋印：" + STAMPS[stamp], Rect2(20, 308, 359, 38), apply_stamp)
    press.disabled = not _can_file_stamp()
    press.tooltip_text = "請先翻閱手冊，選擇印章；如需引用，請先查驗證據。" if press.disabled else "記錄判決並返回港口。"


func _findings(inspection: Dictionary) -> void:
    var panel := _panel(surface, Rect2(740, 161, 512, 360), PAPER)
    if evidence_index < 0:
        _text(panel, "尚未查驗", Rect2(18, 12, 476, 50), 22, BROWN)
        return
    if evidence_index == 3:
        _crate_findings(panel, inspection)
        return
    var evidence: Dictionary = inspection["evidence"][evidence_index]
    _text(panel, evidence["title"], Rect2(18, 12, 476, 50), 22, BROWN)
    var evidence_text := str(evidence["text"])
    var paragraphs := evidence_text.split("\n\n", false)
    evidence_page = clampi(evidence_page, 0, paragraphs.size() - 1)
    var short_line := _short_evidence(inspection, evidence)
    var has_art := _has_evidence_art(evidence) and (evidence_page == 0 or not short_line.is_empty())
    if has_art:
        _image(panel, evidence["image"], Rect2(17, 65, 478, 135))
    _reading(panel, short_line if not short_line.is_empty() else paragraphs[evidence_page], Rect2(18, 205 if has_art else 74, 476, 96 if has_art else 227), BROWN, 18)
    if short_line.is_empty():
        _button(panel, "<", Rect2(18, 312, 55, 34), _evidence_turn.bind(-1)).disabled = evidence_page == 0
        _text(panel, "%d / %d" % [evidence_page + 1, paragraphs.size()], Rect2(90, 312, 320, 34), 16, BROWN, true)
        _button(panel, ">", Rect2(439, 312, 55, 34), _evidence_turn.bind(1)).disabled = evidence_page == paragraphs.size() - 1
    else:
        _button(panel, "查看完整證據", Rect2(18, 312, 476, 34), show_evidence.bind(evidence_index, true))


func _crate_findings(panel: Control, inspection: Dictionary) -> void:
    if day.is_rice_spot_check(day.pending_case):
        var sack: Dictionary = inspection["sacks"][selected_crate]
        _text(panel, sack["label"], Rect2(18, 12, 476, 50), 22, BROWN)
        _reading(panel, sack["finding"], Rect2(18, 74, 476, 227), BROWN, 18)
        return
    var case_id: String = inspection["id"]
    var title: String = CRATE_NAMES[case_id][selected_crate]
    var evidence: Dictionary = inspection["evidence"][3]
    var findings := str(evidence["text"]).split("\n\n", false)
    match case_id:
        "case_001":
            # The captain's reply belongs with the jar that prompted it, not the silk.
            findings[1] += "\n\n" + findings[3].replace("他沉默許久，才要求把此事交由天猛公親自裁決。", "他沉默許久，沒有回答。")
        "case_003":
            findings = findings[0].split("他們再", false, 1)
            var weighing := findings[1].split("，", false, 1)
            findings[1] = "搬運工" + weighing[0] + "。"
            if viewed.has("contents"):
                findings[selected_crate] += "\n\n全批錫錠：" + weighing[1]
        "case_004":
            findings[2] += "\n\n" + findings[3]
    var body := findings[selected_crate]
    _text(panel, title, Rect2(18, 12, 476, 50), 22, BROWN)
    var has_art := case_id == "case_001" and selected_crate < 2 and ResourceLoader.exists(evidence["image"], "Texture2D")
    if has_art:
        var picture := _image(panel, evidence["image"], Rect2(17, 65, 478, 135))
        var crop := AtlasTexture.new()
        crop.atlas = picture.texture
        var half_width := picture.texture.get_width() / 2.0
        crop.region = Rect2(selected_crate * half_width, 0, half_width, picture.texture.get_height())
        crop.filter_clip = true
        picture.texture = crop
    _reading(panel, body, Rect2(18, 205 if has_art else 74, 476, 96 if has_art else 227), BROWN, 18)
    _button(panel, "查看完整證據", Rect2(18, 312, 476, 34), show_detail.bind(title, body))


func open_crate(index: int) -> void:
    if day.pending_case.is_empty() or manual_open or detail_open:
        return
    var inspection := day.inspection_for(day.pending_case)
    var rice_spot_check := day.is_rice_spot_check(day.pending_case)
    var count: int = inspection["sacks"].size() if rice_spot_check else CRATE_NAMES[inspection["id"]].size()
    if index < 0 or index >= count:
        return
    if rice_spot_check:
        day.open_rice_sack(index)
        if day.pending_case.is_empty():
            render()
            return
    opened_crates[index] = true
    selected_crate = index
    evidence_index = 3
    if rice_spot_check or opened_crates.size() == count:
        viewed["contents"] = true
    render()


func _short_evidence(inspection: Dictionary, evidence: Dictionary) -> String:
    return short_copy.get("cases", {}).get(inspection["id"], {}).get("evidence", {}).get(evidence["id"], "")


func _has_evidence_art(evidence: Dictionary) -> bool:
    return evidence.has("image") and ResourceLoader.exists(evidence["image"], "Texture2D")


func show_evidence(index: int, full := false) -> void:
    if day.pending_case.is_empty() or manual_open or detail_open or index < 0 or index > 2:
        return
    var inspection := day.inspection_for(day.pending_case)
    var evidence: Dictionary = inspection["evidence"][index]
    evidence_index = index
    evidence_page = 0
    match evidence_index:
        0: viewed["manifest"] = true
        1:
            viewed["measurements"] = true
            var shows_seal_plate: bool = inspection["id"] == "case_001" and _has_evidence_art(evidence)
            if inspection["id"] != "case_003" and (full or shows_seal_plate or _short_evidence(inspection, evidence).is_empty()):
                viewed["marks"] = true
        2: viewed["testimony"] = true
    if full:
        show_detail(evidence["title"], evidence["text"])
    else:
        render()


func _evidence_turn(direction: int) -> void:
    evidence_page += direction
    render()


func show_detail(title: String, body: String, close_caption := "返回驗貨桌") -> void:
    detail_title = title
    detail_text = body
    detail_close_caption = close_caption
    detail_open = true
    render()


func _detail() -> void:
    for control: Control in surface.find_children("*", "Control", true, false):
        control.focus_mode = Control.FOCUS_NONE
        if control is BaseButton:
            control.disabled = true
    var panel := _modal(Rect2(230, 145, 820, 510), PAPER)
    _text(panel, detail_title, Rect2(26, 18, 768, 56), 26, BROWN)
    _reading(panel, detail_text, Rect2(26, 87, 768, 330), BROWN, 21)
    var close := _button(panel, detail_close_caption, Rect2(255, 446, 310, 43), func() -> void:
        detail_open = false
        render()
    )
    close.grab_focus()


func _stamp_rack(inspection: Dictionary) -> void:
    _panel(surface, Rect2(318, 535, 934, 168), DARK)
    var citation_caption := "引用已核實的證據"
    if cited_sack >= 0:
        citation_caption += "  ／  已引用：%s" % inspection["sacks"][cited_sack]["label"]
    _text(surface, citation_caption, Rect2(334, 542, 400, 26), 14, GOLD)
    for index in PortDay.CITATION_METHODS.size():
        var id: String = PortDay.CITATION_METHODS[index]["id"]
        var button := _button(surface, METHODS[index], Rect2(334 + index * 181, 574, 170, 35), choose_method.bind(id))
        button.disabled = not _can_cite(id, selected_crate)
        button.tooltip_text = METHOD_TITLES[id] if not button.disabled else "尚未查驗"
        if id == "contents" and day.is_rice_spot_check(day.pending_case) and opened_crates.has(selected_crate):
            button.tooltip_text = "引用%s的貨物查驗結果" % inspection["sacks"][selected_crate]["label"]
        if _citation_selected(id, _citation_sack(id)):
            button.tooltip_text = "取消引用"
            button.add_theme_stylebox_override("normal", _style(Color("#346052"), GOLD, 2))
    var ordered_rulings: Array[String] = []
    for id in STAMPS:
        if inspection["rulings"].any(func(r: Dictionary) -> bool: return r["id"] == id):
            ordered_rulings.append(id)
    for index in ordered_rulings.size():
        var id: String = ordered_rulings[index]
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


func _can_cite(id: String, sack: int) -> bool:
    return viewed.has(id) and (id != "contents" or not day.is_rice_spot_check(day.pending_case) or opened_crates.has(sack))


func _citation_sack(id: String) -> int:
    return selected_crate if id == "contents" and day.is_rice_spot_check(day.pending_case) else -1


func _citation_selected(id: String, sack: int) -> bool:
    return method == id and cited_sack == sack


func choose_method(id: String) -> void:
    if not day.pending_case.is_empty() and _can_cite(id, selected_crate) and not manual_open and not detail_open:
        var sack := _citation_sack(id)
        if _citation_selected(id, sack):
            cited_sack = -1
            method = ""
        else:
            cited_sack = sack
            method = id
        render()


func choose_stamp(id: String) -> void:
    if not manual_open and not detail_open and not day.pending_case.is_empty() and day.inspection_for(day.pending_case)["rulings"].any(func(r: Dictionary) -> bool: return r["id"] == id):
        stamp = id
        render()


func _can_file_stamp() -> bool:
    return not stamp.is_empty() and manual_seen and (stamp == "clear" if method.is_empty() else _can_cite(method, cited_sack))


func apply_stamp() -> void:
    if day.pending_case.is_empty() or not _can_file_stamp() or manual_open or detail_open:
        return
    var inspection := day.inspection_for(day.pending_case)
    var truth: Dictionary = inspection.get("hidden_truth", {})
    var rice_spot_check := day.is_rice_spot_check(day.pending_case)
    var ruling_matches: bool = stamp == truth.get("ruling_id")
    var evidence_matches: bool = not rice_spot_check and method in day._citation_methods(truth)
    day.rule_with_method(stamp, method, cited_sack)
    # The model's legacy diagnostic scaffolding is English; the played desk is not.
    last_feedback = day.ruling_note if rice_spot_check or (ruling_matches and evidence_matches) else day.ruling_note.split("\n\n")[0]
    if not rice_spot_check and method.is_empty():
        last_feedback = "已按申報放行，未引用驗貨證據。"
    elif not rice_spot_check and not (ruling_matches and evidence_matches):
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
    render()


func manual_pages() -> Array:
    return short_copy.get("manual", {}).get("pages", [])


func _manual() -> void:
    var book := _modal(Rect2(170, 145, 940, 510), PAPER)
    _text(book, MANUAL_TITLE, Rect2(28, 18, 500, 35), 25, BROWN)
    _button(book, "合上手冊", Rect2(759, 17, 155, 36), func() -> void:
        manual_open = false
        render()
    )
    var pages := manual_pages()
    if manual_full or pages.is_empty():
        _manual_full(book, not pages.is_empty())
        return
    # A one-glance digest of the rules the Day 1 cases need; the full book stays a click away.
    manual_page = clampi(manual_page, 0, pages.size() - 1)
    var tab_width := 880.0 / pages.size()
    for index in pages.size():
        var tab := _button(book, pages[index]["title"], Rect2(30 + index * tab_width, 66, tab_width - 10, 40), _manual_tab.bind(index))
        if index != manual_page:
            _style_paper_button(tab)
            tab.add_theme_color_override("font_color", BROWN)
            tab.add_theme_color_override("font_hover_color", BROWN)
    var lines := PackedStringArray()
    for line in pages[manual_page]["lines"]:
        lines.append("・" + str(line))
    _reading(book, "\n".join(lines), Rect2(30, 122, 880, 322), BROWN, 20)
    _button(book, "閱讀完整手冊（%d頁）" % day.manual["entries"].size(), Rect2(30, 457, 300, 36), func() -> void:
        manual_full = true
        render()
    )


func _manual_full(book: Panel, has_digest: bool) -> void:
    if has_digest:
        _button(book, "返回摘要", Rect2(590, 17, 155, 36), func() -> void:
            manual_full = false
            render()
        )
    var entries: Array = day.manual["entries"]
    manual_full_page = clampi(manual_full_page, 0, entries.size() - 1)
    _text(book, entries[manual_full_page]["title"], Rect2(30, 74, 880, 40), 25, BROWN)
    _reading(book, entries[manual_full_page]["text"], Rect2(30, 127, 880, 310), BROWN, 20)
    _button(book, "< 上一頁", Rect2(30, 457, 160, 36), _manual_turn.bind(-1)).disabled = manual_full_page == 0
    _text(book, "%d / %d" % [manual_full_page + 1, entries.size()], Rect2(329, 457, 280, 36), 17, BROWN, true)
    _button(book, "下一頁 >", Rect2(750, 457, 160, 36), _manual_turn.bind(1)).disabled = manual_full_page == entries.size() - 1


func _manual_tab(index: int) -> void:
    manual_page = index
    render()


func _manual_turn(direction: int) -> void:
    manual_full_page = clampi(manual_full_page + direction, 0, day.manual["entries"].size() - 1)
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
    _text(panel, "已完成首次值勤。您可重新安排靠泊次序，或改變抽驗策略。", Rect2(30, 105, 780, 100), 21, INK, true)
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
    _text(surface, "國庫  %d" % day.duty, Rect2(428, 27, 140, 36), 20, GOLD, true)
    _text(surface, "存糧  %d 袋" % day.watch_stock, Rect2(576, 27, 156, 36), 20, GOLD, true)
    var duty_help := _button(surface, "", Rect2(737, 27, 183, 36), show_detail.bind("盡忠職守", DUTY_HELP, "關閉說明"))
    duty_help.accessibility_name = "盡忠職守說明"
    _text(duty_help, "盡忠職守  %d" % day.watch_score, Rect2(4, 0, 126, 36), 20, GOLD, true)
    _text(duty_help, "說明", Rect2(129, 0, 46, 36), 14, INK, true)
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

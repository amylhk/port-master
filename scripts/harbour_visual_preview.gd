extends Control
## Visual Stage A showcase scene for Port Master: Melaka 1511.
## Demonstrates all c.1500 Melaka art assets (harbour, 6 ships, 6 cargo lots,
## and the interactive Inspection View) without modifying scripts/harbour.gd.

const INK := Color("#2A1E17")
const PARCHMENT := Color("#F7F0DF")
const GOLD := Color("#C49A45")
const TEAK := Color("#4A2E1E")
const CINNABAR := Color("#A8322D")
const JADE := Color("#3B7A57")

const VESSELS := [
    {
        "id": "rice",
        "name": "Javanese Rice Trader",
        "vessel_type": "Javanese Jong",
        "cargo": "Rice (24 sacks)",
        "ship_tex": "res://assets/art/ships/ship_javanese_jong.png",
        "cargo_tex": "res://assets/art/cargo/cargo_rice.png",
        "slot": "berth_1",
        "manifest": "Vessel: Javanese Rice Trader (Jong)\nOrigin: Tuban, Java\nCargo: 24 sacks of milled rice\nCondition: Dry pandanus sacks",
    },
    {
        "id": "porcelain",
        "name": "Chinese Porcelain Trader",
        "vessel_type": "Ming Chuan Junk",
        "cargo": "Porcelain (Lot Seven)",
        "ship_tex": "res://assets/art/ships/ship_chinese_junk.png",
        "cargo_tex": "res://assets/art/cargo/cargo_porcelain.png",
        "slot": "berth_2",
        "manifest": "Vessel: Chinese Porcelain Trader\nCaptain Lin • Origin: Quanzhou\nLot 7: Six stacks of common bowls\n(60 bowls). No other goods declared.",
    },
    {
        "id": "pepper",
        "name": "Indian Pepper Trader",
        "vessel_type": "Gujarati Merchantman",
        "cargo": "Pepper",
        "ship_tex": "res://assets/art/ships/ship_indian_merchant.png",
        "cargo_tex": "res://assets/art/cargo/cargo_pepper.png",
        "slot": "anchor_1",
        "manifest": "Vessel: Indian Pepper Trader\nOrigin: Calicut / Malabar\nCargo: Tied jute sacks of pepper",
    },
    {
        "id": "resin",
        "name": "Arabian Frankincense Trader",
        "vessel_type": "Arabian Baghlah Dhow",
        "cargo": "Frankincense",
        "ship_tex": "res://assets/art/ships/ship_arabian_dhow.png",
        "cargo_tex": "res://assets/art/cargo/cargo_frankincense.png",
        "slot": "anchor_2",
        "manifest": "Vessel: Arabian Frankincense Trader\nOrigin: Aden / Hadhramaut\nCargo: Strapped chests of amber resin",
    },
    {
        "id": "tin",
        "name": "Regional Tin Trader",
        "vessel_type": "Malay Coastal Perahu",
        "cargo": "Tin Ingots",
        "ship_tex": "res://assets/art/ships/ship_regional_perahu.png",
        "cargo_tex": "res://assets/art/cargo/cargo_tin.png",
        "slot": "anchor_3",
        "manifest": "Vessel: Regional Tin Trader\nOrigin: Perak / Klang\nCargo: Cast Melaka tin ingots (bida)",
    },
    {
        "id": "cloth",
        "name": "Coromandel Cloth Trader",
        "vessel_type": "Keling Merchantman",
        "cargo": "Dyed Cloth",
        "ship_tex": "res://assets/art/ships/ship_coromandel_cloth.png",
        "cargo_tex": "res://assets/art/cargo/cargo_cloth.png",
        "slot": "anchor_4",
        "manifest": "Vessel: Coromandel Cloth Trader\nOrigin: Pulicat / Coromandel\nCargo: Indigo & madder-dyed cotton bolts",
    },
]

const SLOT_POS := {
    "berth_1": Vector2(105, 252),
    "berth_2": Vector2(455, 254),
    "anchor_1": Vector2(815, 295),
    "anchor_2": Vector2(150, 445),
    "anchor_3": Vector2(535, 458),
    "anchor_4": Vector2(935, 448),
}

var inspection_overlay: Control
var jar_opened := false
var jar_tex_rect: TextureRect
var seal_tex_rect: TextureRect
var evidence_plate_rect: TextureRect
var toggle_jar_btn: Button
var selected_vessel: Dictionary = VESSELS[1]
var manifest_body: Label


func _ready() -> void:
    _build_harbour_layer()
    _build_inspection_overlay()
    if OS.get_environment("OPEN_INSPECTION") == "1":
        _open_inspection(VESSELS[1], true)


func _build_harbour_layer() -> void:
    var bg := TextureRect.new()
    bg.texture = load("res://assets/art/harbour/harbour_backdrop.png")
    bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
    bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(bg)

    # Header banner
    var banner := TextureRect.new()
    banner.texture = load("res://assets/art/ui/banner_header.png")
    banner.position = Vector2(320, 10)
    banner.size = Vector2(640, 64)
    banner.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    add_child(banner)

    var title := Label.new()
    title.text = "PORT MASTER: MELAKA 1511  —  HARBOUR WATCH (09:00)"
    title.position = Vector2(345, 28)
    title.size = Vector2(590, 32)
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 18)
    title.add_theme_color_override("font_color", PARCHMENT)
    add_child(title)

    # Berth markers above jetties so ships never occlude them
    _add_berth_marker(Vector2(124, 232), "BERTH 1  •  DOCKED")
    _add_berth_marker(Vector2(474, 232), "BERTH 2  •  DOCKED")

    # Place all 6 Stage A vessels with their cargo lot badges
    for v in VESSELS:
        var pos: Vector2 = SLOT_POS[v["slot"]]
        _add_vessel_card(v, pos)

    # Bottom parchment control strip
    var strip := NinePatchRect.new()
    strip.texture = load("res://assets/art/ui/panel_parchment.png")
    strip.patch_margin_left = 24
    strip.patch_margin_right = 24
    strip.patch_margin_top = 24
    strip.patch_margin_bottom = 24
    strip.position = Vector2(24, 632)
    strip.size = Vector2(1232, 74)
    add_child(strip)

    var row := HBoxContainer.new()
    row.position = Vector2(24, 16)
    row.size = Vector2(1184, 42)
    row.add_theme_constant_override("separation", 18)
    strip.add_child(row)

    var info := Label.new()
    info.text = "Berths 2/2  |  Anchorage 4 vessels  |  Click 'Inspect Lot Seven' to open the Detailed Inspection Desk"
    info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    info.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    info.add_theme_font_size_override("font_size", 15)
    info.add_theme_color_override("font_color", INK)
    row.add_child(info)

    var inspect_btn := _styled_button("Inspect Lot Seven (Porcelain)")
    inspect_btn.pressed.connect(_open_inspection.bind(VESSELS[1], false))
    row.add_child(inspect_btn)


func _add_berth_marker(pos: Vector2, caption: String) -> void:
    var plate := TextureRect.new()
    plate.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    plate.texture = load("res://assets/art/harbour/berth_marker.png")
    plate.position = pos
    plate.size = Vector2(168, 40)
    add_child(plate)

    var lbl := Label.new()
    lbl.text = caption
    lbl.position = Vector2(10, 10)
    lbl.size = Vector2(148, 22)
    lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    lbl.add_theme_font_size_override("font_size", 12)
    lbl.add_theme_color_override("font_color", INK)
    plate.add_child(lbl)


func _add_vessel_card(vessel: Dictionary, pos: Vector2) -> void:
    var holder := Control.new()
    holder.position = pos
    holder.size = Vector2(240, 175)
    add_child(holder)

    var ship := TextureRect.new()
    ship.texture = load(vessel["ship_tex"])
    ship.position = Vector2(12, 0)
    ship.size = Vector2(204, 153)
    ship.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    ship.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    holder.add_child(ship)

    var badge := TextureRect.new()
    badge.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    badge.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    badge.texture = load(vessel["cargo_tex"])
    badge.position = Vector2(178, 96)
    badge.size = Vector2(52, 52)
    holder.add_child(badge)

    var tag := PanelContainer.new()
    var sb := StyleBoxFlat.new()
    sb.bg_color = Color(0.96, 0.93, 0.85, 0.92)
    sb.border_color = TEAK
    sb.set_border_width_all(1)
    sb.set_corner_radius_all(4)
    sb.content_margin_left = 8
    sb.content_margin_right = 8
    sb.content_margin_top = 2
    sb.content_margin_bottom = 2
    tag.add_theme_stylebox_override("panel", sb)
    tag.position = Vector2(24, 146)
    holder.add_child(tag)

    var lbl := Label.new()
    lbl.text = "%s — %s" % [vessel["name"], vessel["cargo"]]
    lbl.add_theme_font_size_override("font_size", 11)
    lbl.add_theme_color_override("font_color", INK)
    tag.add_child(lbl)


func _build_inspection_overlay() -> void:
    inspection_overlay = Control.new()
    inspection_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    inspection_overlay.visible = false
    add_child(inspection_overlay)

    var dim := ColorRect.new()
    dim.color = Color(0.08, 0.05, 0.03, 0.72)
    dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    inspection_overlay.add_child(dim)

    var desk := TextureRect.new()
    desk.texture = load("res://assets/art/inspection/inspection_desk_bg.png")
    desk.position = Vector2(128, 40)
    desk.size = Vector2(1024, 640)
    desk.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    inspection_overlay.add_child(desk)

    # Left: Manifest Scroll
    var scroll_tex := TextureRect.new()
    scroll_tex.texture = load("res://assets/art/inspection/manifest_scroll.png")
    scroll_tex.position = Vector2(28, 64)
    scroll_tex.size = Vector2(360, 480)
    scroll_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    desk.add_child(scroll_tex)

    var m_title := Label.new()
    m_title.text = "CARGO MANIFEST"
    m_title.position = Vector2(44, 52)
    m_title.size = Vector2(272, 28)
    m_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    m_title.add_theme_font_size_override("font_size", 18)
    m_title.add_theme_color_override("font_color", TEAK)
    scroll_tex.add_child(m_title)

    manifest_body = Label.new()
    manifest_body.position = Vector2(54, 118)
    manifest_body.size = Vector2(252, 260)
    manifest_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    manifest_body.add_theme_font_size_override("font_size", 14)
    manifest_body.add_theme_color_override("font_color", INK)
    scroll_tex.add_child(manifest_body)

    # Seal on manifest corner
    seal_tex_rect = TextureRect.new()
    seal_tex_rect.texture = load("res://assets/art/inspection/seal_wax_intact.png")
    seal_tex_rect.position = Vector2(236, 358)
    seal_tex_rect.size = Vector2(78, 78)
    seal_tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    scroll_tex.add_child(seal_tex_rect)

    # Right-top: Stage A Evidence Plate (2:1, Lot Seven)
    evidence_plate_rect = TextureRect.new()
    evidence_plate_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    evidence_plate_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    evidence_plate_rect.texture = load("res://assets/inspection/lot-seven-exterior.png")
    evidence_plate_rect.position = Vector2(442, 108)
    evidence_plate_rect.size = Vector2(490, 245)
    desk.add_child(evidence_plate_rect)

    # Right-bottom: Interactive Porcelain Jar close-up + controls
    jar_tex_rect = TextureRect.new()
    jar_tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    jar_tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    jar_tex_rect.texture = load("res://assets/art/cargo/porcelain_jar_closed.png")
    jar_tex_rect.position = Vector2(444, 368)
    jar_tex_rect.size = Vector2(160, 160)
    desk.add_child(jar_tex_rect)

    var notes := Label.new()
    notes.text = "DETAILED INSPECTION — LOT SEVEN\nToggle between sealed exterior (18 catties gross,\n3 catties tare) and opened interior (nested Ming\nbowls + unlisted red-grain frankincense)."
    notes.position = Vector2(618, 374)
    notes.size = Vector2(320, 96)
    notes.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    notes.add_theme_font_size_override("font_size", 13)
    notes.add_theme_color_override("font_color", INK)
    desk.add_child(notes)

    var btns := HBoxContainer.new()
    btns.position = Vector2(618, 480)
    btns.add_theme_constant_override("separation", 12)
    desk.add_child(btns)

    toggle_jar_btn = _styled_button("Open Jar")
    toggle_jar_btn.pressed.connect(_toggle_jar)
    btns.add_child(toggle_jar_btn)

    var close_btn := _styled_button("Return to Harbour")
    close_btn.pressed.connect(func(): inspection_overlay.visible = false)
    btns.add_child(close_btn)


func _open_inspection(vessel: Dictionary, opened: bool) -> void:
    selected_vessel = vessel
    manifest_body.text = vessel["manifest"]
    jar_opened = opened
    _refresh_inspection_art()
    inspection_overlay.visible = true


func _toggle_jar() -> void:
    jar_opened = not jar_opened
    _refresh_inspection_art()


func _refresh_inspection_art() -> void:
    if jar_opened:
        jar_tex_rect.texture = load("res://assets/art/cargo/porcelain_jar_open.png")
        seal_tex_rect.texture = load("res://assets/art/inspection/seal_wax_broken.png")
        evidence_plate_rect.texture = load("res://assets/inspection/lot-seven-open.png")
        toggle_jar_btn.text = "Close Jar"
    else:
        jar_tex_rect.texture = load("res://assets/art/cargo/porcelain_jar_closed.png")
        seal_tex_rect.texture = load("res://assets/art/inspection/seal_wax_intact.png")
        evidence_plate_rect.texture = load("res://assets/inspection/lot-seven-exterior.png")
        toggle_jar_btn.text = "Open Jar"


func _styled_button(caption: String) -> Button:
    var b := Button.new()
    b.text = caption
    var normal := StyleBoxFlat.new()
    normal.bg_color = TEAK
    normal.border_color = GOLD
    normal.set_border_width_all(2)
    normal.set_corner_radius_all(5)
    normal.content_margin_left = 14
    normal.content_margin_right = 14
    normal.content_margin_top = 6
    normal.content_margin_bottom = 6
    var hover := normal.duplicate()
    hover.bg_color = Color("#633E28")
    b.add_theme_stylebox_override("normal", normal)
    b.add_theme_stylebox_override("hover", hover)
    b.add_theme_stylebox_override("pressed", hover)
    b.add_theme_color_override("font_color", PARCHMENT)
    b.add_theme_font_size_override("font_size", 14)
    return b

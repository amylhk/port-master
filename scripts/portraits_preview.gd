extends Control
## Standalone Godot 4.3 gallery preview for the Stage B/early-day character portraits.
## Displays all 5 deputies and 13 early-day recurring merchants in game-style frames.

const DESIGN_SIZE := Vector2(1280.0, 720.0)
const BG_TEAL := Color("#15353D")
const CARD_TEAL := Color("#1E4650")
const CARD_PARCHMENT := Color("#EFE5CE")
const INK := Color("#2A1E17")
const PARCHMENT := Color("#F7F0DF")
const GOLD := Color("#C49A45")

const DEPUTIES := [
    {"id": "abdul_rahim", "name": "Abdul Rahim", "role": "Broker & Valuer"},
    {"id": "chen_bao", "name": "Chen Bao", "role": "Tally Clerk"},
    {"id": "kesavan", "name": "Kesavan", "role": "Steelyard Weigher"},
    {"id": "pak_mamat", "name": "Pak Mamat", "role": "Roads Pilot"},
    {"id": "siti_aminah", "name": "Siti Aminah", "role": "Rice Buyer"},
]

const MERCHANTS := [
    {"id": "jaka_wira", "name": "Jaka Wira", "role": "Demak · Rice"},
    {"id": "khoja_ismail", "name": "Khoja Ismail", "role": "Cambay · Resin"},
    {"id": "lim_seng", "name": "Lim Seng", "role": "Guangzhou · Porcelain"},
    {"id": "tan_bo", "name": "Tan Bo", "role": "Kim Hong · Factor"},
    {"id": "ong_kuan", "name": "Ong Kuan", "role": "Kim Hong · Nakhoda"},
    {"id": "awang_musa", "name": "Awang Musa", "role": "Perak · Tin"},
    {"id": "sri_rangan", "name": "Sri Rangan", "role": "Pulicat · Cloth"},
    {"id": "arulan", "name": "Arulan", "role": "Kaveri · Deckhand"},
    {"id": "mariam_of_cambay", "name": "Mariam of Cambay", "role": "Cambay · Pepper"},
    {"id": "nyai_ratri", "name": "Nyai Ratri", "role": "Tuban · Rice Broker"},
    {"id": "min_ye", "name": "Min Ye", "role": "Pegu · Rice & Teak"},
    {"id": "encik_hamzah", "name": "Encik Hamzah", "role": "Melaka · Nutmeg"},
    {"id": "ramli_arus", "name": "Ramli of the Arus", "role": "Perak · Tin Factor"},
]

var stage: Control


func _ready() -> void:
    var letterbox := ColorRect.new()
    letterbox.color = BG_TEAL
    letterbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(letterbox)

    stage = Control.new()
    stage.size = DESIGN_SIZE
    add_child(stage)

    _build_gallery()
    resized.connect(_fit_stage)
    _fit_stage()


func _fit_stage() -> void:
    if stage == null:
        return
    var vp := get_viewport_rect().size
    if vp.x <= 0.0 or vp.y <= 0.0:
        return
    var s: float = minf(vp.x / DESIGN_SIZE.x, vp.y / DESIGN_SIZE.y)
    stage.scale = Vector2(s, s)
    stage.position = (vp - DESIGN_SIZE * s) * 0.5


func _build_gallery() -> void:
    var bg := ColorRect.new()
    bg.color = BG_TEAL
    bg.size = DESIGN_SIZE
    stage.add_child(bg)

    var banner := TextureRect.new()
    banner.texture = load("res://assets/art/ui/banner_header.png")
    banner.position = Vector2(320, 8)
    banner.size = Vector2(640, 56)
    banner.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    stage.add_child(banner)

    var title := Label.new()
    title.text = "PORT MASTER: MELAKA 1511  —  DEPUTIES & EARLY MERCHANTS"
    title.position = Vector2(336, 22)
    title.size = Vector2(608, 28)
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 16)
    title.add_theme_color_override("font_color", PARCHMENT)
    stage.add_child(title)

    # Row 1: 5 Deputies (parchment-framed cards)
    _add_section_label(Vector2(28, 72), "HARBOUR DEPUTIES (5)")
    for i in range(DEPUTIES.size()):
        _add_portrait_card(DEPUTIES[i], Vector2(28 + i * 246, 98), Vector2(232, 186), true)

    # Rows 2-3: 13 Early-Day Recurring Merchants (dark-teal game-framed cards)
    _add_section_label(Vector2(28, 298), "EARLY-DAY RECURRING MERCHANTS (13)")
    for i in range(MERCHANTS.size()):
        var row := i / 7
        var col := i % 7
        var x := 28 + col * 176
        var y := 324 + row * 190
        _add_portrait_card(MERCHANTS[i], Vector2(x, y), Vector2(166, 178), false)


func _add_section_label(pos: Vector2, caption: String) -> void:
    var lbl := Label.new()
    lbl.text = caption
    lbl.position = pos
    lbl.size = Vector2(520, 22)
    lbl.add_theme_font_size_override("font_size", 13)
    lbl.add_theme_color_override("font_color", GOLD)
    stage.add_child(lbl)


func _add_portrait_card(entry: Dictionary, pos: Vector2, card_size: Vector2, parchment_bg: bool) -> void:
    var card := PanelContainer.new()
    var sb := StyleBoxFlat.new()
    sb.bg_color = CARD_PARCHMENT if parchment_bg else CARD_TEAL
    sb.border_color = GOLD
    sb.set_border_width_all(2)
    sb.set_corner_radius_all(8)
    card.add_theme_stylebox_override("panel", sb)
    card.position = pos
    card.size = card_size
    stage.add_child(card)

    var vbox := VBoxContainer.new()
    vbox.add_theme_constant_override("separation", 2)
    card.add_child(vbox)

    var tex := TextureRect.new()
    tex.texture = load("res://assets/art/portraits/%s.png" % entry["id"])
    tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    tex.custom_minimum_size = Vector2(card_size.x - 8, card_size.y - 46)
    vbox.add_child(tex)

    var name_lbl := Label.new()
    name_lbl.text = entry["name"]
    name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    name_lbl.add_theme_font_size_override("font_size", 13)
    name_lbl.add_theme_color_override("font_color", INK if parchment_bg else PARCHMENT)
    vbox.add_child(name_lbl)

    var role_lbl := Label.new()
    role_lbl.text = entry["role"]
    role_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    role_lbl.add_theme_font_size_override("font_size", 10)
    role_lbl.add_theme_color_override("font_color", Color("#5C4430") if parchment_bg else Color("#C8D4D6"))
    vbox.add_child(role_lbl)

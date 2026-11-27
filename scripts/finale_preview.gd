extends Control
## Standalone Godot gallery preview for the Stage D finale scenes (days 16–18).
## Displays the Fall (last_quay_roll) and all four Day 18 fates at 1280x720 with click-to-inspect.

const DESIGN_SIZE := Vector2(1280.0, 720.0)
const BG_TEAL := Color("#15353D")
const CARD_TEAL := Color("#1E4650")
const INK := Color("#2A1E17")
const PARCHMENT := Color("#F7F0DF")
const GOLD := Color("#C49A45")

const FINALE_SCENES := [
	{"id": "last_quay_roll", "title": "Day 16–17 · The Last Quay Roll", "sub": "Late August 1511 — Fall of Melaka"},
	{"id": "aftermath_inland_exile", "title": "Day 18 · A Timber Landing Upriver", "sub": "Fate 1 — Muar & Pagoh Exile"},
	{"id": "aftermath_fortress_quay", "title": "Day 18 · New Coin at the Stone Fort", "sub": "Fate 2 — Portuguese Melaka Quay"},
	{"id": "aftermath_upeh_reckoning", "title": "Day 18 · After the Scaffold in Upeh", "sub": "Fate 3 — December 1511 Upeh"},
	{"id": "aftermath_strait_passage", "title": "Day 18 · A Ledger on the Monsoon", "sub": "Fate 4 — Strait of Melaka Passage"},
]

var stage: Control
var grid_layer: Control
var detail_layer: Control
var detail_tex: TextureRect
var detail_caption: Label
var close_btn: Button
var last_thumb_btn: Control


func _ready() -> void:
	var letterbox := ColorRect.new()
	letterbox.color = BG_TEAL
	letterbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(letterbox)

	stage = Control.new()
	stage.size = DESIGN_SIZE
	add_child(stage)

	_build_ui()
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


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = BG_TEAL
	bg.size = DESIGN_SIZE
	stage.add_child(bg)

	var banner := TextureRect.new()
	banner.texture = load("res://assets/art/ui/banner_header.png")
	banner.position = Vector2(260, 8)
	banner.size = Vector2(760, 52)
	banner.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stage.add_child(banner)

	var title := Label.new()
	title.text = "PORT MASTER: MELAKA 1511  —  FINALE SCENES (DAYS 16–18)"
	title.position = Vector2(276, 20)
	title.size = Vector2(728, 28)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", PARCHMENT)
	stage.add_child(title)

	grid_layer = Control.new()
	grid_layer.size = DESIGN_SIZE
	grid_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(grid_layer)

	# Top row: 2 wide cards (The Fall + Fate 1)
	# Bottom row: 3 cards (Fates 2, 3, 4)
	var layouts := [
		Rect2(36, 72, 594, 304),
		Rect2(650, 72, 594, 304),
		Rect2(36, 392, 392, 304),
		Rect2(444, 392, 392, 304),
		Rect2(852, 392, 392, 304),
	]
	for i in range(FINALE_SCENES.size()):
		_add_scene_card(FINALE_SCENES[i], layouts[i])

	# Fullscreen detail overlay (hidden by default)
	detail_layer = Control.new()
	detail_layer.size = DESIGN_SIZE
	detail_layer.visible = false
	stage.add_child(detail_layer)

	var dim := ColorRect.new()
	dim.color = Color(0.05, 0.1, 0.12, 0.92)
	dim.size = DESIGN_SIZE
	detail_layer.add_child(dim)

	detail_tex = TextureRect.new()
	detail_tex.position = Vector2(80, 56)
	detail_tex.size = Vector2(1120, 630)
	detail_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	detail_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	detail_layer.add_child(detail_tex)

	detail_caption = Label.new()
	detail_caption.position = Vector2(80, 14)
	detail_caption.size = Vector2(900, 32)
	detail_caption.add_theme_font_size_override("font_size", 18)
	detail_caption.add_theme_color_override("font_color", PARCHMENT)
	detail_layer.add_child(detail_caption)

	close_btn = Button.new()
	close_btn.text = "Back to Gallery"
	close_btn.position = Vector2(1040, 14)
	close_btn.size = Vector2(160, 34)
	close_btn.pressed.connect(func() -> void:
		detail_layer.visible = false
		grid_layer.visible = true
		if last_thumb_btn != null:
			last_thumb_btn.grab_focus()
	)
	detail_layer.add_child(close_btn)


func _add_scene_card(entry: Dictionary, rect: Rect2) -> void:
	var card := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = CARD_TEAL
	sb.border_color = GOLD
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(8)
	card.add_theme_stylebox_override("panel", sb)
	card.position = rect.position
	card.size = rect.size
	grid_layer.add_child(card)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	card.add_child(vbox)

	var img_tex: Texture2D = load("res://assets/art/finale/%s.png" % entry["id"])
	var tex_btn := TextureButton.new()
	tex_btn.texture_normal = img_tex
	tex_btn.ignore_texture_size = true
	tex_btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	tex_btn.custom_minimum_size = Vector2(rect.size.x - 10, rect.size.y - 54)
	tex_btn.pressed.connect(func() -> void:
		last_thumb_btn = tex_btn
		detail_tex.texture = img_tex
		detail_caption.text = "%s  —  %s" % [entry["title"], entry["sub"]]
		grid_layer.visible = false
		detail_layer.visible = true
		close_btn.grab_focus()
	)
	vbox.add_child(tex_btn)

	var t_lbl := Label.new()
	t_lbl.text = entry["title"]
	t_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t_lbl.add_theme_font_size_override("font_size", 14)
	t_lbl.add_theme_color_override("font_color", PARCHMENT)
	vbox.add_child(t_lbl)

	var s_lbl := Label.new()
	s_lbl.text = entry["sub"]
	s_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	s_lbl.add_theme_font_size_override("font_size", 11)
	s_lbl.add_theme_color_override("font_color", Color("#C8D4D6"))
	vbox.add_child(s_lbl)

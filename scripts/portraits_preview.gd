extends Control
## Standalone Godot 4.3 gallery preview for the full 64-character cast portrait roster.
## Toggle between Remaining Cast (46) and Deputies & Early Merchants (18).

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

const EARLY_MERCHANTS := [
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

const REMAINING_CAST := [
	# 8 Remaining Merchants
	{"id": "idris_pasai", "name": "Idris of Pasai", "role": "Pasai · Pepper"},
	{"id": "jalal_sonargaon", "name": "Jalal Sonargaon", "role": "Bengal · Muslin"},
	{"id": "lin_wen", "name": "Lin Wen", "role": "Fujian · Porcelain"},
	{"id": "matsu_of_naha", "name": "Matsu of Naha", "role": "Ryukyu · Silver"},
	{"id": "po_dara", "name": "Po Dara", "role": "Champa · Eaglewood"},
	{"id": "raden_sura", "name": "Raden Sura", "role": "Java · Rice"},
	{"id": "salim_diu", "name": "Salim of Diu", "role": "Diu · Cloth"},
	{"id": "yusuf_vora", "name": "Yusuf Vora", "role": "Cambay · Broker"},
	# 4 Portuguese Expedition
	{"id": "afonso_de_albuquerque", "name": "Albuquerque", "role": "Portuguese Governor"},
	{"id": "diogo_lopes_de_sequeira", "name": "Sequeira", "role": "1509 Captain-Major"},
	{"id": "duarte_fernandes", "name": "Duarte Fernandes", "role": "Envoy & Tailor"},
	{"id": "rui_de_araujo", "name": "Rui de Araújo", "role": "Captive Factor"},
	# 17 Malay Royals & Court
	{"id": "sultan_mahmud_shah", "name": "Sultan Mahmud", "role": "Sultan of Melaka"},
	{"id": "sultan_ahmad_shah", "name": "Sultan Ahmad", "role": "Heir & Commander"},
	{"id": "tun_fatimah", "name": "Tun Fatimah", "role": "Bendahara Daughter"},
	{"id": "tun_mutahir", "name": "Tun Mutahir", "role": "Bendahara"},
	{"id": "tun_pikrama", "name": "Tun Pikrama", "role": "Paduka Tuan"},
	{"id": "tun_hasan_temenggung", "name": "Tun Hasan", "role": "Temenggung"},
	{"id": "tun_tahir", "name": "Tun Tahir", "role": "Seri Nara Diraja"},
	{"id": "tun_hamzah", "name": "Tun Hamzah", "role": "Court Youth"},
	{"id": "tun_ali_hati", "name": "Tun Ali Hati", "role": "Ahmad's Circle"},
	{"id": "tun_mai_ulat_bulu", "name": "Tun Mai", "role": "Court Noble"},
	{"id": "raja_abdullah_kampar", "name": "Raja Abdullah", "role": "Raja of Kampar"},
	{"id": "laksamana_khoja_husain", "name": "Khoja Husain", "role": "Laksamana"},
	{"id": "hang_nadim", "name": "Hang Nadim", "role": "Sea Commander"},
	{"id": "tuam_banda", "name": "Tuam Banda", "role": "Court Official"},
	{"id": "tuam_mafamut", "name": "Tuam Mafamut", "role": "Court Elder"},
	{"id": "regimo_diraja", "name": "Regimo Diraja", "role": "Court Officer"},
	{"id": "tuan_colascar", "name": "Tuan Colascar", "role": "Port Officer"},
	# 5 Upeh / Javanese Household
	{"id": "utimutiraja", "name": "Utimutiraja", "role": "Upeh Patriarch"},
	{"id": "utimutiraja_widow", "name": "Utimutiraja Widow", "role": "Upeh Household"},
	{"id": "pate_acoo", "name": "Pate Acoo", "role": "Upeh Heir"},
	{"id": "patih_kadir", "name": "Patih Kadir", "role": "Upeh Captain"},
	{"id": "upeh_reception_broker", "name": "Upeh Broker", "role": "Reception Broker"},
	# 5 Keling / Tamil & Brokers
	{"id": "nina_chatu", "name": "Nina Chatu", "role": "Keling Merchant"},
	{"id": "raja_mendeliar", "name": "Raja Mendeliar", "role": "Shahbandar Rival"},
	{"id": "naina_sura_dewana", "name": "Naina Sura Dewana", "role": "Keling Elder"},
	{"id": "kannan_bookkeeper", "name": "Kannan", "role": "Bookkeeper"},
	{"id": "si_kitul", "name": "Si Kitul", "role": "Informer"},
	# 4 Shahbandars & Reception
	{"id": "cambay_shahbandar", "name": "Cambay Shahbandar", "role": "Gujarati Port Chief"},
	{"id": "cojeabrahem", "name": "Cojeabrahem", "role": "Gujarati Envoy"},
	{"id": "cogequirmani", "name": "Cogequirmani", "role": "Persian Broker"},
	{"id": "eastern_junks_shahbandar", "name": "Eastern Shahbandar", "role": "Junk Port Chief"},
	# 3 Waterfront Workers & Retainers
	{"id": "awang_jernih", "name": "Awang Jernih", "role": "Orang Laut Boatman"},
	{"id": "salmah_quay_watch", "name": "Salmah", "role": "Quay Watch"},
	{"id": "seri_bunga", "name": "Seri Bunga", "role": "Dock Retainer"},
]

var stage: Control
var batch1_layer: Control
var batch2_layer: Control
var btn_batch1: Button
var btn_batch2: Button


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
	banner.position = Vector2(260, 6)
	banner.size = Vector2(760, 50)
	banner.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stage.add_child(banner)

	var title := Label.new()
	title.text = "PORT MASTER: MELAKA 1511  —  COMPLETE CAST PORTRAITS (64)"
	title.position = Vector2(276, 18)
	title.size = Vector2(728, 26)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 15)
	title.add_theme_color_override("font_color", PARCHMENT)
	stage.add_child(title)

	btn_batch2 = Button.new()
	btn_batch2.text = "Remaining Cast (46)"
	btn_batch2.position = Vector2(18, 14)
	btn_batch2.size = Vector2(220, 34)
	btn_batch2.pressed.connect(_show_batch2)
	stage.add_child(btn_batch2)

	btn_batch1 = Button.new()
	btn_batch1.text = "Deputies & Early (18)"
	btn_batch1.position = Vector2(1042, 14)
	btn_batch1.size = Vector2(220, 34)
	btn_batch1.pressed.connect(_show_batch1)
	stage.add_child(btn_batch1)

	batch2_layer = Control.new()
	batch2_layer.size = DESIGN_SIZE
	batch2_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(batch2_layer)
	_build_batch2()

	batch1_layer = Control.new()
	batch1_layer.size = DESIGN_SIZE
	batch1_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(batch1_layer)
	_build_batch1()

	_show_batch2()


func _build_batch2() -> void:
	# 10 columns x 5 rows fits all 46 portraits crisply inside 1280x720
	for i in range(REMAINING_CAST.size()):
		var row := i / 10
		var col := i % 10
		var x := 14 + col * 126
		var y := 60 + row * 126
		var is_merchant := i < 8
		_add_portrait_card(batch2_layer, REMAINING_CAST[i], Vector2(x, y), Vector2(120, 120), is_merchant, true)


func _build_batch1() -> void:
	_add_section_label(batch1_layer, Vector2(28, 72), "HARBOUR DEPUTIES (5)")
	for i in range(DEPUTIES.size()):
		_add_portrait_card(batch1_layer, DEPUTIES[i], Vector2(28 + i * 246, 98), Vector2(232, 186), true, false)

	_add_section_label(batch1_layer, Vector2(28, 298), "EARLY-DAY RECURRING MERCHANTS (13)")
	for i in range(EARLY_MERCHANTS.size()):
		var row := i / 7
		var col := i % 7
		var x := 28 + col * 176
		var y := 324 + row * 190
		_add_portrait_card(batch1_layer, EARLY_MERCHANTS[i], Vector2(x, y), Vector2(166, 178), false, false)


func _show_batch2() -> void:
	batch2_layer.visible = true
	batch1_layer.visible = false


func _show_batch1() -> void:
	batch1_layer.visible = true
	batch2_layer.visible = false


func _add_section_label(parent: Control, pos: Vector2, caption: String) -> void:
	var lbl := Label.new()
	lbl.text = caption
	lbl.position = pos
	lbl.size = Vector2(520, 22)
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.add_theme_color_override("font_color", GOLD)
	parent.add_child(lbl)


func _add_portrait_card(parent: Control, entry: Dictionary, pos: Vector2, card_size: Vector2, parchment_bg: bool, compact: bool) -> void:
	var card := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = CARD_PARCHMENT if parchment_bg else CARD_TEAL
	sb.border_color = GOLD
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(6 if compact else 8)
	card.add_theme_stylebox_override("panel", sb)
	card.position = pos
	card.size = card_size
	parent.add_child(card)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 1 if compact else 2)
	card.add_child(vbox)

	var tex := TextureRect.new()
	tex.texture = load("res://assets/art/portraits/%s.png" % entry["id"])
	tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var img_h := card_size.y - (32 if compact else 46)
	tex.custom_minimum_size = Vector2(card_size.x - 8, img_h)
	vbox.add_child(tex)

	var name_lbl := Label.new()
	name_lbl.text = entry["name"]
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name_lbl.add_theme_font_size_override("font_size", 10 if compact else 13)
	name_lbl.add_theme_color_override("font_color", INK if parchment_bg else PARCHMENT)
	vbox.add_child(name_lbl)

	var role_lbl := Label.new()
	role_lbl.text = entry["role"]
	role_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	role_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	role_lbl.add_theme_font_size_override("font_size", 8 if compact else 10)
	role_lbl.add_theme_color_override("font_color", Color("#5C4430") if parchment_bg else Color("#C8D4D6"))
	vbox.add_child(role_lbl)

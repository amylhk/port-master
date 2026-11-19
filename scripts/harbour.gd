extends Control
## A playable, deliberately small harbour-queue experiment.
## All ships and values are fictional test data, not historical claims.

const BERTH_CAPACITY := 2
const ANCHORAGE_CAPACITY := 3
const DAY_END_MINUTES := 17 * 60
const SHIPS := [
    {"name": "Javanese Rice Trader", "cargo": "Rice", "minutes": 55},
    {"name": "Chinese Porcelain Trader", "cargo": "Porcelain", "minutes": 70},
    {"name": "Indian Pepper Trader", "cargo": "Pepper", "minutes": 65},
    {"name": "Arabian Frankincense Trader", "cargo": "Frankincense", "minutes": 60},
    {"name": "Regional Tin Trader", "cargo": "Tin", "minutes": 45},
]

var minute_of_day := 9 * 60
var waiting: Array[Dictionary] = []
var berths: Array[Dictionary] = []
var completed := 0
var lost := 0
var next_ship := 0
var log_lines: Array[String] = []
var status_label: Label
var ship_list: VBoxContainer
var log_label: Label

func _ready() -> void:
    _build_ui()
    _arrive_ship()
    _arrive_ship()
    _arrive_ship()
    _refresh()

func _build_ui() -> void:
    var scroll := ScrollContainer.new()
    scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(scroll)
    var column := VBoxContainer.new()
    column.custom_minimum_size = Vector2(580, 0)
    column.add_theme_constant_override("separation", 12)
    scroll.add_child(column)
    var title := Label.new()
    title.text = "PORT MASTER — MELAKA 1511 | Harbour experiment"
    title.add_theme_font_size_override("font_size", 24)
    column.add_child(title)
    status_label = Label.new()
    column.add_child(status_label)
    var help := Label.new()
    help.text = "Choose which ship to berth. Time advances in 15-minute steps; berths process cargo in parallel."
    help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    column.add_child(help)
    ship_list = VBoxContainer.new()
    column.add_child(ship_list)
    var controls := HBoxContainer.new()
    column.add_child(controls)
    _button(controls, "Advance 15 min", _advance.bind(15))
    _button(controls, "Advance 60 min", _advance.bind(60))
    _button(controls, "Next arrival", _arrive_ship)
    log_label = Label.new()
    log_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    column.add_child(log_label)

func _button(parent: Node, caption: String, callback: Callable) -> void:
    var button := Button.new()
    button.text = caption
    button.pressed.connect(callback)
    parent.add_child(button)

func _arrive_ship() -> void:
    if next_ship >= SHIPS.size():
        _log("No more ships in this test scenario.")
    elif minute_of_day >= DAY_END_MINUTES:
        _log("The harbour is closed for the day.")
    elif waiting.size() >= ANCHORAGE_CAPACITY:
        lost += 1
        _log("Anchorage full: %s sailed on." % SHIPS[next_ship]["name"])
        next_ship += 1
    else:
        var ship: Dictionary = SHIPS[next_ship].duplicate(true)
        ship["remaining"] = ship["minutes"]
        waiting.append(ship)
        next_ship += 1
        _log("Arrived: %s" % ship["name"])
    _refresh()

func _berth_ship(index: int) -> void:
    if index < 0 or index >= waiting.size() or berths.size() >= BERTH_CAPACITY:
        return
    var ship: Dictionary = waiting.pop_at(index)
    berths.append(ship)
    _log("Berthed: %s" % ship["name"])
    _refresh()

func _advance(minutes: int) -> void:
    if minute_of_day >= DAY_END_MINUTES:
        return
    var elapsed: int = mini(minutes, DAY_END_MINUTES - minute_of_day)
    minute_of_day += elapsed
    for i in range(berths.size() - 1, -1, -1):
        berths[i]["remaining"] -= elapsed
        if berths[i]["remaining"] <= 0:
            completed += 1
            _log("Completed: %s" % berths[i]["name"])
            berths.remove_at(i)
    if minute_of_day >= DAY_END_MINUTES:
        _log("Day closed. %d ships remain at anchor; departure rules are not yet implemented." % waiting.size())
    _refresh()

func _refresh() -> void:
    var hh: int = minute_of_day / 60
    var mm: int = minute_of_day % 60
    status_label.text = "Time %02d:%02d  |  Berths %d/%d  |  Anchorage %d/%d  |  Completed %d  |  Lost %d" % [hh, mm, berths.size(), BERTH_CAPACITY, waiting.size(), ANCHORAGE_CAPACITY, completed, lost]
    for child in ship_list.get_children():
        child.queue_free()
    var heading := Label.new()
    heading.text = "AT BERTH"
    ship_list.add_child(heading)
    for ship in berths:
        var label := Label.new()
        label.text = "%s — %s — %d min remaining" % [ship["name"], ship["cargo"], ship["remaining"]]
        ship_list.add_child(label)
    heading = Label.new()
    heading.text = "WAITING AT ANCHOR"
    ship_list.add_child(heading)
    for i in range(waiting.size()):
        var ship: Dictionary = waiting[i]
        var row := HBoxContainer.new()
        ship_list.add_child(row)
        var label := Label.new()
        label.text = "%s — %s" % [ship["name"], ship["cargo"]]
        row.add_child(label)
        if berths.size() < BERTH_CAPACITY and minute_of_day < DAY_END_MINUTES:
            _button(row, "Assign berth", _berth_ship.bind(i))
    log_label.text = "EVENT LOG\n" + "\n".join(log_lines)

func _log(message: String) -> void:
    log_lines.push_front(message)
    if log_lines.size() > 9:
        log_lines.pop_back()

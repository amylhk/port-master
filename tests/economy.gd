extends SceneTree

const DIR := "res://data/economy"
const COMMODITIES := [
    "tin", "rice", "timber", "iron", "copper", "nutmeg", "pepper", "sandalwood",
    "frankincense", "silk", "cloth", "porcelain", "glassware",
]
const HANDOFFS := ["lighterage", "unloading", "weighing_records", "warehouse_intake"]
const STOCK_BANDS := ["scarce", "normal", "glut"]
const BLOCS := ["gujarati", "kling_bengal_pegu_pasai", "java_eastern_islands", "china_ryukyu_champa"]

var failures := 0


func _initialize() -> void:
    var scenario := _read("res://data/port_day.json")
    var ships := {}
    var days: Array = [scenario] + scenario.get("following_days", [])
    for day in days:
        for ship in day["ships"]:
            ships[ship["id"]] = true
    var last_day := days.size()
    for story in _records("res://data/history").values():
        last_day = maxi(last_day, int(story.get("day", 0)))

    var prices := _records(DIR.path_join("prices"), true)
    var labour := _records(DIR.path_join("labour"), true)
    var routes := _records(DIR.path_join("arrivals"), true)
    var merchants := _records("res://data/merchants")
    _check_prices(prices)
    _check_calendar(last_day, prices)
    _check_labour(labour, last_day)
    _check_routes(routes, merchants, ships)
    var tagged := _check_offers(prices)

    if failures == 0:
        print("Economy checks passed: %d days, %d prices, %d shortages, %d routes, %d tagged offer choices."
            % [last_day, prices.size(), labour.size(), routes.size(), tagged])
    quit(1 if failures else 0)


func _check_prices(prices: Dictionary) -> void:
    _expect(prices.size() == COMMODITIES.size(), "one price required per blueprint commodity")
    for id in COMMODITIES:
        if not _expect(prices.has(id), "missing commodity %s" % id):
            continue
        var record: Dictionary = prices[id]
        _expect(_has_text(record.get("name")), "%s needs a name" % id)
        _expect(_integer(record.get("base_index"), 1), "%s needs a positive base index" % id)
        var months: Variant = record.get("month_pct")
        var bands: Variant = record.get("stock_pct")
        if not _expect(months is Array and months.size() == 12, "%s needs 12 month percentages" % id):
            continue
        if not _expect(bands is Dictionary and bands.size() == STOCK_BANDS.size(), "%s needs three stock percentages" % id):
            continue
        for band in STOCK_BANDS:
            _expect(_signed_integer(bands.get(band)), "%s needs an integer %s percentage" % [id, band])
        _expect(bands.get("normal") == 0, "%s needs a neutral normal stock percentage" % id)
        if _signed_integer(bands.get("scarce")) and _signed_integer(bands.get("glut")):
            _expect(bands["scarce"] > 0 and bands["glut"] < 0, "%s must rise in scarcity and fall in glut" % id)
        for pct in months:
            if _expect(_signed_integer(pct), "%s has a non-integer month percentage" % id):
                for band in STOCK_BANDS:
                    if _signed_integer(bands.get(band)):
                        _expect(100 + pct + bands[band] > 0, "%s has a nonpositive price" % id)


func _check_calendar(last_day: int, prices: Dictionary) -> void:
    var calendar := _read(DIR.path_join("calendar.json"))
    _expect(calendar.size() == last_day, "calendar must have one entry per campaign day")
    for day in range(1, last_day + 1):
        var entry: Variant = calendar.get(str(day))
        if not _expect(entry is Dictionary, "missing calendar day %d" % day):
            continue
        _expect(_month(entry.get("month")), "invalid month on day %d" % day)
        var stock: Variant = entry.get("stock", {})
        if _expect(stock is Dictionary, "invalid stock map on day %d" % day):
            for id in stock:
                _expect(prices.has(id) and stock[id] in ["scarce", "glut"], "invalid stock for %s on day %d" % [id, day])


func _check_labour(records: Dictionary, last_day: int) -> void:
    var handoffs := {}
    var trigger := RegEx.create_from_string("^day(>=|<=|==|>|<)[1-9][0-9]*\\z")
    for id in records:
        var record: Dictionary = records[id]
        _expect(_has_text(record.get("title")) and _has_text(record.get("body")), "%s needs a title and body" % id)
        var handoff: Variant = record.get("handoff")
        if _expect(handoff in HANDOFFS, "%s has an unknown handoff" % id):
            handoffs[handoff] = true
        _expect(_integer(record.get("delay_minutes"), 1), "%s requires a positive delay_minutes" % id)
        if _expect(record.has("day") != record.has("trigger"), "%s needs exactly one of day or trigger" % id):
            if record.has("day"):
                _expect(_integer(record["day"], 1) and record["day"] <= last_day, "%s has an invalid day" % id)
            else:
                _expect(record["trigger"] is String and trigger.search(record["trigger"]) != null, "%s has an invalid trigger" % id)
        for key in ["requires", "conditions"]:
            var items: Variant = record.get(key, [])
            if _expect(items is Array, "%s: %s must be an array" % [id, key]):
                for item in items:
                    _expect(_has_text(item), "%s: %s must contain text" % [id, key])
    _expect(handoffs.size() == HANDOFFS.size(), "all authored labour handoffs must be represented")


func _check_routes(routes: Dictionary, merchants: Dictionary, ships: Dictionary) -> void:
    for id in routes:
        var route: Dictionary = routes[id]
        _expect(_has_text(route.get("origin")), "%s needs an origin" % id)
        var bloc: Variant = route.get("bloc")
        _expect(route.has("bloc") and (bloc == null or bloc in BLOCS), "%s has an invalid bloc" % id)
        _check_refs(id, route, "merchant_ids", merchants)
        _check_refs(id, route, "ship_ids", ships)
        if route.get("merchant_ids") is Array:
            for merchant_id in route["merchant_ids"]:
                if merchants.has(merchant_id):
                    _expect(merchants[merchant_id]["bloc"] == bloc, "%s merchant %s has a different bloc" % [id, merchant_id])
        var weights: Variant = route.get("arrival_weights")
        if _expect(weights is Array and weights.size() == 12, "%s needs 12 arrival weights" % id):
            var nonzero := false
            for weight in weights:
                if _expect(_integer(weight, 0), "%s has an invalid arrival weight" % id):
                    nonzero = nonzero or weight > 0
            _expect(nonzero, "%s has no active arrival month" % id)
        var departures: Variant = route.get("preferred_departure_months", [])
        if _expect(departures is Array, "%s needs a departure month array" % id):
            var seen := {}
            for month in departures:
                if _expect(_month(month) and not seen.has(month), "%s has an invalid or repeated departure month" % id):
                    seen[month] = true


func _check_refs(id: String, record: Dictionary, key: String, index: Dictionary) -> void:
    var refs: Variant = record.get(key, [])
    if _expect(refs is Array, "%s: %s must be an array" % [id, key]):
        var seen := {}
        for ref in refs:
            if _expect(ref is String and index.has(ref) and not seen.has(ref), "%s: invalid or repeated %s reference %s" % [id, key, ref]):
                seen[ref] = true


func _check_offers(prices: Dictionary) -> int:
    var offers := _records("res://data/offers")
    var tagged := 0
    for offer in offers.values():
        for choice in offer.get("choices", []):
            if not choice.has("commodity_id"):
                continue
            tagged += 1
            var duty: Variant = choice.get("effects", {}).get("duty")
            var label := "%s/%s" % [offer["id"], choice["id"]]
            _expect(prices.has(choice["commodity_id"]), "%s references an unknown commodity" % label)
            _expect(_signed_integer(duty) and duty < 0, "%s must tag a negative duty purchase" % label)
    var pegu := {}
    for choice in offers.get("min_ye_rice_or_teak", {}).get("choices", []):
        pegu[choice["id"]] = choice.get("commodity_id")
    _expect(pegu.get("buy_rice") == "rice" and pegu.get("buy_teak") == "timber",
        "Pegu's alternative purchases must price different commodities")
    return tagged


func _records(directory: String, require_notes := false) -> Dictionary:
    var records := {}
    var pattern := RegEx.create_from_string("^[a-z][a-z0-9_]*\\z")
    for file in DirAccess.get_files_at(directory):
        if not file.ends_with(".json"):
            continue
        var path := directory.path_join(file)
        var record := _read(path)
        var id: Variant = record.get("id")
        if not _expect(id is String and pattern.search(id) != null and file == id + ".json",
                "%s must have a matching lower-snake-case id" % path):
            continue
        records[id] = record
        if require_notes:
            var notes: Variant = record.get("notes")
            if _expect(notes is Array and not notes.is_empty(), "%s needs notes" % path):
                for note in notes:
                    _expect(note is String and (note.begins_with("fact: ") or note.begins_with("inference: ")
                        or note.begins_with("gameplay: ")), "%s has an unlabeled note" % path)
    _expect(not records.is_empty(), "%s has no records" % directory)
    return records


func _read(path: String) -> Dictionary:
    var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
    return data if _expect(data is Dictionary, "%s must contain a JSON object" % path) else {}


func _has_text(value: Variant) -> bool:
    return value is String and not value.strip_edges().is_empty()


func _signed_integer(value: Variant) -> bool:
    return value is int or (value is float and value == floor(value))


func _integer(value: Variant, minimum: int) -> bool:
    return _signed_integer(value) and value >= minimum


func _month(value: Variant) -> bool:
    return _integer(value, 1) and value <= 12


func _expect(ok: bool, message: String) -> bool:
    if not ok:
        failures += 1
        push_error(message)
    return ok

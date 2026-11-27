extends SceneTree

const Harbour = preload("res://scenes/harbour.tscn")

var failures := 0


func _initialize() -> void:
    call_deferred("_run")


func _run() -> void:
    root.size = Vector2i(1280, 960)
    var harbour = Harbour.instantiate()
    root.add_child(harbour)
    var day = harbour.day
    if day.scenario.is_empty() or day.inspection.is_empty() or day.manual.is_empty():
        _expect(false, "main scene loads the day, case, and manual")
        quit(1)
        return
    _expect(day.inspection["title"] == "The jars from Guangzhou", "main scene loads the authored inspection")
    _expect(day.manual["entries"].size() == 11, "main scene loads all authored manual entries")

    _expect(day.waiting.size() == 3, "morning harbour has three waiting ships")
    harbour._berth("rice", false)
    _expect(day.ship_at_anchor(0).is_empty() and day.ship_at_anchor(1).get("id") == "pepper",
        "assigning one ship keeps the other ship in its original row")
    harbour._berth("pepper", false)
    harbour._advance(60)
    _expect(day.rice == 24 and day.duty == 30, "two berths unload in parallel")
    _expect(day.ship_at_anchor(0).get("id") == "resin" and day.ship_at_anchor(2).get("id") == "porcelain",
        "a scheduled arrival fills a free slot without moving other ships")
    harbour._berth("porcelain", true)
    _expect(day.pending_case.is_empty(), "serving both early ships misses the inspection window")
    harbour._berth("porcelain", false)
    harbour._advance(60)
    _expect(day.completed == 3 and day.duty == 42, "cleared porcelain trades exactly on the deadline")

    harbour._restart()
    harbour._berth("rice", false)
    harbour._berth("porcelain", true)
    _expect(day.minute_of_day == 585 and day.berths[0]["remaining"] == 15, "one fixed inspection cost advances the other berth")
    _expect(day.waiting.size() == 2 and day.pending_case["remaining"] == 60, "scheduled arrival proceeds while porcelain awaits ruling")
    _expect(harbour.ruling_index == -1 and harbour.reason_index == -1, "ruling starts unanswered")
    var scroll := harbour.find_children("*", "ScrollContainer", true, false)[0] as ScrollContainer
    harbour.evidence_index = day.inspection["evidence"].size()
    harbour._render()
    await process_frame
    await process_frame
    _expect(not scroll.get_h_scroll_bar().visible, "the reference manual fits within a 1280px-wide window")
    harbour.ruling_index = 1
    harbour.reason_index = 3
    harbour._rule()
    _expect(day.recovered_duty == 0, "the weighing fee is credited only when trade completes")
    harbour._advance(60)
    _expect(day.rice == 24 and day.lost == 1 and day.duty == 38 and day.recovered_duty == 18, "correct proof recovers duty at the cost of the pepper tide")
    harbour._advance(420)
    _expect(day.closed() and day.waiting.is_empty() and day.berths.is_empty(), "the closing ledger follows a finite port day")

    harbour._restart()
    harbour._berth("pepper", false)
    harbour._berth("porcelain", true)
    day.rule("major_fraud", "foreign_seal")
    harbour._advance(60)
    _expect(day.rice == 0 and day.duty == 34 and day.recovered_duty == 0 and day.lost == 1, "ruling fraud with the wrong evidence recovers nothing")

    harbour._restart()
    harbour._berth("porcelain", true)
    day.rule("hold", "foreign_seal")
    _expect(day.lost == 1 and day.berths.is_empty(), "an unjustified hold forfeits the porcelain sale")

    harbour._restart()
    harbour._advance(30)
    _expect(day.waiting.size() == 3 and day.lost == 1, "a full anchorage forfeits the next arrival")
    root.size = Vector2i(460, 960)
    await process_frame
    await process_frame
    _expect(scroll.get_h_scroll_bar().visible, "the harbour remains horizontally scrollable at 460px")
    if failures == 0:
        print("Loaded manual: %d entries; case %s (%s): %d evidence pages" % [
            day.manual["entries"].size(), day.inspection["id"], day.inspection["title"], day.inspection["evidence"].size(),
        ])
        print("Stage A checks passed: capacity, deadlines, trade-offs, inspection proof, and closing ledger.")
    quit(1 if failures else 0)


func _expect(condition: bool, message: String) -> void:
    if not condition:
        failures += 1
        push_error("FAILED: " + message)

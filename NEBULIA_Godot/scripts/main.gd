extends Control
## NEBULIA vertical slice: character collection, tactical expeditions, village management and events.
## All content is original placeholder content and designed to be expanded.

const BG := Color("#0b1024")
const PANEL := Color("#151d3a")
const PANEL_2 := Color("#202b50")
const GOLD := Color("#f5cb78")
const CYAN := Color("#80e6f2")
const MUTED := Color("#aab5d8")
const PINK := Color("#f18acb")

var gold := 1200
var gems := 180
var stamina := 12
var day := 1
var pull_count := 0
var village_level := 1
var selected_tab := "Sanctuary"
var roster: Array[Dictionary] = []
var buildings: Array[Dictionary] = [
    {"name":"Moonwell","level":1,"desc":"Produces gems over time","cost":250},
    {"name":"Wayfarer Hall","level":1,"desc":"Unlocks expedition contracts","cost":180},
    {"name":"Starforge","level":1,"desc":"Improves gear rewards","cost":320}
]
var event_claimed := false
var battle_log := ""
var active_enemy_hp := 90
var player_turn := true
var team_power := 0

var root_box: VBoxContainer
var content: VBoxContainer
var status_label: Label
var nav_buttons: Dictionary = {}

const CHARACTERS := [
    {"name":"Airi of the Glass Tide","rarity":"SSR","role":"Duelist","element":"Tide","power":94,"color":Color("#65d8e8"),"skill":"Undertow Waltz"},
    {"name":"Kael, Ember Courier","rarity":"SR","role":"Striker","element":"Flame","power":72,"color":Color("#ff987d"),"skill":"Comet Delivery"},
    {"name":"Mira Bellweather","rarity":"SR","role":"Support","element":"Gale","power":68,"color":Color("#a8f0c6"),"skill":"Borrowed Breeze"},
    {"name":"Noct, the Lantern Fox","rarity":"R","role":"Scout","element":"Shade","power":48,"color":Color("#bca2ff"),"skill":"Foxfire Feint"},
    {"name":"Toma Reedkeeper","rarity":"R","role":"Guardian","element":"Stone","power":52,"color":Color("#e6c18a"),"skill":"Rootbound Guard"},
    {"name":"Sena of the Paper Stars","rarity":"SR","role":"Tactician","element":"Aether","power":70,"color":Color("#ffd7f2"),"skill":"Constellation Map"}
]

func _ready() -> void:
    _seed_roster()
    _build_ui()
    show_tab("Sanctuary")

func _seed_roster() -> void:
    roster = [
        _make_owned(CHARACTERS[1], 1),
        _make_owned(CHARACTERS[2], 1),
        _make_owned(CHARACTERS[3], 1)
    ]

func _make_owned(base: Dictionary, level: int) -> Dictionary:
    var item := base.duplicate(true)
    item["level"] = level
    item["copies"] = 1
    item["bond"] = 0
    return item

func _build_ui() -> void:
    var bg := ColorRect.new()
    bg.color = BG
    bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(bg)

    var margin := MarginContainer.new()
    margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    margin.add_theme_constant_override("margin_left", 22)
    margin.add_theme_constant_override("margin_right", 22)
    margin.add_theme_constant_override("margin_top", 22)
    margin.add_theme_constant_override("margin_bottom", 18)
    add_child(margin)

    root_box = VBoxContainer.new()
    root_box.add_theme_constant_override("separation", 12)
    margin.add_child(root_box)

    var title_row := HBoxContainer.new()
    root_box.add_child(title_row)
    var title := Label.new()
    title.text = "✦  NEBULIA"
    title.add_theme_font_size_override("font_size", 31)
    title.add_theme_color_override("font_color", GOLD)
    title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    title_row.add_child(title)
    var day_label := Label.new()
    day_label.name = "DayLabel"
    day_label.text = "DAY 01"
    day_label.add_theme_color_override("font_color", CYAN)
    day_label.add_theme_font_size_override("font_size", 15)
    title_row.add_child(day_label)

    var status_panel := _panel()
    root_box.add_child(status_panel)
    var status_row := HBoxContainer.new()
    status_row.add_theme_constant_override("separation", 12)
    status_panel.add_child(status_row)
    status_label = Label.new()
    status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    status_label.add_theme_font_size_override("font_size", 15)
    status_label.add_theme_color_override("font_color", Color.WHITE)
    status_row.add_child(status_label)
    _refresh_status()

    var subtitle := Label.new()
    subtitle.text = "A living constellation of companions, places and choices."
    subtitle.add_theme_color_override("font_color", MUTED)
    subtitle.add_theme_font_size_override("font_size", 13)
    root_box.add_child(subtitle)

    var nav := HBoxContainer.new()
    nav.add_theme_constant_override("separation", 6)
    root_box.add_child(nav)
    for tab in ["Sanctuary", "Summon", "Roster", "Expeditions", "Village", "Events", "Ranks"]:
        var b := Button.new()
        b.text = tab
        b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        b.custom_minimum_size.y = 44
        b.add_theme_font_size_override("font_size", 12)
        b.pressed.connect(func(): show_tab(tab))
        nav.add_child(b)
        nav_buttons[tab] = b

    var scroll := ScrollContainer.new()
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    root_box.add_child(scroll)
    content = VBoxContainer.new()
    content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    content.add_theme_constant_override("separation", 12)
    scroll.add_child(content)

func _panel() -> PanelContainer:
    var p := PanelContainer.new()
    var style := StyleBoxFlat.new()
    style.bg_color = PANEL
    style.set_corner_radius_all(16)
    style.set_content_margin_all(14)
    p.add_theme_stylebox_override("panel", style)
    return p

func _label(text: String, size: int = 16, color: Color = Color.WHITE) -> Label:
    var l := Label.new()
    l.text = text
    l.add_theme_font_size_override("font_size", size)
    l.add_theme_color_override("font_color", color)
    l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    return l

func _button(text: String, action: Callable, min_y: int = 46) -> Button:
    var b := Button.new()
    b.text = text
    b.custom_minimum_size.y = min_y
    b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    b.add_theme_font_size_override("font_size", 15)
    b.pressed.connect(action)
    return b

func _section(title: String, subtitle: String = "") -> void:
    content.add_child(_label(title, 24, GOLD))
    if subtitle != "":
        content.add_child(_label(subtitle, 14, MUTED))

func _clear_content() -> void:
    for child in content.get_children():
        child.queue_free()

func show_tab(tab: String) -> void:
    selected_tab = tab
    _clear_content()
    for key in nav_buttons:
        nav_buttons[key].modulate = CYAN if key == tab else Color.WHITE
    match tab:
        "Sanctuary": _show_sanctuary()
        "Summon": _show_summon()
        "Roster": _show_roster()
        "Expeditions": _show_expeditions()
        "Village": _show_village()
        "Events": _show_events()
        "Ranks": _show_ranks()
    _refresh_status()

func _show_sanctuary() -> void:
    _section("The Starfall Sanctuary", "Your home between worlds. Every companion has a story; every choice shapes the constellation.")
    var hero := _panel()
    content.add_child(hero)
    var col := VBoxContainer.new()
    col.add_child(_label("A quiet signal arrives from beyond the Veil.", 19, CYAN))
    col.add_child(_label("The old roads are waking. Recruit a small crew, prepare their roles, then choose an expedition. Victory depends on team composition and skill timing—not tapping faster.", 15))
    hero.add_child(col)
    var row := HBoxContainer.new()
    content.add_child(row)
    row.add_child(_stat_card("COMPANIONS", str(roster.size()), "collected"))
    row.add_child(_stat_card("SANCTUARY", "Lv. %d" % village_level, "growth"))
    row.add_child(_stat_card("NEXT DAY", "Day %02d" % (day + 1), "claim income"))
    content.add_child(_button("Rest & begin next day  •  collect village income", _next_day))
    content.add_child(_button("Open the Starfall Dispatch", func(): show_tab("Events")))
    _section("Today’s field notes")
    content.add_child(_label("• The Wayfarer Hall has found a trace near the Glass Orchard.\n• Mira’s wind-reading can interrupt enemy casting.\n• A limited banner is active for the first seven days.", 15, MUTED))

func _stat_card(title: String, value: String, caption: String) -> Control:
    var p := _panel()
    p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    var v := VBoxContainer.new()
    v.add_child(_label(title, 11, MUTED))
    v.add_child(_label(value, 21, GOLD))
    v.add_child(_label(caption, 12, CYAN))
    p.add_child(v)
    return p

func _show_summon() -> void:
    _section("Astral Archive", "Recruit companions through a ritual. Rates are visible; results are random, with a guaranteed SR or higher every 10 summons.")
    var banner := _panel()
    content.add_child(banner)
    var v := VBoxContainer.new()
    v.add_child(_label("THE TIDE REMEMBERS", 21, CYAN))
    v.add_child(_label("Featured: Airi of the Glass Tide  •  Ends in 6 days", 14, MUTED))
    v.add_child(_label("SSR  4%     SR  26%     R  70%", 16, GOLD))
    v.add_child(_label("Pity: %d / 10" % (pull_count % 10), 14, MUTED))
    banner.add_child(v)
    content.add_child(_button("✦  Summon once  —  100 gems", func(): _summon(1)))
    content.add_child(_button("✦  Summon ten  —  900 gems", func(): _summon(10)))
    content.add_child(_label("Duplicates become Memory Shards and increase Bond. No real-money purchase system is included in this prototype.", 13, MUTED))

func _summon(count: int) -> void:
    var cost := 100 if count == 1 else 900
    if gems < cost:
        _notice("Not enough gems. Complete an expedition or claim an event reward.")
        return
    gems -= cost
    var results: Array[String] = []
    for i in range(count):
        pull_count += 1
        var idx := _roll_character()
        var base: Dictionary = CHARACTERS[idx]
        if pull_count % 10 == 0 and base["rarity"] == "R":
            base = CHARACTERS[1 + (randi() % 2)]
        var found := false
        for owned in roster:
            if owned["name"] == base["name"]:
                owned["copies"] += 1
                owned["bond"] += 10
                gems += 15
                results.append("%s — duplicate (+15 gems, Bond +10)" % base["name"])
                found = true
                break
        if not found:
            roster.append(_make_owned(base, 1))
            results.append("%s  [%s / %s]" % [base["name"], base["rarity"], base["role"]])
    _refresh_status()
    show_tab("Summon")
    var result_panel := _panel()
    content.add_child(result_panel)
    var rv := VBoxContainer.new()
    rv.add_child(_label("ARCHIVE RESULTS", 18, GOLD))
    for result in results:
        rv.add_child(_label("✧ " + result, 14, CYAN))
    result_panel.add_child(rv)

func _roll_character() -> int:
    var roll := randf()
    if roll < 0.04:
        return 0
    if roll < 0.30:
        return [1, 2, 5][randi() % 3]
    return [3, 4, 3, 4][randi() % 4]

func _show_roster() -> void:
    _section("Your Constellation", "Build a balanced team. Roles matter on expeditions: Strikers deal damage, Supports restore resolve, Guardians reduce incoming damage.")
    if roster.is_empty():
        content.add_child(_label("No companions yet. Visit the Astral Archive.", 16, MUTED))
        return
    for member in roster:
        var card := _panel()
        content.add_child(card)
        var row := HBoxContainer.new()
        card.add_child(row)
        var portrait := ColorRect.new()
        portrait.custom_minimum_size = Vector2(10, 88)
        portrait.color = member["color"]
        row.add_child(portrait)
        var v := VBoxContainer.new()
        v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        v.add_child(_label("%s  [%s]" % [member["name"], member["rarity"]], 16, member["color"]))
        v.add_child(_label("%s • %s • Power %d" % [member["role"], member["element"], member["power"] + (member["level"] - 1) * 8], 13, MUTED))
        v.add_child(_label("Lv.%d  |  Copies %d  |  Bond %d" % [member["level"], member["copies"], member["bond"]], 12, CYAN))
        row.add_child(v)
        row.add_child(_button("Train\n80g", func(): _train(member), 56))

func _train(member: Dictionary) -> void:
    if gold < 80:
        _notice("Not enough gold.")
        return
    gold -= 80
    member["level"] += 1
    member["bond"] += 2
    show_tab("Roster")

func _show_expeditions() -> void:
    _section("Wayfarer Contracts", "A short tactical encounter. Pick a crew by recruiting and training; spend stamina to depart. Skills have distinct effects.")
    var team := _team_power()
    var p := _panel()
    p.add_child(_label("Current crew power: %d" % team, 19, GOLD))
    p.add_child(_label("Recommended power: 150 • Rewards: gold, gems, bond", 13, MUTED))
    content.add_child(p)
    content.add_child(_button("Enter: Glass Orchard  •  3 stamina", func(): _start_battle("Glass Orchard", 3, 90, 140, 25)))
    content.add_child(_button("Enter: Lantern-Rail Ruins  •  5 stamina", func(): _start_battle("Lantern-Rail Ruins", 5, 155, 240, 40)))
    content.add_child(_button("Enter: The Quiet Observatory  •  7 stamina", func(): _start_battle("Quiet Observatory", 7, 240, 380, 60)))
    if battle_log != "":
        var log_panel := _panel()
        log_panel.add_child(_label("LAST ENCOUNTER", 17, GOLD))
        log_panel.add_child(_label(battle_log, 14, MUTED))
        content.add_child(log_panel)

func _start_battle(place: String, cost: int, enemy_hp: int, reward_gold: int, reward_gems: int) -> void:
    if stamina < cost:
        _notice("Not enough stamina. Rest by advancing the day.")
        return
    if roster.size() < 3:
        _notice("Recruit at least 3 companions before departing.")
        return
    stamina -= cost
    var power := _team_power()
    var rounds := 0
    var hp := enemy_hp
    var lines: Array[String] = []
    var team_damage := max(18, int(power * 0.31))
    while hp > 0 and rounds < 8:
        rounds += 1
        var damage := team_damage + randi_range(-8, 12)
        if rounds == 2 and _has_role("Support"):
            damage += 15
            lines.append("Mira reads the wind: team combo +15 damage.")
        if rounds == 3 and _has_role("Guardian"):
            lines.append("Toma anchors the line; the team avoids a counterattack.")
        hp -= damage
        lines.append("Round %d: your crew deals %d damage." % [rounds, damage])
        if hp > 0:
            var incoming := max(4, 18 - int(power * 0.025))
            if _has_role("Guardian"):
                incoming = max(2, incoming - 5)
            lines.append("Enemy counters for %d resolve." % incoming)
    if hp <= 0:
        gold += reward_gold
        gems += reward_gems
        for member in roster:
            member["bond"] += 3
        battle_log = "%s cleared in %d rounds. +%d gold, +%d gems.\\n" % [place, rounds, reward_gold, reward_gems] + "\\n".join(lines)
    else:
        battle_log = "%s: your crew withdrew after 8 rounds. Train or improve your village.\\n" % place + "\\n".join(lines)
    _refresh_status()
    show_tab("Expeditions")

func _team_power() -> int:
    var total := 0
    for i in range(min(3, roster.size())):
        total += int(roster[i]["power"]) + (int(roster[i]["level"]) - 1) * 8
    return total

func _has_role(role: String) -> bool:
    for member in roster:
        if member["role"] == role:
            return true
    return false

func _show_village() -> void:
    _section("Hearthvale Village", "A small settlement grows with your companions. Buildings create strategic bonuses; upgrades are choices, not idle tapping.")
    content.add_child(_label("Village level %d  •  Next level at 3 upgraded buildings" % village_level, 15, CYAN))
    for building in buildings:
        var p := _panel()
        content.add_child(p)
        var row := HBoxContainer.new()
        p.add_child(row)
        var v := VBoxContainer.new()
        v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        v.add_child(_label("%s  Lv.%d" % [building["name"], building["level"]], 17, GOLD))
        v.add_child(_label(building["desc"], 13, MUTED))
        v.add_child(_label("Upgrade cost: %d gold" % building["cost"], 12, CYAN))
        row.add_child(v)
        row.add_child(_button("Upgrade", func(): _upgrade_building(building), 52))
    content.add_child(_label("Building bonuses\nMoonwell: +5 gems per day for each level.\nWayfarer Hall: +3 stamina at the start of each day.\nStarforge: expedition gold rewards increase by 5% per level.", 14, MUTED))

func _upgrade_building(building: Dictionary) -> void:
    if gold < int(building["cost"]):
        _notice("Not enough gold for this upgrade.")
        return
    gold -= int(building["cost"])
    building["level"] += 1
    building["cost"] = int(building["cost"] * 1.65)
    var total_levels := 0
    for b in buildings:
        total_levels += int(b["level"]) - 1
    village_level = 1 + int(total_levels / 3)
    show_tab("Village")

func _show_events() -> void:
    _section("Starfall Dispatch", "Rotating limited-time stories with objectives, not just a login reward.")
    var p := _panel()
    content.add_child(p)
    p.add_child(_label("EVENT 01  •  THE PAPER MOON FESTIVAL", 19, PINK))
    p.add_child(_label("The village lanterns are losing their light. Complete one expedition and make a choice: preserve the old shrine or help the travelling troupe.", 14, MUTED))
    p.add_child(_label("Progress: %s" % ("Reward claimed" if event_claimed else "Ready to claim once"), 13, CYAN))
    if not event_claimed:
        content.add_child(_button("Resolve event story & claim 120 gold + 30 gems", _claim_event))
    else:
        content.add_child(_label("You chose to help the travelling troupe. A new story branch can be added in a later chapter.", 14, MUTED))
    var p2 := _panel()
    p2.add_child(_label("Upcoming: Tideglass Tournament", 17, GOLD))
    p2.add_child(_label("Asynchronous challenge concept: compare team power and role synergy against weekly rivals. No live server required for this prototype.", 13, MUTED))
    content.add_child(p2)

func _claim_event() -> void:
    event_claimed = true
    gold += 120
    gems += 30
    _refresh_status()
    show_tab("Events")

func _show_ranks() -> void:
    _section("Constellation Board", "Prototype rankings use local simulated rivals. Online leaderboards require a backend and account system.")
    var rivals := [
        {"name":"VelvetComet","power":4120,"rank":1},
        {"name":"MikoAfterRain","power":3760,"rank":2},
        {"name":"CloudTea","power":3490,"rank":3},
        {"name":"RinOfTheNorth","power":3020,"rank":4}
    ]
    for rival in rivals:
        var p := _panel()
        content.add_child(p)
        var row := HBoxContainer.new()
        p.add_child(row)
        row.add_child(_label("#%d" % rival["rank"], 22, GOLD))
        var v := VBoxContainer.new()
        v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        v.add_child(_label(rival["name"], 16))
        v.add_child(_label("Constellation Power %d" % rival["power"], 12, MUTED))
        row.add_child(v)
    var own := _panel()
    own.add_child(_label("#%d  You" % (5 if _team_power() < 3500 else 3), 20, CYAN))
    own.add_child(_label("Crew power %d • Rank improves through expeditions, bonds and village upgrades." % _team_power(), 13, MUTED))
    content.add_child(own)

func _next_day() -> void:
    day += 1
    stamina = min(12 + _building_level("Wayfarer Hall") * 3, stamina + 8 + _building_level("Wayfarer Hall") * 3)
    gold += 50 + _building_level("Starforge") * 10
    gems += 5 * _building_level("Moonwell")
    for member in roster:
        member["bond"] += 1
    _refresh_status()
    show_tab("Sanctuary")

func _building_level(name: String) -> int:
    for building in buildings:
        if building["name"] == name:
            return int(building["level"])
    return 1

func _refresh_status() -> void:
    if is_instance_valid(status_label):
        status_label.text = "◈ %d gold     ✦ %d gems     ⚡ %d/%d stamina" % [gold, gems, stamina, 12 + _building_level("Wayfarer Hall") * 3]
    if has_node("DayLabel"):
        get_node("DayLabel").text = "DAY %02d" % day

func _notice(message: String) -> void:
    var dialog := AcceptDialog.new()
    dialog.dialog_text = message
    add_child(dialog)
    dialog.confirmed.connect(func(): dialog.queue_free())
    dialog.popup_centered(Vector2i(440, 180))

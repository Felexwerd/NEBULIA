extends Control
## NEBULIA vertical slice: character collection, tactical expeditions, village management and events.
## All content is original placeholder content and designed to be expanded.

const BG := Color("#0b1024")
const PANEL := Color("#151d3a")
const PANEL_2 := Color("#202b50")
const PANEL_DARK := Color("#10172d")
const GOLD := Color("#f5cb78")
const CYAN := Color("#80e6f2")
const MUTED := Color("#aab5d8")
const PINK := Color("#f18acb")
const GREEN := Color("#a7edc5")

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
var daily_claimed := false
var battle_log := ""
var active_enemy_hp := 90
var player_turn := true
var team_power := 0

var root_box: VBoxContainer
var content: VBoxContainer
var status_label: Label
var day_label: Label
var gold_value: Label
var gems_value: Label
var stamina_value: Label
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
    bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(bg)

    var ambience := TextureRect.new()
    ambience.texture = load("res://art/ambient_stars.svg")
    ambience.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    ambience.stretch_mode = TextureRect.STRETCH_SCALE
    ambience.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    ambience.modulate = Color(0.58, 0.67, 1.0, 0.25)
    ambience.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(ambience)

    var margin := MarginContainer.new()
    margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    margin.add_theme_constant_override("margin_left", 17)
    margin.add_theme_constant_override("margin_right", 17)
    margin.add_theme_constant_override("margin_top", 11)
    margin.add_theme_constant_override("margin_bottom", 8)
    add_child(margin)

    root_box = VBoxContainer.new()
    root_box.add_theme_constant_override("separation", 8)
    margin.add_child(root_box)

    var header := HBoxContainer.new()
    header.add_theme_constant_override("separation", 8)
    root_box.add_child(header)
    header.add_child(_label("✦", 29, GOLD))
    var brand := VBoxContainer.new()
    brand.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    brand.add_theme_constant_override("separation", 0)
    brand.add_child(_label("NEBULIA", 24, GOLD))
    brand.add_child(_label("A CONSTELLATION OF STORIES", 9, MUTED))
    header.add_child(brand)
    var day_panel := _panel()
    var day_box := HBoxContainer.new()
    day_box.add_child(_label("DAY", 9, MUTED))
    day_label = _label("01", 14, CYAN)
    day_box.add_child(day_label)
    day_panel.add_child(day_box)
    header.add_child(day_panel)

    var resources := HBoxContainer.new()
    resources.add_theme_constant_override("separation", 6)
    root_box.add_child(resources)
    resources.add_child(_resource_chip("✧", "GOLD", "gold"))
    resources.add_child(_resource_chip("◆", "GEMS", "gems"))
    resources.add_child(_resource_chip("ϟ", "STAMINA", "stamina"))

    var scroll := ScrollContainer.new()
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    root_box.add_child(scroll)
    content = VBoxContainer.new()
    content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    content.add_theme_constant_override("separation", 11)
    scroll.add_child(content)

    var nav_panel := _panel(PANEL_DARK, 5, Color("#2a3858"))
    root_box.add_child(nav_panel)
    var nav := HBoxContainer.new()
    nav.add_theme_constant_override("separation", 3)
    nav_panel.add_child(nav)
    var nav_data := [
        {"key":"Sanctuary","label":"HOME","icon":"⌂"},
        {"key":"Roster","label":"HEROES","icon":"✧"},
        {"key":"Summon","label":"SUMMON","icon":"✦"},
        {"key":"Village","label":"TOWN","icon":"⌘"},
        {"key":"Expeditions","label":"EXPLORE","icon":"⚔"}
    ]
    for item in nav_data:
        var key: String = item["key"]
        var button := Button.new()
        button.text = "%s\n%s" % [item["icon"], item["label"]]
        button.custom_minimum_size = Vector2(0, 54)
        button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        button.add_theme_font_size_override("font_size", 10)
        button.add_theme_color_override("font_color", MUTED)
        button.add_theme_color_override("font_hover_color", GOLD)
        button.focus_mode = Control.FOCUS_NONE
        _style_button(button, PANEL_DARK, Color("#293858"))
        button.pressed.connect(func(): show_tab(key))
        nav.add_child(button)
        nav_buttons[key] = button
    _refresh_status()

func _resource_chip(symbol: String, title: String, key: String) -> Control:
    var panel := _panel(PANEL, 8, Color("#293858"))
    panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    var row := HBoxContainer.new()
    row.add_theme_constant_override("separation", 5)
    row.add_child(_label(symbol, 16, GOLD if key == "gold" else (PINK if key == "gems" else CYAN)))
    var col := VBoxContainer.new()
    col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    col.add_theme_constant_override("separation", 0)
    col.add_child(_label(title, 8, MUTED))
    var value := _label("0", 14, TEXT)
    col.add_child(value)
    row.add_child(col)
    panel.add_child(row)
    if key == "gold":
        gold_value = value
    elif key == "gems":
        gems_value = value
    else:
        stamina_value = value
    return panel

func _style_button(button: Button, fill: Color, border: Color) -> void:
    var normal := StyleBoxFlat.new()
    normal.bg_color = fill
    normal.border_color = border
    normal.set_border_width_all(1)
    normal.set_corner_radius_all(11)
    normal.set_content_margin_all(7)
    var hover := normal.duplicate() as StyleBoxFlat
    hover.bg_color = fill.lightened(0.10)
    hover.border_color = CYAN
    var pressed := normal.duplicate() as StyleBoxFlat
    pressed.bg_color = fill.darkened(0.08)
    pressed.border_color = GOLD
    button.add_theme_stylebox_override("normal", normal)
    button.add_theme_stylebox_override("hover", hover)
    button.add_theme_stylebox_override("pressed", pressed)
    button.add_theme_stylebox_override("focus", normal)

func _portrait(slug: String, width: float, height: float) -> TextureRect:
    var portrait := TextureRect.new()
    portrait.custom_minimum_size = Vector2(width, height)
    portrait.texture = load("res://art/%s.svg" % slug)
    portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
    portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
    return portrait

func _hero_card() -> Control:
    var hero := Control.new()
    hero.custom_minimum_size = Vector2(0, 258)
    hero.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    hero.clip_contents = true
    var art := TextureRect.new()
    art.texture = load("res://art/sanctuary.svg")
    art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    art.stretch_mode = TextureRect.STRETCH_SCALE
    art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    art.mouse_filter = Control.MOUSE_FILTER_IGNORE
    hero.add_child(art)
    var shade := ColorRect.new()
    shade.color = Color(0.025, 0.04, 0.13, 0.42)
    shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
    hero.add_child(shade)
    var margin := MarginContainer.new()
    margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    margin.add_theme_constant_override("margin_left", 16)
    margin.add_theme_constant_override("margin_right", 16)
    margin.add_theme_constant_override("margin_top", 14)
    margin.add_theme_constant_override("margin_bottom", 13)
    margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
    hero.add_child(margin)
    var col := VBoxContainer.new()
    col.add_theme_constant_override("separation", 5)
    margin.add_child(col)
    col.add_child(_label("CHAPTER 01   •   THE STARFALL", 9, CYAN))
    col.add_child(_label("A world written\nin the stars", 26, TEXT))
    col.add_child(_label("Find your companions. Build a home.\nChoose your path beyond the Veil.", 12, Color("#e4e8ff")))
    var spacer := Control.new()
    spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
    col.add_child(spacer)
    col.add_child(_button("OPEN STORY  ›", func(): show_tab("Events"), 39))
    return hero

func _featured_companion(member: Dictionary) -> Control:
    var card := _panel(PANEL, 6, member.get("color", CYAN))
    card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    var col := VBoxContainer.new()
    col.add_theme_constant_override("separation", 4)
    card.add_child(col)
    var portrait := _portrait(str(member.get("slug", "airi")), 90, 112)
    portrait.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    col.add_child(portrait)
    var short_name := str(member.get("name", "Companion")).split(",")[0].split(" of the ")[0]
    col.add_child(_label(short_name, 10, TEXT))
    col.add_child(_label("%s · Lv.%d" % [member.get("rarity", "R"), int(member.get("level", 1))], 9, member.get("color", CYAN)))
    return card

func _shortcut(symbol: String, title: String, desc: String, action: Callable, accent: Color) -> Control:
    var holder := Control.new()
    holder.custom_minimum_size = Vector2(0, 108)
    holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    var panel := _panel(PANEL_ALT, 9, Color("#354469"))
    panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    holder.add_child(panel)
    var margin := MarginContainer.new()
    margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    margin.add_theme_constant_override("margin_left", 10)
    margin.add_theme_constant_override("margin_right", 10)
    margin.add_theme_constant_override("margin_top", 8)
    margin.add_theme_constant_override("margin_bottom", 8)
    margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
    holder.add_child(margin)
    var col := VBoxContainer.new()
    col.add_theme_constant_override("separation", 3)
    margin.add_child(col)
    col.add_child(_label(symbol, 20, accent))
    col.add_child(_label(title, 11, TEXT))
    col.add_child(_label(desc, 10, MUTED))
    var cover := Button.new()
    cover.text = ""
    cover.flat = true
    cover.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    cover.pressed.connect(action)
    holder.add_child(cover)
    return holder

func _panel(fill: Color = PANEL, padding: int = 12, border: Color = Color("#293858")) -> PanelContainer:
    var panel := PanelContainer.new()
    var style := StyleBoxFlat.new()
    style.bg_color = fill
    style.border_color = border
    style.set_border_width_all(1)
    style.set_corner_radius_all(16)
    style.set_content_margin_all(padding)
    style.shadow_color = Color(0, 0, 0, 0.18)
    style.shadow_size = 3
    panel.add_theme_stylebox_override("panel", style)
    return panel

func _label(text: String, size: int = 16, color: Color = Color.WHITE) -> Label:
    var l := Label.new()
    l.text = text
    l.add_theme_font_size_override("font_size", size)
    l.add_theme_color_override("font_color", color)
    l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    return l

func _button(text: String, action: Callable, min_y: int = 46) -> Button:
    var button := Button.new()
    button.text = text
    button.custom_minimum_size.y = min_y
    button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    button.add_theme_font_size_override("font_size", 12)
    button.add_theme_color_override("font_color", TEXT)
    button.add_theme_color_override("font_hover_color", GOLD)
    button.focus_mode = Control.FOCUS_NONE
    _style_button(button, PANEL_ALT, Color("#3a4e76"))
    button.pressed.connect(action)
    return button

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
        nav_buttons[key].add_theme_color_override("font_color", GOLD if key == tab else MUTED)
        nav_buttons[key].modulate = Color.WHITE if key == tab else Color(0.86, 0.9, 1.0, 1.0)
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
    content.add_child(_hero_card())
    var greeting := HBoxContainer.new()
    greeting.add_theme_constant_override("separation", 7)
    var greeting_col := VBoxContainer.new()
    greeting_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    greeting_col.add_child(_label("GOOD TO SEE YOU, WAYFARER", 9, CYAN))
    greeting_col.add_child(_label("Your journey continues", 18, TEXT))
    greeting.add_child(greeting_col)
    var badge := _panel(PANEL_ALT, 7, Color("#354469"))
    badge.add_child(_label("SANCTUARY  Lv.%d" % village_level, 9, GOLD))
    greeting.add_child(badge)
    content.add_child(greeting)

    var daily := _panel(PANEL, 9, Color("#3b456a"))
    var daily_row := HBoxContainer.new()
    daily_row.add_theme_constant_override("separation", 8)
    daily.add_child(daily_row)
    daily_row.add_child(_portrait("sena", 61, 74))
    var daily_text := VBoxContainer.new()
    daily_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    daily_text.add_child(_label("DAILY BLESSING", 9, GOLD))
    daily_text.add_child(_label("A gift from the Celestial Archive", 11, TEXT))
    daily_text.add_child(_label("120 gold  ·  15 gems", 10, MUTED))
    daily_row.add_child(daily_text)
    daily_row.add_child(_button("CLAIM", _claim_daily, 39))
    content.add_child(daily)

    var stats := HBoxContainer.new()
    stats.add_theme_constant_override("separation", 6)
    stats.add_child(_stat_card("COMPANIONS", str(roster.size()), "in your circle", CYAN))
    stats.add_child(_stat_card("TEAM POWER", str(_team_power()), "party strength", GOLD))
    stats.add_child(_stat_card("DAY", "%02d" % day, "your story", PINK))
    content.add_child(stats)

    _section("YOUR COMPANIONS", "The people who make this world feel like home.")
    var featured := HBoxContainer.new()
    featured.add_theme_constant_override("separation", 7)
    content.add_child(featured)
    var shown := 0
    for member in roster:
        if shown >= 3:
            break
        featured.add_child(_featured_companion(member))
        shown += 1

    _section("SET OUT", "Choose your next step.")
    var shortcuts := GridContainer.new()
    shortcuts.columns = 2
    shortcuts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    shortcuts.add_theme_constant_override("h_separation", 7)
    shortcuts.add_theme_constant_override("v_separation", 7)
    content.add_child(shortcuts)
    shortcuts.add_child(_shortcut("⚔", "EXPEDITIONS", "Find treasure and stories", func(): show_tab("Expeditions"), CYAN))
    shortcuts.add_child(_shortcut("✦", "ASTRAL ARCHIVE", "Recruit a new companion", func(): show_tab("Summon"), PINK))
    shortcuts.add_child(_shortcut("⌂", "HEARTHVALE", "Build your little town", func(): show_tab("Village"), GREEN))
    shortcuts.add_child(_shortcut("✧", "STARFALL DISPATCH", "Play the story event", func(): show_tab("Events"), GOLD))

    var commission := _panel(PANEL_DARK, 10, Color("#293858"))
    var commission_col := VBoxContainer.new()
    commission_col.add_child(_label("WAYFARER'S COMMISSION", 9, CYAN))
    commission_col.add_child(_label("Complete an expedition · %s" % ("1/1" if battle_log != "" else "0/1"), 12, TEXT))
    commission_col.add_child(_label("Reward: 80 gold + 20 gems", 10, MUTED))
    commission.add_child(commission_col)
    content.add_child(commission)
    content.add_child(_button("REST UNTIL DAY %02d  ·  COLLECT VILLAGE INCOME" % (day + 1), _next_day, 43))

func _stat_card(title: String, value: String, caption: String, accent: Color) -> Control:
    var panel := _panel(PANEL, 9, Color("#293858"))
    panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    var col := VBoxContainer.new()
    col.add_theme_constant_override("separation", 3)
    col.add_child(_label(title, 8, MUTED))
    col.add_child(_label(value, 20, accent))
    col.add_child(_label(caption, 9, MUTED))
    panel.add_child(col)
    return panel

func _show_summon() -> void:
    _section("THE CELESTIAL ARCHIVE", "Call a new star into your story.")
    var banner := _panel(PANEL, 9, Color("#47647f"))
    content.add_child(banner)
    var row := HBoxContainer.new()
    row.add_theme_constant_override("separation", 10)
    banner.add_child(row)
    row.add_child(_portrait("airi", 123, 168))
    var info := VBoxContainer.new()
    info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    info.add_child(_label("LIMITED MEMORY", 9, CYAN))
    info.add_child(_label("THE TIDE\nREMEMBERS", 17, GOLD))
    info.add_child(_label("Featured: Airi of the Glass Tide", 11, TEXT))
    info.add_child(_label("A blade that dances with the sea between worlds.", 10, MUTED))
    info.add_child(_label("SSR 4%  ·  SR 26%  ·  R 70%", 10, PINK))
    info.add_child(_label("Pity: %d / 10" % (pull_count % 10), 10, CYAN))
    row.add_child(info)
    content.add_child(_button("✦  SUMMON ONCE  ·  100 GEMS", func(): _summon(1), 46))
    content.add_child(_button("✦  SUMMON TEN  ·  900 GEMS", func(): _summon(10), 46))
    var note := _panel(PANEL_DARK, 10, Color("#293858"))
    var note_col := VBoxContainer.new()
    note_col.add_child(_label("ARCHIVE NOTES", 9, CYAN))
    note_col.add_child(_label("At least one SR or higher is guaranteed every 10 summons. Duplicates grant Bond and 15 gems.", 11, MUTED))
    note.add_child(note_col)
    content.add_child(note)

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
    _section("YOUR CONSTELLATION", "Meet your companions, train them, and grow their bonds.")
    var party := _panel(PANEL_ALT, 11, Color("#3c5978"))
    var party_col := VBoxContainer.new()
    party_col.add_theme_constant_override("separation", 4)
    party_col.add_child(_label("YOUR EXPEDITION CREW", 10, CYAN))
    party_col.add_child(_label("Team power  %d" % _team_power(), 16, GOLD))
    party_col.add_child(_label("Your first three companions travel together.", 11, MUTED))
    party.add_child(party_col)
    content.add_child(party)
    if roster.is_empty():
        content.add_child(_button("VISIT THE ASTRAL ARCHIVE", func(): show_tab("Summon"), 45))
        return
    for member in roster:
        var card := _panel(PANEL, 9, member.get("color", Color("#35466c")))
        content.add_child(card)
        var row := HBoxContainer.new()
        row.add_theme_constant_override("separation", 9)
        card.add_child(row)
        row.add_child(_portrait(str(member.get("slug", "airi")), 96, 126))
        var info := VBoxContainer.new()
        info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        info.add_theme_constant_override("separation", 4)
        var rarity_color: Color = GOLD if member["rarity"] == "SSR" else (PINK if member["rarity"] == "SR" else MUTED)
        info.add_child(_label(str(member["name"]), 13, rarity_color))
        info.add_child(_label("%s  ·  %s" % [member["rarity"], member["role"]], 10, member.get("color", CYAN)))
        info.add_child(_label("%s element  ·  Power %d" % [member["element"], int(member["power"]) + (int(member["level"]) - 1) * 8], 10, MUTED))
        info.add_child(_label("Lv.%d  ·  Copies %d  ·  Bond %d" % [member["level"], member["copies"], member["bond"]], 9, CYAN))
        info.add_child(_label(str(member["skill"]), 10, TEXT))
        row.add_child(info)
        row.add_child(_button("TRAIN\n80 G", func(): _train(member), 46))

func _train(member: Dictionary) -> void:
    if gold < 80:
        _notice("Not enough gold.")
        return
    gold -= 80
    member["level"] += 1
    member["bond"] += 2
    show_tab("Roster")

func _show_expeditions() -> void:
    _section("BEYOND THE VEIL", "Choose a route. Your crew fights together.")
    var crew := _panel(PANEL_ALT, 10, Color("#3d5a7a"))
    var crew_col := VBoxContainer.new()
    crew_col.add_child(_label("YOUR CREW  ·  POWER %d" % _team_power(), 15, GOLD))
    crew_col.add_child(_label("Strikers hit hard. Supports create combos. Guardians reduce danger.", 11, MUTED))
    crew.add_child(crew_col)
    content.add_child(crew)
    var routes := [
        {"name":"Glass Orchard","desc":"Crystal branches hum with lost memories.","cost":3,"hp":90,"gold":140,"gems":25,"color":CYAN},
        {"name":"Lantern-Rail Ruins","desc":"An abandoned sky-train follows the old moon route.","cost":5,"hp":155,"gold":240,"gems":40,"color":PINK},
        {"name":"Quiet Observatory","desc":"Something stirs beneath a telescope pointed at tomorrow.","cost":7,"hp":240,"gold":380,"gems":60,"color":GOLD}
    ]
    var index := 1
    for route in routes:
        var card := _panel(PANEL, 10, Color("#354766"))
        var col := VBoxContainer.new()
        col.add_theme_constant_override("separation", 5)
        col.add_child(_label("ROUTE %02d" % index, 9, route["color"]))
        col.add_child(_label(str(route["name"]), 16, TEXT))
        col.add_child(_label(str(route["desc"]), 11, MUTED))
        col.add_child(_label("ϟ %d stamina   ·   ✧ %d gold   ·   ◆ %d gems" % [route["cost"], route["gold"], route["gems"]], 10, CYAN))
        var action := Callable(self, "_start_battle").bind(str(route["name"]), int(route["cost"]), int(route["hp"]), int(route["gold"]), int(route["gems"]))
        col.add_child(_button("DEPART  ›", action, 40))
        card.add_child(col)
        content.add_child(card)
        index += 1
    if battle_log != "":
        var report := _panel(PANEL_DARK, 10, Color("#35466c"))
        var report_col := VBoxContainer.new()
        report_col.add_child(_label("LAST FIELD REPORT", 10, CYAN))
        report_col.add_child(_label(battle_log, 11, MUTED))
        report.add_child(report_col)
        content.add_child(report)

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
    var team_damage: int = maxi(18, int(power * 0.31))
    while hp > 0 and rounds < 8:
        rounds += 1
        var damage: int = team_damage + randi_range(-8, 12)
        if rounds == 2 and _has_role("Support"):
            damage += 15
            lines.append("Mira reads the wind: team combo +15 damage.")
        if rounds == 3 and _has_role("Guardian"):
            lines.append("Toma anchors the line; the team avoids a counterattack.")
        hp -= damage
        lines.append("Round %d: your crew deals %d damage." % [rounds, damage])
        if hp > 0:
            var incoming: int = maxi(4, 18 - int(power * 0.025))
            if _has_role("Guardian"):
                incoming = maxi(2, incoming - 5)
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
    _section("STARFALL DISPATCH", "A story event about the people who keep the village bright.")
    var story := _panel(PANEL, 8, Color("#624b80"))
    var col := VBoxContainer.new()
    col.add_theme_constant_override("separation", 6)
    var art := TextureRect.new()
    art.texture = load("res://art/festival.svg")
    art.custom_minimum_size = Vector2(0, 150)
    art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
    col.add_child(art)
    col.add_child(_label("THE PAPER MOON FESTIVAL", 14, PINK))
    col.add_child(_label("The lanterns of Hearthvale are losing their light. Mira believes the travelling troupe can rekindle them — but the oldest shrine has begun to answer back.", 12, TEXT))
    col.add_child(_label("Choose kindness, gather the village, and keep the paper moon aloft.", 11, MUTED))
    story.add_child(col)
    content.add_child(story)
    if not event_claimed:
        content.add_child(_button("HELP THE TROUPE  ·  CLAIM 120 GOLD + 30 GEMS", _claim_event, 46))
    else:
        var done := _panel(PANEL_ALT, 10, Color("#456c65"))
        var done_col := VBoxContainer.new()
        done_col.add_child(_label("✦  CHAPTER COMPLETE", 13, GREEN))
        done_col.add_child(_label("The lanterns are glowing again. The troupe left a paper star for you.", 11, MUTED))
        done.add_child(done_col)
        content.add_child(done)
    content.add_child(_button("BACK TO SANCTUARY", func(): show_tab("Sanctuary"), 42))

func _claim_event() -> void:
    event_claimed = true
    gold += 120
    gems += 30
    _refresh_status()
    show_tab("Events")

func _show_ranks() -> void:
    _section("THE CONSTELLATION BOARD", "Local practice rankings. Online rankings need a game server.")
    var rivals := [
        {"name":"VelvetComet","power":4120,"rank":1},
        {"name":"MikoAfterRain","power":3760,"rank":2},
        {"name":"CloudTea","power":3490,"rank":3},
        {"name":"RinOfTheNorth","power":3020,"rank":4}
    ]
    for rival in rivals:
        var panel := _panel(PANEL, 10, Color("#303f61"))
        var row := HBoxContainer.new()
        row.add_child(_label("#%d" % rival["rank"], 22, GOLD))
        var info := VBoxContainer.new()
        info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        info.add_child(_label(str(rival["name"]), 14, TEXT))
        info.add_child(_label("Constellation Power %d" % rival["power"], 11, MUTED))
        row.add_child(info)
        panel.add_child(row)
        content.add_child(panel)
    var own := _panel(PANEL_ALT, 10, Color("#47717a"))
    var own_col := VBoxContainer.new()
    own_col.add_child(_label("#%d  ·  YOU" % (5 if _team_power() < 3500 else 3), 15, CYAN))
    own_col.add_child(_label("Crew power %d · %d companions · Town Lv.%d" % [_team_power(), roster.size(), village_level], 11, MUTED))
    own.add_child(own_col)
    content.add_child(own)

func _claim_daily() -> void:
    if daily_claimed:
        _notice("Today's blessing has already been claimed. Return after the next dawn.")
        return
    daily_claimed = true
    gold += 120
    gems += 15
    stamina = mini(12 + (_building_level("Wayfarer Hall") - 1) * 3, stamina + 3)
    _refresh_status()
    show_tab("Sanctuary")

func _next_day() -> void:
    day += 1
    daily_claimed = false
    stamina = min(12 + (_building_level("Wayfarer Hall") - 1) * 3, stamina + 8 + (_building_level("Wayfarer Hall") - 1) * 3)
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
    if is_instance_valid(gold_value):
        gold_value.text = str(gold)
    if is_instance_valid(gems_value):
        gems_value.text = str(gems)
    if is_instance_valid(stamina_value):
        stamina_value.text = "%d/%d" % [stamina, 12 + (_building_level("Wayfarer Hall") - 1) * 3]
    if is_instance_valid(day_label):
        day_label.text = "%02d" % day

func _notice(message: String) -> void:
    var dialog := AcceptDialog.new()
    dialog.dialog_text = message
    add_child(dialog)
    dialog.confirmed.connect(func(): dialog.queue_free())
    dialog.popup_centered(Vector2i(440, 180))

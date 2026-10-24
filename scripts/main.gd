extends Control
# NEBULIA — village-management RPG prototype inspired by the idle town-building loop
# of anime fantasy life sims. Original characters/art; not a copy of proprietary assets.

var gold := 250
var food := 80
var wood := 60
var town_level := 1
var total_income := 0
var selected_tab := "village"
var selected_character := ""
var buildings := [
    {"name":"Трактир «Лунный мёд»","icon":"🍯","level":1,"income":12,"cost":80,"desc":"Приносит золото каждые несколько секунд."},
    {"name":"Ферма у реки","icon":"🌾","level":1,"income":8,"cost":60,"desc":"Производит еду для жителей."},
    {"name":"Мастерская","icon":"🪵","level":1,"income":5,"cost":50,"desc":"Постепенно производит древесину."}
]
var characters := [
    {"name":"Элиана","role":"Хозяйка деревни","rarity":"SSR","level":1,"affection":12,"hair":"Серебряные волосы · голубые глаза","bio":"Добрая и внимательная. Мечтает превратить Линден в уютный город, куда путешественники захотят возвращаться."},
    {"name":"Лиара","role":"Лесная охотница","rarity":"SR","level":1,"affection":5,"hair":"Рыжие волосы · зелёные глаза","bio":"Смелая и независимая. Находит редкие материалы и знает безопасные тропы через лес."}
]
var quests := [
    {"title":"Добро пожаловать в Линден","desc":"Улучши любое здание до 2 уровня.","reward":100,"done":false},
    {"title":"Первые запасы","desc":"Собери 100 золота с построек.","reward":60,"done":false},
    {"title":"Новые знакомства","desc":"Открой профиль Элианы и Лиары.","reward":40,"done":false}
]
var ui_root: VBoxContainer
var header_label: Label
var resources_label: Label
var content: VBoxContainer
var toast_label: Label
var toast_timer := 0.0
var elapsed := 0.0
var viewed_both := false
var income_notice_shown := false
var save_elapsed := 0.0

func _ready() -> void:
    _load_game()
    _build_interface()
    _show_tab("village")
    _refresh_header()

func _notification(what: int) -> void:
    if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_PREDELETE:
        _save_game()

func _save_game() -> void:
    var data := ConfigFile.new()
    data.set_value("resources", "gold", gold)
    data.set_value("resources", "food", food)
    data.set_value("resources", "wood", wood)
    data.set_value("resources", "town_level", town_level)
    data.set_value("resources", "total_income", total_income)
    data.set_value("progress", "viewed_both", viewed_both)
    data.set_value("progress", "income_notice_shown", income_notice_shown)
    data.set_value("buildings", "items", buildings)
    data.set_value("characters", "items", characters)
    data.set_value("quests", "items", quests)
    data.save("user://nebulia_save.cfg")

func _load_game() -> void:
    var data := ConfigFile.new()
    if data.load("user://nebulia_save.cfg") != OK:
        return
    gold = int(data.get_value("resources", "gold", gold))
    food = int(data.get_value("resources", "food", food))
    wood = int(data.get_value("resources", "wood", wood))
    town_level = int(data.get_value("resources", "town_level", town_level))
    total_income = int(data.get_value("resources", "total_income", total_income))
    viewed_both = bool(data.get_value("progress", "viewed_both", viewed_both))
    income_notice_shown = bool(data.get_value("progress", "income_notice_shown", income_notice_shown))
    buildings = data.get_value("buildings", "items", buildings)
    characters = data.get_value("characters", "items", characters)
    quests = data.get_value("quests", "items", quests)

func _process(delta: float) -> void:
    elapsed += delta
    save_elapsed += delta
    if save_elapsed >= 10.0:
        save_elapsed = 0.0
        _save_game()
    toast_timer = maxf(0.0, toast_timer - delta)
    if toast_timer == 0.0:
        toast_label.text = ""
    # Idle production: buildings generate resources even while the player browses menus.
    if elapsed >= 3.0:
        elapsed = 0.0
        var income := 0
        for b in buildings:
            income += int(b["income"]) * int(b["level"])
        gold += income
        total_income += income
        food += int(buildings[1]["level"]) * 2
        wood += int(buildings[2]["level"])
        _refresh_header()
        _save_game()
        _check_quests()

func _build_interface() -> void:
    var bg := ColorRect.new()
    bg.color = Color("#101b2b")
    bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(bg)

    var margin := MarginContainer.new()
    margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    margin.add_theme_constant_override("margin_left", 24)
    margin.add_theme_constant_override("margin_right", 24)
    margin.add_theme_constant_override("margin_top", 18)
    margin.add_theme_constant_override("margin_bottom", 18)
    add_child(margin)

    ui_root = VBoxContainer.new()
    ui_root.add_theme_constant_override("separation", 12)
    margin.add_child(ui_root)

    var top := HBoxContainer.new()
    ui_root.add_child(top)
    var title := Label.new()
    title.text = "✦ NEBULIA"
    title.add_theme_font_size_override("font_size", 30)
    title.add_theme_color_override("font_color", Color("#e5d3ff"))
    title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    top.add_child(title)
    header_label = Label.new()
    header_label.add_theme_font_size_override("font_size", 17)
    header_label.add_theme_color_override("font_color", Color("#ffe6a8"))
    top.add_child(header_label)

    resources_label = Label.new()
    resources_label.add_theme_font_size_override("font_size", 18)
    resources_label.add_theme_color_override("font_color", Color("#d4e8ff"))
    ui_root.add_child(resources_label)

    var nav := HBoxContainer.new()
    nav.add_theme_constant_override("separation", 8)
    ui_root.add_child(nav)
    _button(nav, "🏡 Деревня", func(): _show_tab("village"))
    _button(nav, "💗 Персонажи", func(): _show_tab("characters"))
    _button(nav, "📜 Задания", func(): _show_tab("quests"))
    _button(nav, "🛍 Торговля", func(): _show_tab("shop"))

    var separator := ColorRect.new()
    separator.custom_minimum_size = Vector2(0, 2)
    separator.color = Color("#4b6285")
    ui_root.add_child(separator)

    content = VBoxContainer.new()
    content.size_flags_vertical = Control.SIZE_EXPAND_FILL
    content.add_theme_constant_override("separation", 10)
    ui_root.add_child(content)

    toast_label = Label.new()
    toast_label.add_theme_font_size_override("font_size", 18)
    toast_label.add_theme_color_override("font_color", Color("#ffe6a8"))
    ui_root.add_child(toast_label)

func _button(parent: Node, label: String, callback: Callable) -> Button:
    var b := Button.new()
    b.text = label
    b.custom_minimum_size = Vector2(0, 42)
    b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    b.add_theme_font_size_override("font_size", 16)
    b.pressed.connect(callback)
    parent.add_child(b)
    return b

func _panel(parent: Node) -> VBoxContainer:
    var panel := PanelContainer.new()
    panel.add_theme_stylebox_override("panel", _panel_style())
    panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    parent.add_child(panel)
    var box := VBoxContainer.new()
    box.add_theme_constant_override("separation", 6)
    panel.add_child(box)
    return box

func _panel_style() -> StyleBoxFlat:
    var s := StyleBoxFlat.new()
    s.bg_color = Color("#1b2c43")
    s.border_color = Color("#405b7d")
    s.set_border_width_all(1)
    s.set_corner_radius_all(12)
    s.content_margin_left = 14
    s.content_margin_right = 14
    s.content_margin_top = 10
    s.content_margin_bottom = 10
    return s

func _label(parent: Node, text: String, size := 17, color := "#f0f5ff") -> Label:
    var l := Label.new()
    l.text = text
    l.add_theme_font_size_override("font_size", size)
    l.add_theme_color_override("font_color", Color(color))
    l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    parent.add_child(l)
    return l

func _show_tab(tab: String) -> void:
    selected_tab = tab
    for child in content.get_children():
        child.queue_free()
    match tab:
        "village":
            _show_village()
        "characters":
            _show_characters()
        "quests":
            _show_quests()
        "shop":
            _show_shop()
    _refresh_header()

func _show_village() -> void:
    _label(content, "ЛИНДЕН — ТВОЯ ДЕРЕВНЯ", 24, "#ffe6a8")
    _label(content, "Развивай здания, собирай прибыль и приглашай героев. Постройки производят ресурсы автоматически.", 15, "#b7c9df")
    var row := HBoxContainer.new()
    row.size_flags_vertical = Control.SIZE_EXPAND_FILL
    row.add_theme_constant_override("separation", 10)
    content.add_child(row)
    for i in range(buildings.size()):
        var b: Dictionary = buildings[i]
        var card := _panel(row)
        card.size_flags_vertical = Control.SIZE_EXPAND_FILL
        _label(card, str(b["icon"]), 36)
        _label(card, str(b["name"]), 18, "#ffe6a8")
        _label(card, "Уровень "+str(b["level"]), 16, "#9fdcff")
        _label(card, str(b["desc"]), 14, "#d4e0ee")
        _label(card, "Доход: "+str(int(b["income"])*int(b["level"]))+" зол./цикл", 14, "#a9e5bd")
        _button(card, "Улучшить · "+str(b["cost"])+" зол.", _upgrade_building.bind(i))
    var hero_row := HBoxContainer.new()
    content.add_child(hero_row)
    var welcome := _panel(hero_row)
    _label(welcome, "🌙 Добро пожаловать!", 20, "#ffe6a8")
    _label(welcome, "Элиана поможет управлять деревней, а Лиара будет приносить материалы из леса.", 15)
    _button(welcome, "Познакомиться с героями", func(): _show_tab("characters"))
    var goal := _panel(hero_row)
    _label(goal, "📈 Развитие поселения", 20, "#ffe6a8")
    _label(goal, "Уровень деревни: "+str(town_level)+"\nПрибыль собрано: "+str(total_income), 16)
    _button(goal, "Посмотреть задания", func(): _show_tab("quests"))

func _show_characters() -> void:
    _label(content, "КОЛЛЕКЦИЯ ГЕРОЕВ", 24, "#ffe6a8")
    _label(content, "Выбирай героя, знакомься с его историей и повышай уровень близости.", 15, "#b7c9df")
    for i in range(characters.size()):
        var c: Dictionary = characters[i]
        var card := _panel(content)
        var row := HBoxContainer.new()
        card.add_child(row)
        var portrait := Label.new()
        portrait.text = "✧" if i == 0 else "❀"
        portrait.custom_minimum_size = Vector2(70, 70)
        portrait.add_theme_font_size_override("font_size", 48)
        portrait.add_theme_color_override("font_color", Color("#d8d7ff") if i == 0 else Color("#ffb49d"))
        row.add_child(portrait)
        var info := VBoxContainer.new()
        info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        row.add_child(info)
        _label(info, str(c["name"])+"  ·  "+str(c["rarity"]), 21, "#ffe6a8")
        _label(info, str(c["role"])+" · Ур. "+str(c["level"]), 16, "#9fdcff")
        _label(info, str(c["hair"]), 14, "#d4e0ee")
        _button(info, "Осмотреть и поговорить", _inspect_character.bind(i))
    _label(content, "Подсказка: профили открывают личные истории и отношения героев.", 14, "#9aaec6")

func _inspect_character(index: int) -> void:
    var c: Dictionary = characters[index]
    viewed_both = true
    c["affection"] = int(c["affection"]) + 1
    characters[index] = c
    for child in content.get_children():
        child.queue_free()
    var card := _panel(content)
    card.size_flags_vertical = Control.SIZE_EXPAND_FILL
    _label(card, "✦ "+str(c["name"])+" ✦", 30, "#ffe6a8")
    _label(card, str(c["role"])+"  ·  "+str(c["rarity"]), 18, "#9fdcff")
    _label(card, "Уровень: "+str(c["level"])+"     Близость: "+str(c["affection"])+"/100", 17, "#f2c7ff")
    var portrait := Label.new()
    portrait.text = "◕‿◕" if index == 0 else "✧ᴗ✧"
    portrait.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    portrait.add_theme_font_size_override("font_size", 54)
    portrait.add_theme_color_override("font_color", Color("#e4e2ff") if index == 0 else Color("#ffc2a8"))
    card.add_child(portrait)
    _label(card, str(c["bio"]), 18)
    _label(card, "Анимация портрета и полноценные иллюстрации будут подключены отдельными художественными ресурсами; здесь работает игровой профиль.", 13, "#9aaec6")
    _button(card, "🎁 Подарить угощение · 15 зол.", func(): _gift_character(index))
    _button(card, "← Назад к героям", func(): _show_tab("characters"))
    _refresh_header()
    _check_quests()

func _gift_character(index: int) -> void:
    if gold < 15:
        _toast("Не хватает золота.")
        return
    gold -= 15
    characters[index]["affection"] = int(characters[index]["affection"]) + 5
    _toast("Близость с "+str(characters[index]["name"])+" увеличилась!")
    _inspect_character(index)

func _show_quests() -> void:
    _label(content, "ЗАДАНИЯ И НАГРАДЫ", 24, "#ffe6a8")
    _label(content, "Выполняй небольшие поручения, чтобы получать ресурсы и открывать развитие деревни.", 15, "#b7c9df")
    for i in range(quests.size()):
        var q: Dictionary = quests[i]
        var card := _panel(content)
        _label(card, ("✓ " if q["done"] else "☆ ")+str(q["title"]), 19, "#a9e5bd" if q["done"] else "#ffe6a8")
        _label(card, str(q["desc"]), 15)
        _label(card, "Награда: "+str(q["reward"])+" золота", 14, "#9fdcff")
        if not q["done"]:
            _button(card, "Проверить задание", _claim_quest.bind(i))
        else:
            _label(card, "Выполнено", 14, "#a9e5bd")

func _claim_quest(index: int) -> void:
    var q: Dictionary = quests[index]
    var ready := false
    if index == 0:
        for b in buildings:
            if int(b["level"]) >= 2:
                ready = true
    elif index == 1:
        ready = total_income >= 100
    elif index == 2:
        ready = viewed_both
    if not ready:
        _toast("Пока не выполнено. Продолжай развивать деревню!")
        return
    q["done"] = true
    quests[index] = q
    gold += int(q["reward"])
    _toast("Задание выполнено! +"+str(q["reward"])+" золота")
    _show_tab("quests")

func _check_quests() -> void:
    if quests.is_empty():
        return
    if total_income >= 100 and not quests[1]["done"] and not income_notice_shown:
        income_notice_shown = true
        _toast("Цель выполнена: накоплено 100 золота дохода!")
    _refresh_header()

func _show_shop() -> void:
    _label(content, "ТОРГОВАЯ ПЛОЩАДЬ", 24, "#ffe6a8")
    _label(content, "Потрать накопленное золото на припасы для деревни.", 15, "#b7c9df")
    var food_card := _panel(content)
    _label(food_card, "🥖 Корзина провизии", 21, "#ffe6a8")
    _label(food_card, "Покупка 25 еды за 30 золота.", 15)
    _button(food_card, "Купить провизию", func():
        if gold >= 30:
            gold -= 30
            food += 25
            _toast("Еда +25")
            _refresh_header()
        else:
            _toast("Не хватает золота.")
    )
    var wood_card := _panel(content)
    _label(wood_card, "🪵 Связка древесины", 21, "#ffe6a8")
    _label(wood_card, "Покупка 20 древесины за 25 золота.", 15)
    _button(wood_card, "Купить древесину", func():
        if gold >= 25:
            gold -= 25
            wood += 20
            _toast("Древесина +20")
            _refresh_header()
        else:
            _toast("Не хватает золота.")
    )

func _upgrade_building(index: int) -> void:
    var b: Dictionary = buildings[index]
    var cost := int(b["cost"]) * int(b["level"])
    if gold < cost:
        _toast("Не хватает золота для улучшения.")
        return
    gold -= cost
    b["level"] = int(b["level"]) + 1
    b["cost"] = int(b["cost"]) + 35
    buildings[index] = b
    town_level = 1
    for item in buildings:
        town_level += int(item["level"]) - 1
    _toast(str(b["name"])+" улучшено до уровня "+str(b["level"])+"!")
    _show_tab("village")
    _check_quests()

func _refresh_header() -> void:
    if not is_instance_valid(header_label):
        return
    header_label.text = "Деревня Ур."+str(town_level)
    resources_label.text = "🪙 "+str(gold)+"     🌾 "+str(food)+"     🪵 "+str(wood)+"     ✨ Доход каждые 3 сек."

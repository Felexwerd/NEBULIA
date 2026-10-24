extends Node2D

# NEBULIA — playable Godot 4 prototype.
# Character art is procedural placeholder art until layered anime assets/rigs are added.

var mode := "intro"
var tutorial_step := 0
var player_pos := Vector2(390, 430)
var target_pos := Vector2(390, 430)
var walk_time := 0.0
var dialogue := "Ты просыпаешься у ворот незнакомой деревни. Девушка в бело-синем плаще замечает тебя."
var dialogue_name := "Элиана"
var herbs := 0
var energy := 100
var friendship := 0
var notice_time := 0.0
var eliana_pos := Vector2(660, 405)
var liara_pos := Vector2(850, 438)
var dialogue_label: Label
var name_label: Label
var quest_label: Label
var notice_label: Label

func _ready() -> void:
    _build_ui()
    queue_redraw()

func _process(delta: float) -> void:
    walk_time += delta
    player_pos = player_pos.move_toward(target_pos, 180.0 * delta)
    if notice_time > 0.0:
        notice_time -= delta
        if notice_time <= 0.0:
            notice_label.text = ""
    queue_redraw()

func _draw() -> void:
    var size := get_viewport_rect().size
    draw_rect(Rect2(Vector2.ZERO, size), Color("#8dd5f4"))
    draw_circle(Vector2(1080, 100), 44, Color("#fff2b3"))
    draw_colored_polygon(PackedVector2Array([Vector2(0,300),Vector2(180,140),Vector2(330,290),Vector2(500,165),Vector2(700,305),Vector2(900,175),Vector2(1120,300),Vector2(1280,210),Vector2(1280,500),Vector2(0,500)]), Color("#8bb9a8"))
    draw_colored_polygon(PackedVector2Array([Vector2(0,370),Vector2(220,250),Vector2(410,370),Vector2(650,240),Vector2(850,370),Vector2(1050,260),Vector2(1280,370),Vector2(1280,560),Vector2(0,560)]), Color("#5d9d78"))
    draw_rect(Rect2(0, 460, 1280, 260), Color("#5f9b59"))
    draw_colored_polygon(PackedVector2Array([Vector2(300,720),Vector2(500,720),Vector2(760,440),Vector2(650,440)]), Color("#d9c69b"))
    draw_colored_polygon(PackedVector2Array([Vector2(0,520),Vector2(180,505),Vector2(280,560),Vector2(430,548),Vector2(570,600),Vector2(0,650)]), Color("#56c7dc"))
    _draw_house(Vector2(130, 370), Color("#e9c8a0"), Color("#8b4d50"))
    _draw_house(Vector2(1030, 340), Color("#f4d9b5"), Color("#754c62"))
    _draw_house(Vector2(890, 300), Color("#f5e5c8"), Color("#b76c55"))
    _draw_windmill(Vector2(1140, 285))
    for i in range(18):
        var x := float((i * 83 + 23) % 1260)
        var y := float(500 + (i * 37) % 190)
        draw_circle(Vector2(x,y), 3.0, Color("#fff1dc"))
        draw_circle(Vector2(x+3,y-2), 2.0, Color("#e9a9d5"))
    _draw_character(eliana_pos, "eliana", walk_time, false)
    _draw_character(liara_pos, "liara", walk_time + 1.2, false)
    _draw_character(player_pos, "player", walk_time, player_pos.distance_to(target_pos) > 3.0)
    if mode == "inspect_eliana":
        _draw_inspection("eliana")
    elif mode == "inspect_liara":
        _draw_inspection("liara")
    elif mode == "intro":
        _draw_intro_overlay()

func _draw_house(pos: Vector2, wall: Color, roof: Color) -> void:
    draw_rect(Rect2(pos.x, pos.y, 150, 120), wall)
    draw_colored_polygon(PackedVector2Array([pos+Vector2(-15,5),pos+Vector2(75,-65),pos+Vector2(165,5)]), roof)
    draw_rect(Rect2(pos.x+58,pos.y+60,34,60), Color("#754b42"))
    draw_rect(Rect2(pos.x+17,pos.y+28,28,27), Color("#9de4ed"))
    draw_rect(Rect2(pos.x+105,pos.y+28,28,27), Color("#9de4ed"))

func _draw_windmill(pos: Vector2) -> void:
    draw_rect(Rect2(pos.x-15,pos.y,30,100),Color("#e8d8b7"))
    draw_circle(pos,7,Color("#f7e5b6"))
    for a in [0.0, PI/2, PI, PI*1.5]:
        var end := pos + Vector2(cos(a),sin(a))*65
        draw_line(pos,end,Color("#f8f1de"),7)
        draw_line(end,end+Vector2(cos(a+0.5),sin(a+0.5))*18,Color("#8a6b5d"),4)

func _draw_character(pos: Vector2, kind: String, t: float, walking: bool) -> void:
    var bob := sin(t*3.0)*3.0
    var sway := sin(t*1.7)*2.0
    var p := pos + Vector2(0,bob)
    var hair := Color("#e8e9f6")
    var outfit := Color("#e7f2ff")
    var skin := Color("#ffe0d2")
    if kind == "liara":
        hair = Color("#d75b37")
        outfit = Color("#754b38")
    elif kind == "player":
        hair = Color("#263449")
        outfit = Color("#30394f")
        skin = Color("#f1c9b5")
    _draw_ellipse(p+Vector2(0,54),Vector2(28,8),Color(0,0,0,0.18))
    var leg_swing := sin(t*8.0)*2.0 if walking else 0.0
    draw_line(p+Vector2(-8,28),p+Vector2(-12+leg_swing,48),Color("#3a4050"),7)
    draw_line(p+Vector2(8,28),p+Vector2(12-leg_swing,48),Color("#3a4050"),7)
    draw_colored_polygon(PackedVector2Array([p+Vector2(-17,0),p+Vector2(16,0),p+Vector2(27,38),p+Vector2(-25,38)]), outfit)
    if kind == "eliana":
        draw_line(p+Vector2(-17,6),p+Vector2(-27,27+sway),Color("#e7f2ff"),9)
        draw_line(p+Vector2(17,6),p+Vector2(26,24-sway),Color("#e7f2ff"),9)
        draw_line(p+Vector2(-4,4),p+Vector2(5,35),Color("#c4a35b"),2)
    elif kind == "liara":
        draw_line(p+Vector2(-17,5),p+Vector2(-27,28+sway),Color("#d75b37"),8)
        draw_line(p+Vector2(17,5),p+Vector2(25,25-sway),Color("#d75b37"),8)
        draw_line(p+Vector2(-12,17),p+Vector2(12,17),Color("#d3a15f"),3)
    draw_rect(Rect2(p.x-5,p.y-11,10,13),skin)
    draw_circle(p+Vector2(0,-22),17,skin)
    draw_arc(p+Vector2(0,-23),18,PI,TAU,24,hair,9)
    draw_colored_polygon(PackedVector2Array([p+Vector2(-17,-23),p+Vector2(-14,-39),p+Vector2(0,-43),p+Vector2(16,-35),p+Vector2(15,-23),p+Vector2(5,-31),p+Vector2(-4,-25)]),hair)
    if kind == "eliana":
        draw_line(p+Vector2(-15,-21),p+Vector2(-20,4+sway),hair,7)
        draw_line(p+Vector2(15,-21),p+Vector2(20,3-sway),hair,7)
    elif kind == "liara":
        draw_line(p+Vector2(-14,-20),p+Vector2(-25,0+sway),hair,7)
        draw_line(p+Vector2(14,-20),p+Vector2(23,-2-sway),hair,7)
    var blink := fposmod(t,4.0) > 3.86
    for ex in [-6,6]:
        if blink:
            draw_line(p+Vector2(ex-2,-22),p+Vector2(ex+2,-22),Color("#3a4050"),2)
        else:
            var eye_color := Color("#4a8fc1") if kind=="eliana" else (Color("#5b9d68") if kind=="liara" else Color("#5d799a"))
            _draw_ellipse(p+Vector2(ex,-22),Vector2(2.8,4.0),eye_color)
    draw_line(p+Vector2(-3,-12),p+Vector2(3,-12),Color("#bd7778"),1)
    var label := "Элиана" if kind=="eliana" else ("Лиара" if kind=="liara" else "Ты")
    draw_string(ThemeDB.fallback_font, p+Vector2(-27,70), label, HORIZONTAL_ALIGNMENT_CENTER, 80, 16, Color("#ffffff"))

func _draw_ellipse(center: Vector2, radii: Vector2, color: Color) -> void:
    draw_set_transform(center, 0.0, radii)
    draw_circle(Vector2.ZERO,1,color)
    draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_inspection(kind: String) -> void:
    draw_rect(Rect2(0,0,1280,720),Color(0.02,0.04,0.10,0.72))
    draw_rect(Rect2(340,55,600,610),Color("#152b45"))
    draw_rect(Rect2(350,65,580,590),Color("#203d5b"))
    var char_name := "Элиана" if kind=="eliana" else "Лиара"
    var title := "Помощница деревни" if kind=="eliana" else "Охотница и собирательница"
    var desc := "Добрая и заботливая. Она поможет тебе освоиться в новом мире." if kind=="eliana" else "Смелая и независимая. Знает лесные тропы и лучшие места для сбора трав."
    draw_string(ThemeDB.fallback_font,Vector2(390,125),char_name,HORIZONTAL_ALIGNMENT_LEFT,500,36,Color("#fff1c9"))
    draw_string(ThemeDB.fallback_font,Vector2(390,160),title,HORIZONTAL_ALIGNMENT_LEFT,500,20,Color("#8edbff"))
    _draw_character(Vector2(640,350),kind,walk_time,false)
    draw_string(ThemeDB.fallback_font,Vector2(390,520),desc,HORIZONTAL_ALIGNMENT_LEFT,500,19,Color("#f1f5fb"))
    draw_string(ThemeDB.fallback_font,Vector2(390,570),"Отношение: "+str(friendship)+"/100",HORIZONTAL_ALIGNMENT_LEFT,400,19,Color("#f5d88d"))
    draw_string(ThemeDB.fallback_font,Vector2(390,610),"Ожидание • моргание • лёгкое движение",HORIZONTAL_ALIGNMENT_LEFT,500,15,Color("#a9c5dc"))

func _draw_intro_overlay() -> void:
    draw_rect(Rect2(25,25,510,118),Color(0.03,0.08,0.15,0.86))
    draw_string(ThemeDB.fallback_font,Vector2(48,62),"NEBULIA",HORIZONTAL_ALIGNMENT_LEFT,450,32,Color("#d8efff"))
    draw_string(ThemeDB.fallback_font,Vector2(48,92),"Глава 1 · Новая жизнь",HORIZONTAL_ALIGNMENT_LEFT,450,20,Color("#f6dca0"))
    draw_string(ThemeDB.fallback_font,Vector2(48,122),"Нажми «Начать», чтобы пройти обучение",HORIZONTAL_ALIGNMENT_LEFT,470,17,Color("#ffffff"))

func _build_ui() -> void:
    var layer := CanvasLayer.new()
    add_child(layer)
    var root := Control.new()
    root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    layer.add_child(root)
    var top := PanelContainer.new()
    top.position = Vector2(20,155)
    top.size = Vector2(280,95)
    root.add_child(top)
    var top_box := VBoxContainer.new()
    top.add_child(top_box)
    var stats := Label.new()
    stats.text = "✦ День 1   ♥ Энергия 100\nМонеты: 0   Травы: 0"
    stats.add_theme_font_size_override("font_size",18)
    top_box.add_child(stats)
    quest_label = Label.new()
    quest_label.text = "Задание: поговори с Элианой"
    quest_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    top_box.add_child(quest_label)
    var bottom := PanelContainer.new()
    bottom.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
    bottom.position = Vector2(18,-165)
    bottom.size = Vector2(1244,145)
    root.add_child(bottom)
    var box := VBoxContainer.new()
    bottom.add_child(box)
    name_label = Label.new()
    name_label.text = dialogue_name
    name_label.add_theme_color_override("font_color",Color("#f4d58d"))
    name_label.add_theme_font_size_override("font_size",20)
    box.add_child(name_label)
    dialogue_label = Label.new()
    dialogue_label.text = dialogue
    dialogue_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    dialogue_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
    dialogue_label.add_theme_font_size_override("font_size",17)
    box.add_child(dialogue_label)
    var row := HBoxContainer.new()
    box.add_child(row)
    _add_button(row,"Начать",_start_tutorial)
    _add_button(row,"Продолжить",_next_tutorial)
    _add_button(row,"Осмотреть Элиану",func(): _inspect("eliana"))
    _add_button(row,"Осмотреть Лиару",func(): _inspect("liara"))
    _add_button(row,"Собрать травы",_gather)
    _add_button(row,"Закрыть осмотр",_close_inspection)
    notice_label = Label.new()
    notice_label.position = Vector2(500,155)
    notice_label.add_theme_font_size_override("font_size",22)
    notice_label.add_theme_color_override("font_color",Color("#fff0b8"))
    root.add_child(notice_label)

func _add_button(parent: HBoxContainer, text: String, callback: Callable) -> void:
    var button := Button.new()
    button.text = text
    button.pressed.connect(callback)
    parent.add_child(button)

func _start_tutorial() -> void:
    mode = "village"
    tutorial_step = 0
    dialogue_name = "Элиана"
    dialogue = "Привет! Я Элиана. Ты выглядишь потерянным. Добро пожаловать в Линден! Давай я покажу тебе деревню."
    _refresh_dialogue()
    _toast("Обучение началось")

func _next_tutorial() -> void:
    mode = "village"
    tutorial_step += 1
    match tutorial_step:
        1:
            dialogue_name = "Элиана"
            dialogue = "Попробуй переместиться: коснись свободной точки на земле. Герой пойдёт к ней."
            quest_label.text = "Обучение 1/3: коснись земли, чтобы пройтись"
        2:
            dialogue_name = "Элиана"
            dialogue = "Нажми «Собрать травы», чтобы получить ресурс для первых поручений."
            quest_label.text = "Обучение 2/3: собери травы"
        3:
            dialogue_name = "Элиана"
            dialogue = "Теперь осмотри меня или Лиару. У героев будут личные истории, подарки и развиваемые отношения."
            quest_label.text = "Обучение 3/3: осмотри персонажа"
        _:
            dialogue_name = "Элиана"
            dialogue = "Обучение завершено! Исследуй деревню, собирай ресурсы и знакомься с жителями."
            quest_label.text = "Основное задание: помоги жителям Линдена"
            _toast("Обучение завершено · Свободная игра открыта")
    _refresh_dialogue()

func _gather() -> void:
    if mode.begins_with("inspect"):
        return
    herbs += 1
    energy = max(0,energy-3)
    dialogue_name = "Система"
    dialogue = "Ты собрал душистые травы. Позже их можно будет отдать лекарю или использовать в ремесле."
    quest_label.text = "Травы: "+str(herbs)+"   Энергия: "+str(energy)
    friendship = min(100,friendship+1)
    _refresh_dialogue()
    _toast("Травы +1")

func _inspect(kind: String) -> void:
    mode = "inspect_"+kind
    dialogue_name = "Осмотр персонажа"
    dialogue = "Персонаж слегка покачивается и моргает. Закрой осмотр, чтобы вернуться в деревню."
    _refresh_dialogue()

func _close_inspection() -> void:
    mode = "village"
    _refresh_dialogue()

func _refresh_dialogue() -> void:
    name_label.text = dialogue_name
    dialogue_label.text = dialogue
    queue_redraw()

func _toast(message: String) -> void:
    notice_label.text = message
    notice_time = 2.0

func _input(event: InputEvent) -> void:
    if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
        if mode.begins_with("inspect") or mode == "intro":
            return
        var point := event.position
        if point.y < 530 and point.x > 300:
            target_pos = Vector2(clamp(point.x,330,960),clamp(point.y,370,570))
    elif event is InputEventScreenTouch and event.pressed:
        if mode.begins_with("inspect") or mode == "intro":
            return
        target_pos = Vector2(clamp(event.position.x,330,960),clamp(event.position.y,370,570))

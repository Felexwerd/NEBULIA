extends Node2D

var hero := Vector2(360, 830)
var target := Vector2(360, 830)
var selected_building := -1
var popup := false
var gold := 1250
var crystals := 18
var level := 3
var day_phase := 0.0
var active_tab := "village"
var toast := ""
var toast_time := 0.0
var buildings := [
	{"name":"Moonlit Inn","sub":"TAVERN  ·  Lv. 2","pos":Vector2(180, 470),"color":Color("#d98958"),"roof":Color("#8c3d63"),"income":35,"icon":"✦"},
	{"name":"Starlight Farm","sub":"FARM  ·  Lv. 1","pos":Vector2(535, 510),"color":Color("#d8b778"),"roof":Color("#5c9b70"),"income":18,"icon":"✿"},
	{"name":"Astral Forge","sub":"WORKSHOP  ·  Lv. 1","pos":Vector2(170, 690),"color":Color("#a8a4c9"),"roof":Color("#555b91"),"income":22,"icon":"⚒"},
	{"name":"Luna Apothecary","sub":"ALCHEMY  ·  Lv. 1","pos":Vector2(535, 700),"color":Color("#b6d8ca"),"roof":Color("#548e99"),"income":28,"icon":"✧"}
]
var characters := [
	{"name":"Liora","role":"Village Keeper","color":Color("#f4c6d8"),"hair":Color("#d982ad"),"level":4},
	{"name":"Kael","role":"Wandering Knight","color":Color("#c8d8f8"),"hair":Color("#52689c"),"level":3},
	{"name":"Meiri","role":"Forest Alchemist","color":Color("#d0f0c9"),"hair":Color("#6eaa7b"),"level":2},
	{"name":"Celestra","role":"Star Mage","color":Color("#e0d1ff"),"hair":Color("#9879d4"),"level":1}
]

func _ready() -> void:
	get_viewport().size_changed.connect(queue_redraw)
	queue_redraw()

func _process(delta: float) -> void:
	day_phase += delta
	hero = hero.lerp(target, min(delta * 5.5, 1.0))
	if toast_time > 0.0:
		toast_time -= delta
		queue_redraw()
	if hero.distance_to(target) > 1.0:
		queue_redraw()

func _draw() -> void:
	var size := get_viewport_rect().size
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(size.x / 720.0, size.y / 1280.0))
	_draw_background()
	_draw_river()
	_draw_paths()
	_draw_trees()
	_draw_buildings()
	_draw_hero()
	_draw_top_hud()
	_draw_bottom_ui()
	if popup:
		_draw_building_popup()
	if active_tab == "heroes":
		_draw_heroes_panel()
	elif active_tab == "quests":
		_draw_quests_panel()
	elif active_tab == "world":
		_draw_world_panel()
	if toast_time > 0:
		_draw_toast()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_ellipse(rect: Rect2, color: Color) -> void:
	var pts := PackedVector2Array()
	for i in range(32):
		var a := TAU * float(i) / 32.0
		pts.append(rect.position + rect.size / 2.0 + Vector2(cos(a)*rect.size.x/2.0, sin(a)*rect.size.y/2.0))
	draw_colored_polygon(pts, color)

func _draw_round_rect(rect: Rect2, radius: float, color: Color, filled: bool = true, width: float = 1.0) -> void:
	var r := min(radius, min(rect.size.x, rect.size.y) / 2.0)
	if filled:
		draw_rect(Rect2(rect.position.x+r, rect.position.y, rect.size.x-2*r, rect.size.y), color)
		draw_rect(Rect2(rect.position.x, rect.position.y+r, rect.size.x, rect.size.y-2*r), color)
		draw_circle(rect.position+Vector2(r,r), r, color)
		draw_circle(rect.position+Vector2(rect.size.x-r,r), r, color)
		draw_circle(rect.position+Vector2(r,rect.size.y-r), r, color)
		draw_circle(rect.position+Vector2(rect.size.x-r,rect.size.y-r), r, color)
	else:
		draw_arc(Rect2(rect.position.x,rect.position.y,2*r,2*r),PI,PI*1.5,12,color,width,true)
		draw_arc(Rect2(rect.end.x-2*r,rect.position.y,2*r,2*r),PI*1.5,TAU,12,color,width,true)
		draw_arc(Rect2(rect.end.x-2*r,rect.end.y-2*r,2*r,2*r),0,PI*0.5,12,color,width,true)
		draw_arc(Rect2(rect.position.x,rect.end.y-2*r,2*r,2*r),PI*0.5,PI,12,color,width,true)
		draw_line(rect.position+Vector2(r,0),rect.position+Vector2(rect.size.x-r,0),color,width,true)
		draw_line(rect.position+Vector2(r,rect.size.y),rect.position+Vector2(rect.size.x-r,rect.size.y),color,width,true)
		draw_line(rect.position+Vector2(0,r),rect.position+Vector2(0,rect.size.y-r),color,width,true)
		draw_line(rect.position+Vector2(rect.size.x,r),rect.position+Vector2(rect.size.x,rect.size.y-r),color,width,true)

func _draw_background() -> void:
	draw_rect(Rect2(0,0,720,1280), Color("#162a3d"))
	draw_rect(Rect2(0,130,720,1020), Color("#477e72"))
	draw_circle(Vector2(620,235),112,Color("#b3a6ed",0.12))
	draw_circle(Vector2(620,235),76,Color("#e3d7ff",0.09))
	draw_colored_polygon(PackedVector2Array([Vector2(0,330),Vector2(100,250),Vector2(215,340),Vector2(330,245),Vector2(465,350),Vector2(590,260),Vector2(720,335),Vector2(720,475),Vector2(0,475)]),Color("#385d68"))
	draw_colored_polygon(PackedVector2Array([Vector2(0,385),Vector2(140,300),Vector2(270,400),Vector2(405,305),Vector2(565,400),Vector2(720,315),Vector2(720,500),Vector2(0,500)]),Color("#3b6b69"))
	for i in range(14):
		var x := float((i*137+39)%760)-20.0
		var y := float((i*193+430)%680)+380.0
		_draw_ellipse(Rect2(x,y,100,38),Color("#73a77c",0.18))
	for i in range(34):
		var x := float((i*83+24)%700)+10.0
		var y := float((i*127+410)%660)+400.0
		draw_circle(Vector2(x,y),2.4,Color("#f6e3a8",0.9))
		draw_circle(Vector2(x+3,y-2),1.5,Color("#fff1d2",0.9))

func _draw_river() -> void:
	var water := PackedVector2Array([Vector2(0,850),Vector2(0,785),Vector2(105,815),Vector2(180,875),Vector2(285,892),Vector2(380,950),Vector2(510,963),Vector2(620,1020),Vector2(720,1025),Vector2(720,1110),Vector2(600,1100),Vector2(485,1045),Vector2(365,1030),Vector2(260,960),Vector2(150,935),Vector2(65,880)])
	draw_colored_polygon(water,Color("#4f9cb4"))
	draw_polyline(PackedVector2Array([Vector2(0,824),Vector2(105,850),Vector2(180,906),Vector2(285,923),Vector2(380,982),Vector2(510,994),Vector2(620,1050),Vector2(720,1055)]),Color("#9ce2df",0.8),4.0,true)
	for i in range(9):
		var x := float((i*89+25)%700)
		var y := 870.0 + x*0.30
		draw_line(Vector2(x,y),Vector2(x+25,y+4),Color("#b7edf0",0.55),2.0,true)
	for i in range(5):
		var x := 330.0 + i*23
		var y := 946.0 + i*7
		_draw_ellipse(Rect2(x,y,24,13),Color("#d4cbb6"))
		draw_arc(Rect2(x,y,24,13),0,TAU,24,Color("#f3e6d1"),1.5,true)

func _draw_paths() -> void:
	var path := PackedVector2Array([Vector2(0,600),Vector2(120,620),Vector2(230,650),Vector2(360,630),Vector2(500,650),Vector2(720,625)])
	draw_polyline(path,Color("#b7a080"),54.0,true)
	draw_polyline(path,Color("#d6bd93"),43.0,true)
	var cross := PackedVector2Array([Vector2(350,620),Vector2(365,750),Vector2(360,850),Vector2(420,920)])
	draw_polyline(cross,Color("#c7ae86"),36.0,true)
	draw_polyline(cross,Color("#e2cba1"),27.0,true)
	for i in range(18):
		var x := float((i*67+40)%700)
		var y := 605.0 + sin(x/85.0)*12.0
		draw_circle(Vector2(x,y),2.0,Color("#fff0c9",0.45))

func _draw_trees() -> void:
	var spots := [Vector2(55,445),Vector2(90,510),Vector2(640,430),Vector2(670,480),Vector2(70,740),Vector2(630,770),Vector2(110,940),Vector2(590,920),Vector2(65,1070),Vector2(660,1130),Vector2(270,430),Vector2(450,420),Vector2(280,1070),Vector2(570,1140)]
	for i in range(spots.size()):
		var p: Vector2 = spots[i]
		var r := 25.0 + float(i%3)*5.0
		_draw_ellipse(Rect2(p.x-r*0.8,p.y+15,r*1.6,14),Color("#163d3b",0.28))
		draw_rect(Rect2(p.x-6,p.y-8,12,32),Color("#785849"))
		draw_circle(p+Vector2(-8,-r*0.55),r*0.78,Color("#285a50"))
		draw_circle(p+Vector2(9,-r*0.72),r*0.82,Color("#387c61"))
		draw_circle(p+Vector2(0,-r),r*0.64,Color("#58a276"))
		draw_circle(p+Vector2(-7,-r-5),r*0.16,Color("#9acb8e",0.65))
		if i%3==0:
			draw_circle(p+Vector2(12,-r*0.65),3.0,Color("#f0d59b"))

func _draw_buildings() -> void:
	for i in range(buildings.size()):
		var b: Dictionary = buildings[i]
		var p: Vector2 = b.pos
		var body: Color = b.color
		var roof: Color = b.roof
		_draw_ellipse(Rect2(p.x-67,p.y+52,134,26),Color("#183b3b",0.35))
		draw_colored_polygon(PackedVector2Array([p+Vector2(-52,-38),p+Vector2(0,-10),p+Vector2(0,50),p+Vector2(-52,25)]),body.darkened(0.22))
		draw_colored_polygon(PackedVector2Array([p+Vector2(0,-10),p+Vector2(57,-40),p+Vector2(57,22),p+Vector2(0,50)]),body.darkened(0.08))
		draw_colored_polygon(PackedVector2Array([p+Vector2(-60,-38),p+Vector2(0,-77),p+Vector2(60,-38),p+Vector2(0,-8)]),roof)
		draw_line(p+Vector2(-60,-38),p+Vector2(0,-77),roof.lightened(0.25),5.0,true)
		draw_line(p+Vector2(0,-77),p+Vector2(60,-38),roof.lightened(0.18),5.0,true)
		draw_line(p+Vector2(-52,-28),p+Vector2(0,-61),Color("#f5dcae",0.75),2.0,true)
		draw_rect(Rect2(p.x-13,p.y+9,26,41),Color("#493b4b"))
		draw_rect(Rect2(p.x-9,p.y+14,18,36),Color("#a76b54"))
		draw_circle(p+Vector2(5,32),2.2,Color("#f6dc92"))
		for wx in [-35.0,26.0]:
			draw_rect(Rect2(p.x+wx,p.y-20,18,20),Color("#f6d89a"))
			draw_rect(Rect2(p.x+wx+4,p.y-16,10,12),Color("#fff0bb"))
			draw_line(p+Vector2(wx+9,-20),p+Vector2(wx+9,0),Color("#8b5d52"),2.0)
		draw_line(p+Vector2(38,-8),p+Vector2(38,16),Color("#75503f"),3.0)
		_draw_round_rect(Rect2(p.x+26,p.y-21,25,20),5,Color("#f4e6c5"))
		draw_string(ThemeDB.fallback_font,p+Vector2(31,-7),str(b.icon),HORIZONTAL_ALIGNMENT_LEFT,20,15,Color("#75547d"))
		if selected_building == i:
			draw_arc(Rect2(p.x-73,p.y+38,146,30),0,TAU,48,Color("#ffe5a4"),3.0,true)
		draw_circle(p+Vector2(-66,8),5,Color("#ffdf91",0.85))
		draw_circle(p+Vector2(68,10),5,Color("#ffdf91",0.85))

func _draw_hero() -> void:
	_draw_ellipse(Rect2(hero.x-23,hero.y+15,46,15),Color("#153a3d",0.38))
	draw_arc(Rect2(hero.x-28,hero.y+8,56,19),0,TAU,32,Color("#c9c5ff",0.65),2.0,true)
	draw_colored_polygon(PackedVector2Array([hero+Vector2(-14,-29),hero+Vector2(15,-29),hero+Vector2(22,8),hero+Vector2(0,18),hero+Vector2(-21,8)]),Color("#6958a5"))
	_draw_round_rect(Rect2(hero.x-14,hero.y-30,28,37),8,Color("#f0d8bd"))
	draw_rect(Rect2(hero.x-13,hero.y-8,26,18),Color("#d7b5e9"))
	draw_circle(hero+Vector2(0,-39),15,Color("#f8d8c4"))
	draw_circle(hero+Vector2(0,-47),16,Color("#4a3c6e"))
	draw_circle(hero+Vector2(-10,-39),7,Color("#4a3c6e"))
	draw_colored_polygon(PackedVector2Array([hero+Vector2(-15,-44),hero+Vector2(-12,-59),hero+Vector2(1,-57),hero+Vector2(14,-50),hero+Vector2(8,-39),hero+Vector2(2,-49),hero+Vector2(-5,-43)]),Color("#4a3c6e"))
	draw_circle(hero+Vector2(-5,-38),1.8,Color("#4d456e"))
	draw_circle(hero+Vector2(5,-38),1.8,Color("#4d456e"))
	draw_arc(Rect2(hero.x-5,hero.y-34,10,6),0.2,2.8,12,Color("#b76f79"),1.3)
	for i in range(4):
		var a := day_phase*0.7 + i*TAU/4
		var sp := hero+Vector2(cos(a)*30,sin(a)*24-12)
		draw_circle(sp,2.4,Color("#fff0b4",0.8))

func _draw_top_hud() -> void:
	draw_rect(Rect2(0,0,720,158),Color("#111c32",0.94))
	draw_rect(Rect2(0,154,720,4),Color("#e7c78b",0.8))
	draw_string(ThemeDB.fallback_font,Vector2(28,42),"NEBULIA",HORIZONTAL_ALIGNMENT_LEFT,260,28,Color("#f6e6c7"))
	draw_string(ThemeDB.fallback_font,Vector2(30,68),"ECHOES OF ANOTHER WORLD",HORIZONTAL_ALIGNMENT_LEFT,350,12,Color("#b8c4df"))
	draw_circle(Vector2(56,112),24,Color("#7968a7"))
	draw_circle(Vector2(56,112),19,Color("#b4a0dc"))
	draw_string(ThemeDB.fallback_font,Vector2(46,119),str(level),HORIZONTAL_ALIGNMENT_LEFT,30,20,Color("#fff5d8"))
	draw_string(ThemeDB.fallback_font,Vector2(89,106),"VILLAGE KEEPER",HORIZONTAL_ALIGNMENT_LEFT,200,13,Color("#d8c5f3"))
	draw_string(ThemeDB.fallback_font,Vector2(89,128),"Moonfall Hamlet",HORIZONTAL_ALIGNMENT_LEFT,220,19,Color("#fff0d2"))
	_draw_resource_pill(Rect2(430,34,126,43),"✦  "+str(gold),Color("#5a3f55"))
	_draw_resource_pill(Rect2(566,34,126,43),"◇  "+str(crystals),Color("#314e70"))
	draw_string(ThemeDB.fallback_font,Vector2(435,105),"✧  DAY "+str(int(day_phase/60.0)+1),HORIZONTAL_ALIGNMENT_LEFT,190,15,Color("#d9e7ef"))
	draw_string(ThemeDB.fallback_font,Vector2(435,128),"Village is peaceful",HORIZONTAL_ALIGNMENT_LEFT,220,13,Color("#9fbdc9"))

func _draw_resource_pill(rect: Rect2, label: String, color: Color) -> void:
	_draw_round_rect(rect,18,color)
	draw_string(ThemeDB.fallback_font,Vector2(rect.position.x+12,rect.position.y+27),label,HORIZONTAL_ALIGNMENT_LEFT,rect.size.x-18,18,Color("#fff0d1"))

func _draw_bottom_ui() -> void:
	draw_rect(Rect2(0,1124,720,156),Color("#101a2b",0.96))
	draw_rect(Rect2(0,1124,720,3),Color("#c9ad82",0.8))
	var labels := ["VILLAGE","HEROES","QUESTS","WORLD"]
	var icons := ["⌂","♙","✧","✦"]
	var tabs := ["village","heroes","quests","world"]
	for i in range(4):
		var x := 90.0 + i*180.0
		var active := active_tab == tabs[i]
		draw_circle(Vector2(x,1171),27,Color("#4d406d") if active else Color("#26344b"))
		draw_string(ThemeDB.fallback_font,Vector2(x-13,1180),icons[i],HORIZONTAL_ALIGNMENT_LEFT,35,28,Color("#ffe4a9") if active else Color("#a9b7d1"))
		draw_string(ThemeDB.fallback_font,Vector2(x-49,1223),labels[i],HORIZONTAL_ALIGNMENT_CENTER,98,14,Color("#f4dba8") if active else Color("#a5b4cc"))
	draw_string(ThemeDB.fallback_font,Vector2(24,1257),"Touch a building to manage it  •  Drag to walk",HORIZONTAL_ALIGNMENT_LEFT,675,13,Color("#91a6bf"))

func _draw_building_popup() -> void:
	if selected_building < 0 or selected_building >= buildings.size():
		return
	draw_rect(Rect2(0,0,720,1280),Color("#050b19",0.42))
	var b: Dictionary = buildings[selected_building]
	_draw_round_rect(Rect2(45,410,630,440),28,Color("#202b43"))
	_draw_round_rect(Rect2(45,410,630,440),28,Color("#d6bd91"),false,2.0)
	_draw_round_rect(Rect2(68,432,584,138),20,b.roof)
	draw_string(ThemeDB.fallback_font,Vector2(92,472),str(b.name),HORIZONTAL_ALIGNMENT_LEFT,500,29,Color("#fff1d3"))
	draw_string(ThemeDB.fallback_font,Vector2(92,505),str(b.sub),HORIZONTAL_ALIGNMENT_LEFT,500,15,Color("#f3d9bc"))
	draw_string(ThemeDB.fallback_font,Vector2(92,548),"A cozy place for your growing village.",HORIZONTAL_ALIGNMENT_LEFT,530,16,Color("#fff1df"))
	draw_string(ThemeDB.fallback_font,Vector2(83,615),"INCOME",HORIZONTAL_ALIGNMENT_LEFT,130,14,Color("#b7c5dd"))
	draw_string(ThemeDB.fallback_font,Vector2(83,652),"+"+str(b.income)+" gold / minute",HORIZONTAL_ALIGNMENT_LEFT,300,25,Color("#f7df9d"))
	draw_string(ThemeDB.fallback_font,Vector2(83,691),"Upgrade this business to improve its yield.",HORIZONTAL_ALIGNMENT_LEFT,550,16,Color("#bfcbe0"))
	_draw_button(Rect2(70,735,275,70),"COLLECT INCOME",Color("#537c72"))
	_draw_button(Rect2(365,735,285,70),"UPGRADE  ·  250 G",Color("#8d6390"))
	draw_string(ThemeDB.fallback_font,Vector2(613,454),"×",HORIZONTAL_ALIGNMENT_LEFT,35,31,Color("#fff1df"))

func _draw_heroes_panel() -> void:
	draw_rect(Rect2(0,160,720,965),Color("#111a2d",0.96))
	draw_string(ThemeDB.fallback_font,Vector2(34,212),"YOUR COMPANIONS",HORIZONTAL_ALIGNMENT_LEFT,600,28,Color("#f5e5c8"))
	draw_string(ThemeDB.fallback_font,Vector2(36,242),"Four souls have answered the call.",HORIZONTAL_ALIGNMENT_LEFT,600,16,Color("#aebbd2"))
	for i in range(characters.size()):
		var c: Dictionary = characters[i]
		var y := 278.0 + i*194.0
		_draw_round_rect(Rect2(28,y,664,166),22,Color("#222e48"))
		_draw_round_rect(Rect2(28,y,664,166),22,Color("#5e6889"),false,1.5)
		draw_circle(Vector2(105,y+81),54,c.color.darkened(0.15))
		draw_circle(Vector2(105,y+63),28,c.color)
		draw_circle(Vector2(105,y+49),31,c.hair)
		draw_arc(Rect2(78,y+46,54,56),0,PI,24,c.hair.lightened(0.12),8.0,true)
		draw_circle(Vector2(95,y+63),3,Color("#33344e"))
		draw_circle(Vector2(115,y+63),3,Color("#33344e"))
		draw_string(ThemeDB.fallback_font,Vector2(178,y+52),str(c.name),HORIZONTAL_ALIGNMENT_LEFT,400,25,Color("#fff0d8"))
		draw_string(ThemeDB.fallback_font,Vector2(178,y+80),str(c.role),HORIZONTAL_ALIGNMENT_LEFT,400,16,Color("#b6c6e3"))
		draw_string(ThemeDB.fallback_font,Vector2(178,y+111),"LEVEL  "+str(c.level)+"     ★ ★ ☆",HORIZONTAL_ALIGNMENT_LEFT,400,16,Color("#e8ce91"))
		_draw_button(Rect2(510,y+103,150,43),"DETAILS",Color("#665a89"))

func _draw_quests_panel() -> void:
	draw_rect(Rect2(0,160,720,965),Color("#111a2d",0.97))
	draw_string(ThemeDB.fallback_font,Vector2(34,212),"STORY JOURNAL",HORIZONTAL_ALIGNMENT_LEFT,600,28,Color("#f5e5c8"))
	draw_string(ThemeDB.fallback_font,Vector2(36,242),"Chapter I · A Village Beneath the Stars",HORIZONTAL_ALIGNMENT_LEFT,640,17,Color("#c5b6e7"))
	var quests := [
		["01","Welcome to Moonfall","Speak to Liora near the old fountain.","REWARD  120 GOLD"],
		["02","A Roof for Everyone","Restore the Moonlit Inn.","REWARD  3 STAR SHARDS"],
		["03","Whispers in the Woods","Find the source of the blue lights.","NEW STORY"]
	]
	for i in range(quests.size()):
		var y := 285.0+i*220.0
		_draw_round_rect(Rect2(30,y,660,194),22,Color("#242f49"))
		draw_circle(Vector2(79,y+47),26,Color("#66558e"))
		draw_string(ThemeDB.fallback_font,Vector2(68,y+53),quests[i][0],HORIZONTAL_ALIGNMENT_LEFT,40,18,Color("#fff0d1"))
		draw_string(ThemeDB.fallback_font,Vector2(122,y+47),quests[i][1],HORIZONTAL_ALIGNMENT_LEFT,520,22,Color("#fff0d1"))
		draw_string(ThemeDB.fallback_font,Vector2(53,y+94),quests[i][2],HORIZONTAL_ALIGNMENT_LEFT,600,16,Color("#b6c5dc"))
		draw_string(ThemeDB.fallback_font,Vector2(53,y+143),quests[i][3],HORIZONTAL_ALIGNMENT_LEFT,400,14,Color("#e9d29b"))
		_draw_button(Rect2(490,y+127,172,48),"TRACK QUEST",Color("#557b76"))

func _draw_world_panel() -> void:
	draw_rect(Rect2(0,160,720,965),Color("#111a2d",0.97))
	draw_string(ThemeDB.fallback_font,Vector2(34,212),"THE STARFALL REALMS",HORIZONTAL_ALIGNMENT_LEFT,640,28,Color("#f5e5c8"))
	draw_string(ThemeDB.fallback_font,Vector2(36,242),"Beyond the village, a world is waiting.",HORIZONTAL_ALIGNMENT_LEFT,600,16,Color("#b5c4df"))
	var regions := [
		["MOONFALL HAMLET","Your home · Safe zone",Color("#628e79"),"OPEN"],
		["LUMENWOOD FOREST","Ancient trees and lost shrines",Color("#416e70"),"UNLOCK AT LV. 4"],
		["CRYSTAL VEIL","A frozen valley of starlight",Color("#6579a5"),"LOCKED"],
		["EMBERFALL RUINS","A forgotten kingdom",Color("#98665d"),"LOCKED"]
	]
	for i in range(regions.size()):
		var y := 292.0+i*180.0
		_draw_round_rect(Rect2(30,y,660,150),22,regions[i][2])
		draw_circle(Vector2(115,y+75),45,regions[i][2].lightened(0.17))
		draw_circle(Vector2(115,y+75),29,regions[i][2].darkened(0.18))
		draw_string(ThemeDB.fallback_font,Vector2(183,y+60),regions[i][0],HORIZONTAL_ALIGNMENT_LEFT,460,22,Color("#fff0d8"))
		draw_string(ThemeDB.fallback_font,Vector2(183,y+87),regions[i][1],HORIZONTAL_ALIGNMENT_LEFT,460,15,Color("#e2e4ed"))
		draw_string(ThemeDB.fallback_font,Vector2(183,y+119),regions[i][3],HORIZONTAL_ALIGNMENT_LEFT,460,14,Color("#f1d79c"))

func _draw_button(rect: Rect2, label: String, color: Color) -> void:
	_draw_round_rect(rect,16,color)
	_draw_round_rect(rect,16,color.lightened(0.18),false,1.5)
	draw_string(ThemeDB.fallback_font,Vector2(rect.position.x+10,rect.position.y+rect.size.y/2+6),label,HORIZONTAL_ALIGNMENT_CENTER,rect.size.x-20,16,Color("#fff4df"))

func _draw_toast() -> void:
	_draw_round_rect(Rect2(65,170,590,54),18,Color("#17273a",0.96))
	draw_string(ThemeDB.fallback_font,Vector2(85,204),toast,HORIZONTAL_ALIGNMENT_CENTER,550,17,Color("#fff0ce"))

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed:
		_handle_tap(event.position)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_handle_tap(event.position)
	elif event is InputEventScreenDrag:
		var p := event.position
		if p.y > 170 and p.y < 1110:
			target = _screen_to_game(p)
	elif event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		if event.position.y > 170 and event.position.y < 1110:
			target = _screen_to_game(event.position)

func _screen_to_game(p: Vector2) -> Vector2:
	var s := get_viewport_rect().size
	return Vector2(p.x*720.0/max(s.x,1.0),p.y*1280.0/max(s.y,1.0))

func _handle_tap(raw: Vector2) -> void:
	var p := _screen_to_game(raw)
	if popup:
		if p.y > 720 and p.y < 820:
			if p.x < 355:
				var income: int = buildings[selected_building].income
				gold += income * 5
				_show_toast("Collected "+str(income*5)+" gold from the business!")
			else:
				if gold >= 250:
					gold -= 250
					buildings[selected_building].income += 12
					buildings[selected_building].sub = str(buildings[selected_building].sub).split("  ·")[0]+"  ·  Lv. 2"
					_show_toast("Business upgraded! Income increased.")
				else:
					_show_toast("Not enough gold for this upgrade.")
			popup = false
		else:
			popup = false
		queue_redraw()
		return
	if p.y > 1124:
		if p.x < 180:
			active_tab = "village"
		elif p.x < 360:
			active_tab = "heroes"
		elif p.x < 540:
			active_tab = "quests"
		else:
			active_tab = "world"
		selected_building = -1
		queue_redraw()
		return
	if active_tab != "village":
		if p.y < 260:
			active_tab = "village"
		queue_redraw()
		return
	if p.y < 158:
		if p.x > 425 and p.x < 560:
			gold += 100
			_show_toast("Daily village grant: +100 gold")
		elif p.x >= 560:
			crystals += 1
			_show_toast("Found a hidden star shard!")
		queue_redraw()
		return
	for i in range(buildings.size()):
		var bp: Vector2 = buildings[i].pos
		if abs(p.x-bp.x) < 72 and abs(p.y-(bp.y-15)) < 93:
			selected_building = i
			popup = true
			queue_redraw()
			return
	target = Vector2(clamp(p.x,35,685),clamp(p.y,190,1100))
	queue_redraw()

func _show_toast(message: String) -> void:
	toast = message
	toast_time = 2.7
	queue_redraw()

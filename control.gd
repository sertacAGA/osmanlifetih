extends Control

# --- OYUN AYARLARI ---
const MAP_LAYERS = 6 
const MIN_NODES = 2
const MAX_NODES = 4
# ---------------------

var current_state = "MENU"

# İlerleme ve Ayarlar
var current_floor = 0 
var player_score = 0
var is_battle_resolving = false 
var difficulty_level = 1 

# Savaş Değişkenleri
var player_max_health = 50
var player_health = 50
var player_max_energy = 3
var player_energy = 3
var enemy_health = 40
var enemy_max_health = 40

# Arayüz Elemanları
var top_bar: Panel 
var floor_label: Label
var score_label: Label
var info_label: Label 
var end_turn_button: Button 
var player_stats_label: Label
var enemy_stats_label: Label
var background_rect: TextureRect 

# Menü Elemanları
var current_popup: Control 
var diff_label: Label

# Konteynerler
var main_menu_container: CenterContainer
var map_container: Control
var battle_container: Control
var hand_container: HBoxContainer
var arena_area: Control 
var map_visuals_container: VBoxContainer 

# KART VERİTABANI
var card_database = [
	{"id": "akinci", "name": "Akıncı", "cost": 1, "dmg": 6, "desc": "Hızlı Saldırı", "color": Color(1, 0.4, 0.4)}, # Renkleri biraz açtım
	{"id": "yeniceri", "name": "Yeniçeri", "cost": 2, "dmg": 12, "desc": "Güçlü Vuruş", "color": Color(0.4, 0.4, 1)},
	{"id": "sahi", "name": "Şahi Topu", "cost": 3, "dmg": 25, "desc": "Yok Edici", "color": Color(0.3, 0.3, 0.3)},
	{"id": "sipahi", "name": "Sipahi", "cost": 1, "dmg": 4, "desc": "Savunma", "color": Color(0.9, 0.9, 0.4)},
	{"id": "okcu", "name": "Kemankeş", "cost": 0, "dmg": 3, "desc": "Seri Atış", "color": Color(0.8, 0.6, 0.3)}
]

func _ready():
	randomize()
	
	# --- EKRAN ÖLÇEKLENDİRME ---
	var window = get_window()
	window.content_scale_size = Vector2i(1920, 1080)
	window.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	window.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	
	# --- ARKA PLAN ---
	background_rect = TextureRect.new()
	background_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background_rect)
	move_child(background_rect, 0)
	
	change_background_image("res://assets/backgrounds/menu_bg.png")
	
	set_anchors_preset(Control.PRESET_FULL_RECT)
	create_menu_ui()

# --- YARDIMCI: RESİM YÜKLEME ---
func change_background_image(path: String):
	if ResourceLoader.exists(path):
		background_rect.texture = load(path)
		background_rect.modulate = Color(1, 1, 1, 1) 
	else:
		background_rect.texture = null
		background_rect.modulate = Color(0.18, 0.20, 0.25)

# --- YARDIMCI: BUTON STİLİ (GÜNCELLENDİ) ---
func apply_button_style(btn: Button):
	var path = "res://assets/ui/button_panel.png"
	if ResourceLoader.exists(path):
		var tex = load(path)
		var style = StyleBoxTexture.new()
		style.texture = tex
		style.texture_margin_left = 15
		style.texture_margin_right = 15
		style.texture_margin_top = 10
		style.texture_margin_bottom = 10
		
		btn.add_theme_stylebox_override("normal", style)
		btn.add_theme_stylebox_override("hover", style)
		btn.add_theme_stylebox_override("pressed", style)
		btn.add_theme_stylebox_override("focus", style)
		
		# --- DÜZELTME: OKUNABİLİRLİK İÇİN GÖLGE VE KONTUR ---
		btn.add_theme_color_override("font_color", Color.WHITE)
		btn.add_theme_constant_override("outline_size", 8) # Kalın dış çizgi
		btn.add_theme_color_override("font_outline_color", Color.BLACK)
	else:
		# Resim yoksa standart stil
		pass

# --- POPUP SİSTEMİ ---
func show_popup_layer(content_node):
	if current_popup: current_popup.queue_free()
	
	var overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.8)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.z_index = 100 
	add_child(overlay)
	current_popup = overlay
	
	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)
	center.add_child(content_node)

func close_current_popup():
	if current_popup:
		current_popup.queue_free()
		current_popup = null

# --- MENÜ SİSTEMİ ---
func create_menu_ui():
	if main_menu_container: main_menu_container.queue_free()
	if battle_container: battle_container.visible = false
	if map_container: map_container.visible = false
	
	change_background_image("res://assets/backgrounds/menu_bg.png")
	
	main_menu_container = CenterContainer.new()
	main_menu_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(main_menu_container)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 25)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	main_menu_container.add_child(vbox)
	
	var title = Label.new()
	title.text = "OSMANLI: FETİH"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.modulate = Color(0.85, 0.65, 0.13)
	title.add_theme_font_size_override("font_size", 80)
	title.add_theme_color_override("font_shadow_color", Color.BLACK)
	title.add_theme_constant_override("shadow_offset_x", 4)
	title.add_theme_constant_override("shadow_offset_y", 4)
	vbox.add_child(title)
	
	var subtitle = Label.new()
	subtitle.text = "Roguelike Card RPG"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.modulate = Color(0.9, 0.9, 0.9)
	subtitle.add_theme_font_size_override("font_size", 30)
	subtitle.add_theme_color_override("font_shadow_color", Color.BLACK)
	vbox.add_child(subtitle)
	
	var spacer = Control.new()
	spacer.custom_minimum_size.y = 50
	vbox.add_child(spacer)
	
	var start_btn = Button.new()
	start_btn.text = "YENİ SEFERE BAŞLA"
	start_btn.custom_minimum_size = Vector2(360, 100)
	start_btn.add_theme_font_size_override("font_size", 32)
	apply_button_style(start_btn) 
	start_btn.pressed.connect(_on_start_button_pressed)
	vbox.add_child(start_btn)
	
	var settings_btn = Button.new()
	settings_btn.text = "AYARLAR"
	settings_btn.custom_minimum_size = Vector2(360, 80)
	settings_btn.add_theme_font_size_override("font_size", 28)
	apply_button_style(settings_btn) 
	settings_btn.pressed.connect(show_settings_ui)
	vbox.add_child(settings_btn)

func show_settings_ui():
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(500, 400)
	
	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 25)
	panel.add_child(vbox)
	
	var lbl = Label.new()
	lbl.text = "AYARLAR"
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 40)
	vbox.add_child(lbl)
	
	diff_label = Label.new()
	diff_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	diff_label.add_theme_font_size_override("font_size", 28)
	vbox.add_child(diff_label)
	update_difficulty_label() 
	
	var diff_btn = Button.new()
	diff_btn.text = "Zorluğu Değiştir"
	diff_btn.custom_minimum_size = Vector2(300, 70)
	diff_btn.add_theme_font_size_override("font_size", 24)
	diff_btn.pressed.connect(_on_change_difficulty)
	vbox.add_child(diff_btn)
	
	var close_btn = Button.new()
	close_btn.text = "KAPAT"
	close_btn.custom_minimum_size = Vector2(200, 60)
	close_btn.add_theme_font_size_override("font_size", 24)
	close_btn.pressed.connect(close_current_popup)
	vbox.add_child(close_btn)
	
	show_popup_layer(panel)

func _on_change_difficulty():
	difficulty_level = (difficulty_level + 1) % 3
	update_difficulty_label()

func update_difficulty_label():
	var txt = "Normal"
	if difficulty_level == 0: txt = "Kolay"
	elif difficulty_level == 2: txt = "Zor"
	if diff_label: diff_label.text = "Zorluk: " + txt

func _on_start_button_pressed():
	current_state = "MAP"
	current_floor = 0 
	player_health = player_max_health
	player_score = 0
	
	if main_menu_container: main_menu_container.visible = false
	show_map_screen()

# --- HARİTA ---
func show_map_screen():
	change_background_image("res://assets/backgrounds/map_bg.png")

	if map_container:
		map_container.visible = true
		update_map_visuals() 
		update_top_bar()
		return
		
	map_container = Control.new()
	map_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(map_container)
	
	top_bar = Panel.new()
	top_bar.custom_minimum_size.y = 90
	top_bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	map_container.add_child(top_bar)
	
	var bar_hbox = HBoxContainer.new()
	bar_hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	bar_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	bar_hbox.add_theme_constant_override("separation", 80)
	top_bar.add_child(bar_hbox)
	
	floor_label = Label.new()
	floor_label.add_theme_font_size_override("font_size", 28)
	bar_hbox.add_child(floor_label)
	
	score_label = Label.new()
	score_label.add_theme_font_size_override("font_size", 28)
	bar_hbox.add_child(score_label)
	
	var center_cont = CenterContainer.new()
	center_cont.set_anchors_preset(Control.PRESET_FULL_RECT)
	center_cont.add_theme_constant_override("margin_top", 100)
	map_container.add_child(center_cont)
	
	map_visuals_container = VBoxContainer.new()
	map_visuals_container.alignment = BoxContainer.ALIGNMENT_CENTER
	map_visuals_container.add_theme_constant_override("separation", 60) 
	center_cont.add_child(map_visuals_container)
	
	generate_map_structure()
	update_map_visuals()
	update_top_bar()

func update_top_bar():
	floor_label.text = "KAT: " + str(current_floor + 1) + " / " + str(MAP_LAYERS)
	score_label.text = "PUAN: " + str(player_score)

func generate_map_structure():
	for child in map_visuals_container.get_children():
		child.queue_free()

	for i in range(MAP_LAYERS):
		var layer_hbox = HBoxContainer.new()
		layer_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
		layer_hbox.add_theme_constant_override("separation", 80)
		map_visuals_container.add_child(layer_hbox)
		
		var num_nodes = randi_range(MIN_NODES, MAX_NODES)
		if i == 0: num_nodes = 1 
		
		for j in range(num_nodes):
			var node_btn = Button.new()
			node_btn.custom_minimum_size = Vector2(80, 80)
			node_btn.text = ""
			node_btn.flat = true 
			node_btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
			node_btn.expand_icon = true 
			
			var logical_floor = (MAP_LAYERS - 1) - i
			node_btn.set_meta("floor", logical_floor)
			
			node_btn.pressed.connect(_on_map_node_pressed.bind(node_btn))
			layer_hbox.add_child(node_btn)

func update_map_visuals():
	var tex_locked = null
	var tex_active = null
	var tex_boss = null
	
	if ResourceLoader.exists("res://assets/ui/node_locked.png"):
		tex_locked = load("res://assets/ui/node_locked.png")
	if ResourceLoader.exists("res://assets/ui/node_active.png"):
		tex_active = load("res://assets/ui/node_active.png")
	if ResourceLoader.exists("res://assets/ui/node_boss.png"):
		tex_boss = load("res://assets/ui/node_boss.png")

	for layer in map_visuals_container.get_children():
		for btn in layer.get_children():
			var btn_floor = btn.get_meta("floor")
			
			if btn_floor == MAP_LAYERS - 1:
				btn.icon = tex_boss
			elif btn_floor == current_floor:
				btn.icon = tex_active
			else:
				btn.icon = tex_locked
			
			if btn_floor < current_floor:
				btn.modulate = Color(0.4, 0.4, 0.4)
				btn.disabled = true
			elif btn_floor == current_floor:
				btn.modulate = Color(1, 1, 1)
				btn.disabled = false
				var t = create_tween().set_loops()
				t.tween_property(btn, "scale", Vector2(1.1, 1.1), 0.5)
				t.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.5)
			else:
				btn.modulate = Color(0.6, 0.6, 0.6)
				btn.disabled = true 
			
			if btn_floor == MAP_LAYERS - 1: 
				if btn_floor != current_floor: btn.disabled = true

func _on_map_node_pressed(btn):
	map_container.visible = false
	show_battle_screen()

# --- SAVAŞ SİSTEMİ ---
func show_battle_screen():
	change_background_image("res://assets/backgrounds/battle_bg.png")

	is_battle_resolving = false 
	player_energy = player_max_energy
	
	var base_hp = 30 + (difficulty_level * 10)
	enemy_health = base_hp + (current_floor * 5)
	enemy_max_health = enemy_health
	
	if battle_container:
		battle_container.visible = true
		update_battle_ui()
		start_player_turn()
		return
		
	battle_container = Control.new()
	battle_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(battle_container)
	
	var main_vbox = VBoxContainer.new()
	main_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	main_vbox.add_theme_constant_override("separation", 0) 
	battle_container.add_child(main_vbox)
	
	# 1. ARENA
	arena_area = Control.new()
	arena_area.size_flags_vertical = Control.SIZE_EXPAND_FILL 
	main_vbox.add_child(arena_area)
	
	var arena_overlay = ColorRect.new()
	arena_overlay.color = Color(0, 0, 0, 0.3)
	arena_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	arena_area.add_child(arena_overlay)
	
	var exit_btn = Button.new()
	exit_btn.text = "X"
	exit_btn.modulate = Color(1, 0.3, 0.3)
	exit_btn.custom_minimum_size = Vector2(60, 60)
	exit_btn.add_theme_font_size_override("font_size", 30)
	exit_btn.position = Vector2(30, 30)
	exit_btn.pressed.connect(_on_exit_battle_pressed)
	exit_btn.z_index = 10 
	arena_area.add_child(exit_btn)
	
	var fighters_row = HBoxContainer.new()
	fighters_row.set_anchors_preset(Control.PRESET_FULL_RECT)
	fighters_row.anchor_top = 0.15 
	fighters_row.anchor_bottom = 0.65
	fighters_row.alignment = BoxContainer.ALIGNMENT_CENTER 
	fighters_row.add_theme_constant_override("separation", 200) 
	arena_area.add_child(fighters_row)

	# --- OYUNCU (AKINCI) ---
	var player_visual = VBoxContainer.new()
	player_visual.alignment = BoxContainer.ALIGNMENT_END 
	fighters_row.add_child(player_visual)
	
	player_stats_label = Label.new()
	player_stats_label.text = "AKINCI"
	player_stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	player_stats_label.custom_minimum_size.y = 50 
	player_stats_label.add_theme_font_size_override("font_size", 24)
	player_stats_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	player_visual.add_child(player_stats_label)
	
	var player_rect = TextureRect.new()
	if ResourceLoader.exists("res://assets/characters/akinci.png"):
		player_rect.texture = load("res://assets/characters/akinci.png")
	player_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	player_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	# --- GÜNCELLEME: KARAKTERLER BÜYÜTÜLDÜ (450x550) ---
	player_rect.custom_minimum_size = Vector2(450, 550) 
	player_visual.add_child(player_rect)
	
	# --- DÜŞMAN (BİZANS) ---
	var enemy_visual = VBoxContainer.new()
	enemy_visual.alignment = BoxContainer.ALIGNMENT_END
	fighters_row.add_child(enemy_visual)
	
	enemy_stats_label = Label.new()
	enemy_stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	enemy_stats_label.custom_minimum_size.y = 50
	enemy_stats_label.add_theme_font_size_override("font_size", 24)
	enemy_stats_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	enemy_visual.add_child(enemy_stats_label)
	
	var enemy_rect = TextureRect.new()
	if ResourceLoader.exists("res://assets/characters/byzantine.png"):
		enemy_rect.texture = load("res://assets/characters/byzantine.png")
	enemy_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	enemy_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	# --- GÜNCELLEME: KARAKTERLER BÜYÜTÜLDÜ (450x550) ---
	enemy_rect.custom_minimum_size = Vector2(450, 550)
	enemy_rect.flip_h = true 
	enemy_visual.add_child(enemy_rect)
	
	# KONTROL PANELİ
	var controls_box = VBoxContainer.new()
	controls_box.anchor_left = 0.5
	controls_box.anchor_top = 0.82
	controls_box.anchor_right = 0.5
	controls_box.anchor_bottom = 0.82
	controls_box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	controls_box.alignment = BoxContainer.ALIGNMENT_CENTER
	arena_area.add_child(controls_box)
	
	info_label = Label.new()
	info_label.text = "Hazır Ol!"
	info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_label.add_theme_font_size_override("font_size", 30)
	info_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	controls_box.add_child(info_label)
	
	end_turn_button = Button.new()
	end_turn_button.text = "TURU BİTİR"
	end_turn_button.custom_minimum_size = Vector2(270, 80)
	end_turn_button.add_theme_font_size_override("font_size", 28)
	apply_button_style(end_turn_button) 
	end_turn_button.pressed.connect(_on_end_turn_pressed)
	controls_box.add_child(end_turn_button)

	var spacer_bg = ColorRect.new()
	spacer_bg.custom_minimum_size.y = 40 
	spacer_bg.color = Color(0, 0, 0, 0.3) 
	main_vbox.add_child(spacer_bg)

	# 2. EL KARTLARI
	hand_container = HBoxContainer.new()
	hand_container.custom_minimum_size.y = 320 
	hand_container.alignment = BoxContainer.ALIGNMENT_CENTER
	hand_container.add_theme_constant_override("separation", 25)
	
	var hand_bg = ColorRect.new()
	hand_bg.color = Color(0, 0, 0, 0.5) 
	hand_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	hand_container.add_child(hand_bg)
	
	main_vbox.add_child(hand_container)
	
	update_battle_ui()
	start_player_turn()

func _on_exit_battle_pressed():
	game_over()

func start_player_turn():
	if is_battle_resolving: return 
	
	player_energy = player_max_energy
	info_label.text = "- SENİN SIRAN -"
	info_label.modulate = Color.WHITE
	end_turn_button.disabled = false
	end_turn_button.text = "TURU BİTİR"
	update_battle_ui()
	draw_cards_to_hand()

func _on_end_turn_pressed():
	if is_battle_resolving: return
	
	end_turn_button.disabled = true
	end_turn_button.text = "Bekleniyor..."
	
	for child in hand_container.get_children():
		if child is Button: child.queue_free()
		
	info_label.text = "Düşman Hamlesi..."
	info_label.modulate = Color.RED
	
	await get_tree().create_timer(1.0).timeout
	
	if is_battle_resolving: return 
	
	var diff_bonus = difficulty_level 
	var enemy_damage = 4 + diff_bonus + int(current_floor * 0.5) 
	
	player_health -= enemy_damage
	info_label.text = "Düşman " + str(enemy_damage) + " hasar verdi!"
	update_battle_ui()
	
	if player_health <= 0:
		show_game_over_ui(false) 
		return
		
	await get_tree().create_timer(1.0).timeout
	start_player_turn()

func _on_card_clicked(card_data, card_visual):
	if is_battle_resolving: return 
	
	if player_energy >= card_data["cost"]:
		player_energy -= card_data["cost"]
		enemy_health -= card_data["dmg"]
		card_visual.queue_free()
		update_battle_ui()
		
		if enemy_health <= 0:
			win_battle()
	else:
		info_label.text = "Enerji Yetersiz!"
		info_label.modulate = Color.RED

func win_battle():
	if is_battle_resolving: return
	is_battle_resolving = true 
	
	var heal_amount = 10
	if difficulty_level == 2: heal_amount = 5 
	
	player_health = min(player_max_health, player_health + heal_amount)
	
	info_label.text = "ZAFER! (+" + str(heal_amount) + " Can)"
	
	for child in hand_container.get_children():
		if child is Button: child.queue_free()
	
	await get_tree().create_timer(1.5).timeout
	
	current_floor += 1 
	player_score += 100 * (difficulty_level + 1)
	
	if current_floor >= MAP_LAYERS:
		show_game_over_ui(true) 
	else:
		battle_container.visible = false
		show_map_screen()

# --- MERKEZLENMİŞ BİTİŞ EKRANI ---
func game_over():
	show_game_over_ui(false)

func show_game_over_ui(is_win):
	battle_container.visible = false
	map_container.visible = false
	
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(600, 450)
	
	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 30)
	panel.add_child(vbox)
	
	var title = Label.new()
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 50)
	if is_win:
		title.text = "FETİH TAMAMLANDI!"
		title.modulate = Color.GREEN
	else:
		title.text = "SEFER BAŞARISIZ..."
		title.modulate = Color.RED
	vbox.add_child(title)
	
	var score_txt = Label.new()
	score_txt.text = "Toplam Puan: " + str(player_score)
	score_txt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_txt.add_theme_font_size_override("font_size", 30)
	vbox.add_child(score_txt)
	
	var restart_btn = Button.new()
	restart_btn.text = "ANA MENÜYE DÖN"
	restart_btn.custom_minimum_size = Vector2(300, 80)
	restart_btn.add_theme_font_size_override("font_size", 24)
	apply_button_style(restart_btn) # Stil
	restart_btn.pressed.connect(return_to_main_menu)
	vbox.add_child(restart_btn)
	
	show_popup_layer(panel)

func return_to_main_menu():
	close_current_popup()
	create_menu_ui()
	current_state = "MENU"

# --- KART İŞLEMLERİ ---
func draw_cards_to_hand():
	for child in hand_container.get_children():
		if child is Button: child.queue_free()
	for i in range(4):
		var data = card_database.pick_random()
		create_visual_card(data)

func create_visual_card(data):
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(200, 290) 
	
	# --- GÜNCELLEME: DOKULU KART ARKAPLANI ---
	var style = StyleBoxTexture.new()
	var bg_tex_path = "res://assets/cards/card_base.png"
	
	if ResourceLoader.exists(bg_tex_path):
		style.texture = load(bg_tex_path)
		# Dokuyu bozmadan renklendir (Tint)
		style.modulate_color = data["color"]
	else:
		# Resim yoksa eski usül düz renk (Hata vermesin)
		# StyleBoxTexture yerine StyleBoxFlat'e dönüştürülmeli ama basitlik için renk verip geçiyoruz
		# En doğrusu StyleBoxFlat kullanmaktır bu durumda:
		var flat = StyleBoxFlat.new()
		flat.bg_color = data["color"]
		flat.set_corner_radius_all(12)
		style = flat # Style değişkenini değiştir

	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("hover", style)
	btn.add_theme_stylebox_override("pressed", style)
	btn.add_theme_stylebox_override("focus", style)
	
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var margin = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	
	btn.add_child(margin)
	margin.add_child(vbox)
	
	var header = HBoxContainer.new()
	vbox.add_child(header)
	
	var lbl_name = Label.new()
	lbl_name.text = data["name"]
	lbl_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl_name.add_theme_font_size_override("font_size", 18) 
	# Zıt renk olsun diye siyah outline
	lbl_name.add_theme_constant_override("outline_size", 4)
	lbl_name.add_theme_color_override("font_outline_color", Color.BLACK)
	header.add_child(lbl_name)
	
	var lbl_cost = Label.new()
	lbl_cost.text = str(data["cost"])
	lbl_cost.modulate = Color.YELLOW
	lbl_cost.add_theme_font_size_override("font_size", 24) 
	lbl_cost.add_theme_constant_override("outline_size", 4)
	lbl_cost.add_theme_color_override("font_outline_color", Color.BLACK)
	header.add_child(lbl_cost)
	
	var card_img_path = "res://assets/cards/card_" + data["id"] + ".png"
	var card_rect = TextureRect.new()
	card_rect.custom_minimum_size = Vector2(0, 100) 
	card_rect.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	card_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	
	if ResourceLoader.exists(card_img_path):
		card_rect.texture = load(card_img_path)
	else:
		card_rect.modulate = Color(0,0,0,0.3) 
		
	vbox.add_child(card_rect)
	
	var lbl_desc = Label.new()
	lbl_desc.text = data["desc"]
	lbl_desc.autowrap_mode = TextServer.AUTOWRAP_WORD
	lbl_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_desc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	lbl_desc.add_theme_font_size_override("font_size", 14) 
	lbl_desc.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95))
	lbl_desc.add_theme_constant_override("outline_size", 3)
	lbl_desc.add_theme_color_override("font_outline_color", Color.BLACK)
	vbox.add_child(lbl_desc)
	
	var lbl_dmg = Label.new()
	lbl_dmg.text = "Güç: " + str(data["dmg"])
	lbl_dmg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_dmg.add_theme_color_override("font_color", Color(1, 0.6, 0.6))
	lbl_dmg.add_theme_font_size_override("font_size", 18) 
	lbl_dmg.add_theme_constant_override("outline_size", 3)
	lbl_dmg.add_theme_color_override("font_outline_color", Color.BLACK)
	vbox.add_child(lbl_dmg)
	
	btn.pressed.connect(_on_card_clicked.bind(data, btn))
	hand_container.add_child(btn)

func update_battle_ui():
	if player_stats_label:
		player_stats_label.text = "AKINCI\nCan: %d/%d\nEnerji: %d/%d" % [player_health, player_max_health, player_energy, player_max_energy]
	if enemy_stats_label:
		enemy_stats_label.text = "DÜŞMAN (Kat %d)\nCan: %d/%d" % [current_floor + 1, enemy_health, enemy_max_health]

func _process(_delta):
	pass
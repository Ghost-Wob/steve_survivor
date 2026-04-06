extends CanvasLayer
class_name GameUI

# =========================
# REFS
# =========================
var player: Player = null

# Health panel
var health_bar_fill: ColorRect
var health_label: Label

# Apple
var apple_icon_label: Label

# Materials panel
var material_labels: Dictionary = {}

# Weapon slots panel
var weapon_slots_ui: Array = []  # Array of Dictionary {panel, icon, dur_fill, dur_label}

# =========================
# INIT
# =========================
func _ready() -> void:
	_build_health_panel()
	_build_materials_panel()
	_build_weapon_slots_panel()
	
	await get_tree().create_timer(0.2).timeout
	_find_player()

func _find_player() -> void:
	var players := get_tree().get_nodes_in_group("player")
	if players.size() == 0 or not players[0] is Player:
		return
	player = players[0] as Player
	player.health_changed.connect(_on_health_changed)
	player.material_changed.connect(_on_material_changed)
	player.apple_changed.connect(_on_apple_changed)
	player.weapons_changed.connect(_on_weapons_changed)
	_refresh_all()

# =========================
# PANEL : HEALTH (haut gauche)
# =========================
func _build_health_panel() -> void:
	var panel := PanelContainer.new()
	add_child(panel)
	
	var style := _make_style(Color(0.08, 0.08, 0.08, 0.88), Color(0.25, 0.25, 0.25))
	panel.add_theme_stylebox_override("panel", style)
	panel.anchor_left   = 0.0
	panel.anchor_right  = 0.0
	panel.anchor_top    = 0.0
	panel.anchor_bottom = 0.0
	panel.offset_left   = 10
	panel.offset_right  = 200
	panel.offset_top    = 10
	panel.offset_bottom = 70
	
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	panel.add_child(vbox)
	
	# Titre + label HP
	var top_row := HBoxContainer.new()
	vbox.add_child(top_row)
	
	var hp_title := Label.new()
	hp_title.text = "❤ HP"
	hp_title.add_theme_font_size_override("font_size", 13)
	hp_title.add_theme_color_override("font_color", Color(0.9, 0.3, 0.3))
	top_row.add_child(hp_title)
	
	# Spacer
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_row.add_child(spacer)
	
	health_label = Label.new()
	health_label.text = "20 / 20"
	health_label.add_theme_font_size_override("font_size", 13)
	health_label.add_theme_color_override("font_color", Color.WHITE)
	top_row.add_child(health_label)
	
	# Barre de vie (fond gris + fill vert)
	var bar_bg := ColorRect.new()
	bar_bg.color = Color(0.2, 0.2, 0.2)
	bar_bg.custom_minimum_size = Vector2(0, 12)
	bar_bg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(bar_bg)
	
	health_bar_fill = ColorRect.new()
	health_bar_fill.color = Color(0.2, 0.85, 0.2)
	health_bar_fill.size = Vector2(160, 12)
	bar_bg.add_child(health_bar_fill)
	
	# Pommes (icône + stock)
	var apple_row := HBoxContainer.new()
	apple_row.add_theme_constant_override("separation", 6)
	vbox.add_child(apple_row)
	
	var apple_tex := TextureRect.new()
	apple_tex.custom_minimum_size = Vector2(16, 16)
	apple_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	apple_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var apple_path := GlobalData.TEXTURE_PATHS["apple"]
	if ResourceLoader.exists(apple_path):
		apple_tex.texture = load(apple_path)
	apple_row.add_child(apple_tex)
	
	apple_icon_label = Label.new()
	apple_icon_label.text = "0 en stock"
	apple_icon_label.add_theme_font_size_override("font_size", 12)
	apple_icon_label.add_theme_color_override("font_color", Color(0.9, 0.5, 0.5))
	apple_row.add_child(apple_icon_label)

# =========================
# PANEL : MATÉRIAUX (haut droit)
# =========================
func _build_materials_panel() -> void:
	var panel := PanelContainer.new()
	add_child(panel)
	
	var style := _make_style(Color(0.08, 0.08, 0.08, 0.88), Color(0.25, 0.25, 0.25))
	panel.add_theme_stylebox_override("panel", style)
	panel.anchor_left   = 1.0
	panel.anchor_right  = 1.0
	panel.anchor_top    = 0.0
	panel.offset_left   = -155
	panel.offset_right  = -10
	panel.offset_top    = 10
	
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 3)
	panel.add_child(vbox)
	
	var title := Label.new()
	title.text = "MATÉRIAUX"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 12)
	title.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	vbox.add_child(title)
	
	var sep := HSeparator.new()
	vbox.add_child(sep)
	
	for mat_type in GlobalData.MATERIAL_ORDER:
		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 6)
		vbox.add_child(hbox)
		
		var icon := TextureRect.new()
		icon.custom_minimum_size = Vector2(18, 18)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		var path: String = GlobalData.TEXTURE_PATHS.get(mat_type, "")
		if path != "" and ResourceLoader.exists(path):
			icon.texture = load(path)
		hbox.add_child(icon)
		
		var name_label := Label.new()
		name_label.text = mat_type.capitalize()
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_label.add_theme_font_size_override("font_size", 12)
		name_label.add_theme_color_override("font_color", _mat_color(mat_type))
		hbox.add_child(name_label)
		
		var count_label := Label.new()
		count_label.text = "0"
		count_label.custom_minimum_size = Vector2(28, 0)
		count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		count_label.add_theme_font_size_override("font_size", 12)
		count_label.add_theme_color_override("font_color", Color.WHITE)
		hbox.add_child(count_label)
		
		material_labels[mat_type] = count_label

# =========================
# PANEL : ARMES (bas centre)
# =========================
func _build_weapon_slots_panel() -> void:
	var panel := PanelContainer.new()
	add_child(panel)
	
	var style := _make_style(Color(0.08, 0.08, 0.08, 0.88), Color(0.25, 0.25, 0.25))
	panel.add_theme_stylebox_override("panel", style)
	
	# Centré en bas
	panel.anchor_left   = 0.5
	panel.anchor_right  = 0.5
	panel.anchor_top    = 1.0
	panel.anchor_bottom = 1.0
	panel.offset_left   = -265
	panel.offset_right  = 265
	panel.offset_top    = -75
	panel.offset_bottom = -10
	
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	panel.add_child(vbox)
	
	var title := Label.new()
	title.text = "ARMES"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 11)
	title.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	vbox.add_child(title)
	
	var slots_row := HBoxContainer.new()
	slots_row.add_theme_constant_override("separation", 4)
	slots_row.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(slots_row)
	
	# 10 slots
	for i in range(10):
		var slot_data := _build_weapon_slot(slots_row, i)
		weapon_slots_ui.append(slot_data)

func _build_weapon_slot(parent: HBoxContainer, _index: int) -> Dictionary:
	var slot_panel := PanelContainer.new()
	var slot_style := _make_style(Color(0.15, 0.15, 0.15), Color(0.35, 0.35, 0.35))
	slot_panel.add_theme_stylebox_override("panel", slot_style)
	slot_panel.custom_minimum_size = Vector2(44, 44)
	parent.add_child(slot_panel)
	
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	slot_panel.add_child(vbox)
	
	# Icône du tier
	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(24, 24)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox.add_child(icon)
	
	# Barre de durabilité (fond gris + fill coloré)
	var dur_bg := ColorRect.new()
	dur_bg.color = Color(0.15, 0.15, 0.15)
	dur_bg.custom_minimum_size = Vector2(36, 5)
	dur_bg.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox.add_child(dur_bg)
	
	var dur_fill := ColorRect.new()
	dur_fill.color = Color(0.2, 0.85, 0.2)
	dur_fill.size = Vector2(36, 5)
	dur_bg.add_child(dur_fill)
	
	# Label durabilité (ex: "∞" ou "3/5")
	var dur_label := Label.new()
	dur_label.text = "∞"
	dur_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dur_label.add_theme_font_size_override("font_size", 9)
	dur_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	dur_label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox.add_child(dur_label)
	
	return {
		"panel":     slot_panel,
		"icon":      icon,
		"dur_fill":  dur_fill,
		"dur_label": dur_label
	}

# =========================
# REFRESH
# =========================
func _refresh_all() -> void:
	if not is_instance_valid(player):
		return
	_refresh_health(player.health, player.max_health)
	_refresh_apple(player.apple_stock)
	for mat_type in GlobalData.MATERIAL_ORDER:
		_refresh_material(mat_type, player.get_material_count(mat_type))
	_refresh_weapons()

func _refresh_health(hp: int, max_hp: int) -> void:
	if not health_bar_fill:
		return
	var percent := float(hp) / float(max_hp)
	# La barre fait 160px de large (panel 180 - marges)
	health_bar_fill.size.x = 160.0 * percent
	health_label.text = str(hp) + " / " + str(max_hp)
	
	if percent > 0.5:
		health_bar_fill.color = Color(0.2, 0.85, 0.2)
	elif percent > 0.25:
		health_bar_fill.color = Color(0.9, 0.7, 0.1)
	else:
		health_bar_fill.color = Color(0.85, 0.15, 0.15)

func _refresh_apple(stock: int) -> void:
	if apple_icon_label:
		apple_icon_label.text = str(stock) + " en stock"

func _refresh_material(mat_type: String, count: int) -> void:
	if material_labels.has(mat_type):
		material_labels[mat_type].text = str(count)

func _refresh_weapons() -> void:
	if not is_instance_valid(player):
		return
	
	for i in range(weapon_slots_ui.size()):
		var slot_data: Dictionary = weapon_slots_ui[i]
		
		if i >= player.equipped_weapons.size() or not is_instance_valid(player.equipped_weapons[i]):
			# Slot vide
			slot_data["icon"].texture = null
			slot_data["dur_fill"].size.x = 0
			slot_data["dur_label"].text = ""
			continue
		
		var weapon: Weapon = player.equipped_weapons[i]
		var tier_name := weapon.get_tier_name()
		
		# Icône
		var tex_path: String = ""
		if tier_name == "stick":
			tex_path = GlobalData.TEXTURE_PATHS.get("stick", "")
		else:
			tex_path = "res://Asset/pixel_art/weapons/swords/" + tier_name + "_sword.png"
		if tex_path != "" and ResourceLoader.exists(tex_path):
			slot_data["icon"].texture = load(tex_path)
		
		# Durabilité
		if weapon.durability == Weapon.INFINITE_DURABILITY:
			slot_data["dur_fill"].size.x = 36
			slot_data["dur_fill"].color = Color(0.4, 0.4, 0.4)
			slot_data["dur_label"].text = "∞"
		else:
			var percent := float(weapon.durability) / float(weapon.max_durability)
			slot_data["dur_fill"].size.x = 36.0 * percent
			slot_data["dur_label"].text = str(weapon.durability) + "/" + str(weapon.max_durability)
			
			# Couleur barre selon état
			if percent > 0.5:
				slot_data["dur_fill"].color = Color(0.2, 0.85, 0.2)
			elif percent > 0.25:
				slot_data["dur_fill"].color = Color(0.9, 0.7, 0.1)
			else:
				slot_data["dur_fill"].color = Color(0.85, 0.15, 0.15)
		
		# Teinte du panneau selon tier
		var panel_style := _make_style(
			Color(0.15, 0.15, 0.15),
			_mat_color(tier_name) * 0.6
		)
		slot_data["panel"].add_theme_stylebox_override("panel", panel_style)

# =========================
# SIGNALS
# =========================
func _on_health_changed(hp: int, max_hp: int) -> void:
	_refresh_health(hp, max_hp)

func _on_material_changed(mat_type: String, total: int) -> void:
	_refresh_material(mat_type, total)
	# Flash sur le label
	if material_labels.has(mat_type):
		var label: Label = material_labels[mat_type]
		label.modulate = Color(2.5, 2.5, 2.5, 1)
		var tween := create_tween()
		tween.tween_property(label, "modulate", Color.WHITE, 0.25)

func _on_apple_changed(stock: int) -> void:
	_refresh_apple(stock)

func _on_weapons_changed() -> void:
	_refresh_weapons()

# =========================
# UTILS
# =========================
func _make_style(bg: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.set_border_width_all(2)
	style.border_color = border
	style.set_content_margin_all(6)
	style.set_corner_radius_all(4)
	return style

func _mat_color(mat_type: String) -> Color:
	match mat_type:
		"stick":     return Color(0.6, 0.4, 0.2)
		"wooden":    return Color(0.8, 0.6, 0.3)
		"stone":     return Color(0.6, 0.6, 0.6)
		"gold":      return Color.GOLD
		"iron":      return Color(0.85, 0.85, 0.85)
		"diamond":   return Color(0.3, 0.9, 0.9)
		"netherite": return Color(0.5, 0.35, 0.45)
		_:           return Color.WHITE

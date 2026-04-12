extends CanvasLayer
class_name GameUI

# =========================
# REFS
# =========================
var player: Player = null

# Health + XP (haut gauche)
var health_bar_fill: ColorRect
var health_label: Label
var apple_icon_label: Label
var xp_bar_fill: ColorRect
var xp_label: Label
var level_label: Label

# Armures (haut gauche sous HP)
var armor_icons: Dictionary = {}  # "boots" → TextureRect

# Materials (haut droit)
var material_labels: Dictionary = {}
var material_rows: Dictionary   = {}

# Weapons (bas centre)
var weapon_slot_buttons: Array = []

# =========================
# INIT
# =========================
func _ready() -> void:
	var base := Control.new()
	base.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(base)

	_build_health_panel(base)
	_build_materials_panel(base)
	_build_weapon_slots_panel(base)

	await get_tree().create_timer(0.2).timeout
	_find_player()

func _find_player() -> void:
	var players := get_tree().get_nodes_in_group("player")
	if players.size() == 0 or not players[0] is Player: return
	player = players[0] as Player
	player.health_changed.connect(_on_health_changed)
	player.material_changed.connect(_on_material_changed)
	player.apple_changed.connect(_on_apple_changed)
	player.weapons_changed.connect(_on_weapons_changed)
	player.armor_changed.connect(_on_armor_changed)
	player.xp_changed.connect(_on_xp_changed)
	player.level_up.connect(_on_level_up)
	_refresh_all()

# =========================
# PANEL SANTÉ + XP + ARMURES (haut gauche)
# =========================
func _build_health_panel(base: Control) -> void:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _make_style(Color(0.08,0.08,0.08,0.88), Color(0.25,0.25,0.25)))
	panel.anchor_left = 0.0; panel.anchor_right  = 0.0
	panel.anchor_top  = 0.0; panel.anchor_bottom = 0.0
	panel.offset_left = 10;  panel.offset_right  = 240
	panel.offset_top  = 10;  panel.offset_bottom = 140
	base.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	panel.add_child(vbox)

	# --- HP ---
	var row_hp := HBoxContainer.new()
	vbox.add_child(row_hp)
	var lbl_hp := Label.new()
	lbl_hp.text = "❤ HP"
	lbl_hp.add_theme_font_size_override("font_size", 13)
	lbl_hp.add_theme_color_override("font_color", Color(0.9,0.3,0.3))
	row_hp.add_child(lbl_hp)
	var sp1 := Control.new(); sp1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row_hp.add_child(sp1)
	health_label = Label.new()
	health_label.text = "20 / 20"
	health_label.add_theme_font_size_override("font_size", 13)
	health_label.add_theme_color_override("font_color", Color.WHITE)
	row_hp.add_child(health_label)

	var hp_bg := ColorRect.new()
	hp_bg.color = Color(0.2,0.2,0.2)
	hp_bg.custom_minimum_size   = Vector2(0,10)
	hp_bg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hp_bg.clip_children         = CanvasItem.CLIP_CHILDREN_ONLY
	vbox.add_child(hp_bg)
	health_bar_fill = ColorRect.new()
	health_bar_fill.color = Color(0.2,0.85,0.2)
	health_bar_fill.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hp_bg.add_child(health_bar_fill)

	# --- Pommes ---
	var row_ap := HBoxContainer.new()
	row_ap.add_theme_constant_override("separation", 5)
	vbox.add_child(row_ap)
	var ap_tex := TextureRect.new()
	ap_tex.custom_minimum_size = Vector2(14,14)
	ap_tex.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
	ap_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var ap_path: String = GlobalData.TEXTURE_PATHS["apple"]
	if ResourceLoader.exists(ap_path): ap_tex.texture = load(ap_path)
	row_ap.add_child(ap_tex)
	apple_icon_label = Label.new()
	apple_icon_label.text = "0 en stock"
	apple_icon_label.add_theme_font_size_override("font_size", 11)
	apple_icon_label.add_theme_color_override("font_color", Color(0.9,0.5,0.5))
	row_ap.add_child(apple_icon_label)

	vbox.add_child(HSeparator.new())

	# --- XP ---
	var row_xp := HBoxContainer.new()
	row_xp.add_theme_constant_override("separation", 5)
	vbox.add_child(row_xp)
	var xp_icon := TextureRect.new()
	xp_icon.custom_minimum_size = Vector2(14,14)
	xp_icon.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
	xp_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var xp_path: String = GlobalData.TEXTURE_PATHS["xp_orb"]
	if ResourceLoader.exists(xp_path): xp_icon.texture = load(xp_path)
	row_xp.add_child(xp_icon)
	level_label = Label.new()
	level_label.text = "Niv. 1"
	level_label.add_theme_font_size_override("font_size", 12)
	level_label.add_theme_color_override("font_color", Color(0.4,0.9,0.4))
	row_xp.add_child(level_label)
	var sp2 := Control.new(); sp2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row_xp.add_child(sp2)
	xp_label = Label.new()
	xp_label.text = "0 XP"
	xp_label.add_theme_font_size_override("font_size", 11)
	xp_label.add_theme_color_override("font_color", Color(0.6,0.9,0.4))
	row_xp.add_child(xp_label)

	var xp_bg := ColorRect.new()
	xp_bg.color = Color(0.15,0.15,0.15)
	xp_bg.custom_minimum_size   = Vector2(0,6)
	xp_bg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	xp_bg.clip_children         = CanvasItem.CLIP_CHILDREN_ONLY
	vbox.add_child(xp_bg)
	xp_bar_fill = ColorRect.new()
	xp_bar_fill.color = Color(0.3,0.85,0.25)
	xp_bar_fill.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	xp_bg.add_child(xp_bar_fill)

	vbox.add_child(HSeparator.new())

	# --- Armures (4 icônes côte à côte) ---
	var armor_row := HBoxContainer.new()
	armor_row.add_theme_constant_override("separation", 4)
	armor_row.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(armor_row)

	for piece in GlobalData.ARMOR_ORDER:
		var slot_panel := PanelContainer.new()
		slot_panel.add_theme_stylebox_override("panel",
			_make_style(Color(0.12,0.12,0.12), Color(0.3,0.3,0.3)))
		slot_panel.custom_minimum_size = Vector2(34,34)
		armor_row.add_child(slot_panel)
		var icon := TextureRect.new()
		icon.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		icon.modulate     = Color(0.35,0.35,0.35,0.5)  # grisé avant craft
		slot_panel.add_child(icon)
		armor_icons[piece] = icon

# =========================
# PANEL MATÉRIAUX (haut droit)
# Masqué si 0 et inutile ; "∞" si inutile mais en stock
# =========================
func _build_materials_panel(base: Control) -> void:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _make_style(Color(0.08,0.08,0.08,0.88), Color(0.25,0.25,0.25)))
	panel.anchor_left  = 1.0; panel.anchor_right  = 1.0
	panel.anchor_top   = 0.0; panel.anchor_bottom = 0.0
	panel.offset_left  = -165; panel.offset_right = -10
	panel.offset_top   = 10;  panel.offset_bottom = 10
	base.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 3)
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "MATÉRIAUX"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 11)
	title.add_theme_color_override("font_color", Color(0.7,0.7,0.7))
	vbox.add_child(title)
	vbox.add_child(HSeparator.new())

	for mat_type in GlobalData.MATERIAL_ORDER:
		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 5)
		hbox.visible = false
		vbox.add_child(hbox)
		material_rows[mat_type] = hbox

		var icon := TextureRect.new()
		icon.custom_minimum_size = Vector2(16,16)
		icon.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		var path: String = GlobalData.TEXTURE_PATHS.get(mat_type,"")
		if path != "" and ResourceLoader.exists(path): icon.texture = load(path)
		hbox.add_child(icon)

		var name_lbl := Label.new()
		name_lbl.text = mat_type.capitalize()
		name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_lbl.add_theme_font_size_override("font_size", 12)
		name_lbl.add_theme_color_override("font_color", _mat_color(mat_type))
		hbox.add_child(name_lbl)

		var count_lbl := Label.new()
		count_lbl.text = "0"
		count_lbl.custom_minimum_size  = Vector2(30,0)
		count_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		count_lbl.add_theme_font_size_override("font_size", 12)
		count_lbl.add_theme_color_override("font_color", Color.WHITE)
		hbox.add_child(count_lbl)

		material_labels[mat_type] = count_lbl

# =========================
# PANEL ARMES (bas centre)
# =========================
func _build_weapon_slots_panel(base: Control) -> void:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _make_style(Color(0.08,0.08,0.08,0.88), Color(0.25,0.25,0.25)))
	panel.anchor_left  = 0.5; panel.anchor_right  = 0.5
	panel.anchor_top   = 1.0; panel.anchor_bottom = 1.0
	panel.offset_left  = -270; panel.offset_right = 270
	panel.offset_top   = -80;  panel.offset_bottom = -10
	base.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 3)
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "ARMES  [clic = activer/désactiver]"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 10)
	title.add_theme_color_override("font_color", Color(0.55,0.55,0.55))
	vbox.add_child(title)

	var slots_row := HBoxContainer.new()
	slots_row.add_theme_constant_override("separation", 4)
	slots_row.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(slots_row)
	for i in range(10):
		weapon_slot_buttons.append(_build_weapon_slot(slots_row, i))

func _build_weapon_slot(parent: HBoxContainer, idx: int) -> Dictionary:
	var btn := Button.new()
	btn.flat = true
	btn.custom_minimum_size = Vector2(46,46)
	btn.add_theme_stylebox_override("normal",  _make_style(Color(0.15,0.15,0.15), Color(0.35,0.35,0.35)))
	btn.add_theme_stylebox_override("hover",   _make_style(Color(0.22,0.22,0.22), Color(0.6,0.6,0.6)))
	btn.add_theme_stylebox_override("pressed", _make_style(Color(0.10,0.10,0.10), Color(0.8,0.8,0.8)))
	btn.add_theme_stylebox_override("focus",   _make_style(Color(0.15,0.15,0.15), Color(0.35,0.35,0.35)))
	var si := idx
	btn.pressed.connect(func(): _on_slot_clicked(si))
	parent.add_child(btn)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	btn.add_child(vbox)

	var icon := TextureRect.new()
	icon.custom_minimum_size   = Vector2(24,24)
	icon.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox.add_child(icon)

	var dur_bg := ColorRect.new()
	dur_bg.color = Color(0.12,0.12,0.12)
	dur_bg.custom_minimum_size   = Vector2(36,5)
	dur_bg.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	dur_bg.clip_children         = CanvasItem.CLIP_CHILDREN_ONLY
	vbox.add_child(dur_bg)
	var dur_fill := ColorRect.new()
	dur_fill.color = Color(0.4,0.4,0.4)
	dur_fill.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dur_bg.add_child(dur_fill)

	var dur_lbl := Label.new()
	dur_lbl.text = "∞"
	dur_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dur_lbl.add_theme_font_size_override("font_size", 9)
	dur_lbl.add_theme_color_override("font_color", Color(0.6,0.6,0.6))
	dur_lbl.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox.add_child(dur_lbl)

	return {"btn": btn, "icon": icon, "dur_fill": dur_fill, "dur_label": dur_lbl}

func _on_slot_clicked(idx: int) -> void:
	if is_instance_valid(player): player.toggle_weapon_slot(idx)

# =========================
# REFRESH
# =========================
func _refresh_all() -> void:
	if not is_instance_valid(player): return
	_refresh_health(player.health, player.max_health)
	_refresh_apple(player.apple_stock)
	for mat in GlobalData.MATERIAL_ORDER:
		_refresh_material(mat, player.get_material_count(mat))
	_refresh_weapons()
	_refresh_armor()
	_refresh_xp(player.xp, player._xp_for_next_level(), player.player_level)

func _refresh_health(hp: int, max_hp: int) -> void:
	if not health_bar_fill or not health_label: return
	var pct := float(hp) / float(max_hp)
	health_bar_fill.scale.x = pct
	health_label.text = str(hp) + " / " + str(max_hp)
	if pct > 0.5:     health_bar_fill.color = Color(0.2,0.85,0.2)
	elif pct > 0.25:  health_bar_fill.color = Color(0.9,0.7,0.1)
	else:             health_bar_fill.color = Color(0.85,0.15,0.15)

func _refresh_apple(stock: int) -> void:
	if apple_icon_label: apple_icon_label.text = str(stock) + " en stock"

func _refresh_material(mat_type: String, count: int) -> void:
	if not is_instance_valid(player): return
	var useless := player.is_material_useless(mat_type)

	if material_rows.has(mat_type):
		# Visible si on en a, ou si c'est inutile (pour montrer ∞)
		material_rows[mat_type].visible = count > 0 or (useless and count > 0)
		# En fait : visible si on en a OU si conversion active
		material_rows[mat_type].visible = count > 0

	if material_labels.has(mat_type):
		if useless and count > 0:
			material_labels[mat_type].text = "∞"
			material_labels[mat_type].add_theme_color_override("font_color", Color(0.5,0.5,0.5))
		elif count > 0:
			material_labels[mat_type].text = str(count)
			material_labels[mat_type].add_theme_color_override("font_color", Color.WHITE)

func _refresh_weapons() -> void:
	if not is_instance_valid(player): return
	for i in range(weapon_slot_buttons.size()):
		var slot: Dictionary = weapon_slot_buttons[i]
		if i >= player.equipped_weapons.size() \
				or not is_instance_valid(player.equipped_weapons[i]):
			slot["icon"].texture     = null
			slot["dur_fill"].scale.x = 0
			slot["dur_label"].text   = ""
			continue

		var weapon: Weapon = player.equipped_weapons[i]
		var tn      := weapon.get_tier_name()
		var enabled := weapon.is_enabled

		var tex: String = GlobalData.get_weapon_texture_path(tn)
		if tex != "" and ResourceLoader.exists(tex):
			slot["icon"].texture = load(tex)

		slot["btn"].modulate = Color.WHITE if enabled else Color(0.38,0.38,0.38,0.65)

		if weapon.durability == Weapon.INFINITE_DURABILITY:
			slot["dur_fill"].scale.x = 1.0
			slot["dur_fill"].color   = Color(0.4,0.4,0.4)
			slot["dur_label"].text   = "∞"
		else:
			var pct := float(weapon.durability) / float(weapon.max_durability)
			slot["dur_fill"].scale.x = pct
			slot["dur_label"].text   = str(weapon.durability)+"/"+str(weapon.max_durability)
			slot["dur_fill"].color   = Color(0.2,0.85,0.2) if pct > 0.5 \
				else (Color(0.9,0.7,0.1) if pct > 0.25 else Color(0.85,0.15,0.15))

		var bc := _mat_color(tn) * (0.7 if enabled else 0.25)
		slot["btn"].add_theme_stylebox_override("normal",
			_make_style(Color(0.15,0.15,0.15), bc))

func _refresh_armor() -> void:
	if not is_instance_valid(player): return
	for piece in GlobalData.ARMOR_ORDER:
		if not armor_icons.has(piece): continue
		var icon: TextureRect = armor_icons[piece]
		var tier: int         = player.armor_tiers[piece]
		if tier < 0:
			# Non craftée : icône grisée du tier 0 (copper) pour visualiser l'emplacement
			var placeholder: String = GlobalData.get_armor_texture(0, piece)
			if ResourceLoader.exists(placeholder): icon.texture = load(placeholder)
			icon.modulate = Color(0.3,0.3,0.3,0.4)
		else:
			var tex_path: String = GlobalData.get_armor_texture(tier, piece)
			if ResourceLoader.exists(tex_path): icon.texture = load(tex_path)
			icon.modulate = Color.WHITE

func _refresh_xp(cur_xp: int, xp_next: int, level: int) -> void:
	if not xp_bar_fill or not xp_label or not level_label: return
	if level >= GlobalData.MAX_LEVEL:
		xp_bar_fill.scale.x = 1.0
		xp_bar_fill.color   = Color.GOLD
		level_label.text    = "Niv. MAX"
		xp_label.text       = "MAX"
		return
	var pct := player.get_xp_progress() if is_instance_valid(player) else 0.0
	xp_bar_fill.scale.x = pct
	level_label.text     = "Niv. " + str(level)
	xp_label.text        = str(cur_xp) + " / " + str(xp_next) + " XP"

# =========================
# SIGNALS
# =========================
func _on_health_changed(hp: int, max_hp: int) -> void:
	_refresh_health(hp, max_hp)

func _on_material_changed(mat_type: String, total: int) -> void:
	_refresh_material(mat_type, total)
	if material_labels.has(mat_type) and total > 0 \
			and not (is_instance_valid(player) and player.is_material_useless(mat_type)):
		var lbl: Label = material_labels[mat_type]
		lbl.modulate = Color(2.5,2.5,2.5,1)
		create_tween().tween_property(lbl, "modulate", Color.WHITE, 0.25)

func _on_apple_changed(stock: int) -> void: _refresh_apple(stock)

func _on_weapons_changed() -> void:
	_refresh_weapons()
	if is_instance_valid(player):
		for mat in GlobalData.MATERIAL_ORDER:
			_refresh_material(mat, player.get_material_count(mat))

func _on_armor_changed() -> void: _refresh_armor()

func _on_xp_changed(cur_xp: int, xp_next: int, level: int) -> void:
	_refresh_xp(cur_xp, xp_next, level)

func _on_level_up(new_level: int) -> void:
	_refresh_xp(player.xp, player._xp_for_next_level(), new_level)
	if level_label:
		level_label.modulate = Color(3,3,1,1)
		create_tween().tween_property(level_label, "modulate", Color.WHITE, 0.5)

# =========================
# UTILS
# =========================
func _make_style(bg: Color, border: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.set_border_width_all(2)
	s.border_color = border
	s.set_content_margin_all(5)
	s.set_corner_radius_all(4)
	return s

func _mat_color(mat_type: String) -> Color:
	match mat_type:
		"stick":     return Color(0.6,  0.4,  0.2)
		"wooden":    return Color(0.8,  0.6,  0.3)
		"stone":     return Color(0.6,  0.6,  0.6)
		"gold":      return Color.GOLD
		"iron":      return Color(0.85, 0.85, 0.85)
		"diamond":   return Color(0.3,  0.9,  0.9)
		"netherite": return Color(0.5,  0.35, 0.45)
		_:           return Color.WHITE

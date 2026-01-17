extends CanvasLayer
class_name GameUI

# =========================
# CONFIG
# =========================
const TEXTURE_PATHS: Dictionary = {
	"stick": "res://Asset/pixel_art/items/stick.png",
	"wooden": "res://Asset/pixel_art/items/oak_planks.png",
	"stone": "res://Asset/pixel_art/items/stone.png",
	"gold": "res://Asset/pixel_art/items/gold_ingot.png",
	"iron": "res://Asset/pixel_art/items/iron_ingot.png",
	"diamond": "res://Asset/pixel_art/items/diamond.png",
	"netherite": "res://Asset/pixel_art/items/netherite_ingot.png"
}

const MATERIAL_ORDER: Array[String] = ["stick", "wooden", "stone", "gold", "iron", "diamond", "netherite"]

# =========================
# NODES
# =========================
var material_labels: Dictionary = {}
var weapons_label: Label
var player: Player = null

# =========================
# INIT
# =========================
func _ready() -> void:
	_create_ui()
	await get_tree().create_timer(0.2).timeout
	_find_player()

func _find_player() -> void:
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0 and players[0] is Player:
		player = players[0] as Player
		player.material_changed.connect(_on_material_changed)
		player.weapons_changed.connect(_on_weapons_changed)
		_update_all()

func _create_ui() -> void:
	# Panel
	var panel := PanelContainer.new()
	add_child(panel)
	
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.1, 0.85)
	style.set_border_width_all(2)
	style.border_color = Color(0.3, 0.3, 0.3)
	style.set_content_margin_all(8)
	panel.add_theme_stylebox_override("panel", style)
	
	# Position top right
	panel.anchor_left = 1.0
	panel.anchor_right = 1.0
	panel.offset_left = -140
	panel.offset_right = -10
	panel.offset_top = 10
	
	# Content
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	panel.add_child(vbox)
	
	# Title
	var title := Label.new()
	title.text = "INVENTORY"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", Color.WHITE)
	vbox.add_child(title)
	
	# Separator
	var sep := HSeparator.new()
	vbox.add_child(sep)
	
	# Material rows
	for mat_type in MATERIAL_ORDER:
		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 6)
		vbox.add_child(hbox)
		
		# Icon
		var icon := TextureRect.new()
		icon.custom_minimum_size = Vector2(20, 20)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		if TEXTURE_PATHS.has(mat_type) and ResourceLoader.exists(TEXTURE_PATHS[mat_type]):
			icon.texture = load(TEXTURE_PATHS[mat_type])
		hbox.add_child(icon)
		
		# Label
		var label := Label.new()
		label.text = "0"
		label.custom_minimum_size = Vector2(40, 0)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		label.add_theme_font_size_override("font_size", 14)
		label.add_theme_color_override("font_color", _get_material_color(mat_type))
		hbox.add_child(label)
		
		material_labels[mat_type] = label
	
	# Separator
	var sep2 := HSeparator.new()
	vbox.add_child(sep2)
	
	# Weapons label
	weapons_label = Label.new()
	weapons_label.text = "Sticks: 10"
	weapons_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	weapons_label.add_theme_font_size_override("font_size", 12)
	weapons_label.add_theme_color_override("font_color", Color.WHITE)
	vbox.add_child(weapons_label)

func _get_material_color(mat_type: String) -> Color:
	match mat_type:
		"stick": return Color(0.6, 0.4, 0.2)
		"wooden": return Color(0.8, 0.6, 0.3)
		"stone": return Color(0.6, 0.6, 0.6)
		"gold": return Color.GOLD
		"iron": return Color(0.85, 0.85, 0.85)
		"diamond": return Color(0.3, 0.9, 0.9)
		"netherite": return Color(0.4, 0.3, 0.35)
		_: return Color.WHITE

func _update_all() -> void:
	if not is_instance_valid(player):
		return
	
	for mat_type in MATERIAL_ORDER:
		var count := player.get_material_count(mat_type)
		if material_labels.has(mat_type):
			material_labels[mat_type].text = str(count)
	
	var weapon_count := player.get_weapon_count()
	weapons_label.text = "Sticks: " + str(weapon_count)

func _on_material_changed(mat_type: String, total: int) -> void:
	if material_labels.has(mat_type):
		var label: Label = material_labels[mat_type]
		label.text = str(total)
		
		# Flash effect
		label.modulate = Color(2, 2, 2, 1)
		var tween := create_tween()
		tween.tween_property(label, "modulate", Color.WHITE, 0.2)

func _on_weapons_changed() -> void:
	if is_instance_valid(player):
		var count := player.get_weapon_count()
		weapons_label.text = "Sticks: " + str(count)

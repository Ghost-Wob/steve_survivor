extends CanvasLayer
class_name CraftMenu

# =========================
# CRAFT RECIPES
# =========================
const RECIPES: Array[Dictionary] = [
	{
		"name": "Wooden Sword",
		"result": "wooden_sword",
		"cost": {"stick": 1, "wooden": 2},
		"tier": 1
	},
	{
		"name": "Stone Sword",
		"result": "stone_sword",
		"cost": {"stick": 1, "stone": 2},
		"tier": 2
	},
	{
		"name": "Gold Sword",
		"result": "gold_sword",
		"cost": {"stick": 1, "gold": 2},
		"tier": 3
	},
	{
		"name": "Iron Sword",
		"result": "iron_sword",
		"cost": {"stick": 1, "iron": 2},
		"tier": 4
	},
	{
		"name": "Diamond Sword",
		"result": "diamond_sword",
		"cost": {"stick": 1, "diamond": 2},
		"tier": 5
	},
	{
		"name": "Netherite Sword",
		"result": "netherite_sword",
		"cost": {"stick": 1, "netherite": 2},
		"tier": 6
	}
]

# =========================
# STATE
# =========================
var selected_index: int = 0
var player: Player = null
var input_cooldown: float = 0.0
const INPUT_DELAY: float = 0.15

# =========================
# NODES
# =========================
var menu_container: VBoxContainer
var recipe_labels: Array[Label] = []
var info_label: Label

# =========================
# INIT
# =========================
func _ready() -> void:
	await get_tree().create_timer(0.2).timeout
	_find_player()
	_create_menu()
	_update_display()

func _find_player() -> void:
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0 and players[0] is Player:
		player = players[0] as Player
		player.material_changed.connect(_on_material_changed)

func _create_menu() -> void:
	# Main panel
	var panel := PanelContainer.new()
	add_child(panel)
	
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.1, 0.1, 0.95)
	style.set_border_width_all(3)
	style.border_color = Color(0.6, 0.4, 0.2)
	style.set_content_margin_all(15)
	style.set_corner_radius_all(8)
	panel.add_theme_stylebox_override("panel", style)
	
	# Center position
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.anchor_top = 0.0
	panel.offset_left = -150
	panel.offset_right = 150
	panel.offset_top = 20
	
	# Content
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	panel.add_child(vbox)
	
	# Title
	var title := Label.new()
	title.text = "⚔ FORGE ⚔"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color.GOLD)
	vbox.add_child(title)
	
	# Instructions
	var instructions := Label.new()
	instructions.text = "↑↓ Sélectionner  |  → Forger"
	instructions.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	instructions.add_theme_font_size_override("font_size", 12)
	instructions.add_theme_color_override("font_color", Color.GRAY)
	vbox.add_child(instructions)
	
	# Separator
	var sep := HSeparator.new()
	vbox.add_child(sep)
	
	# Recipe container
	menu_container = VBoxContainer.new()
	menu_container.add_theme_constant_override("separation", 5)
	vbox.add_child(menu_container)
	
	# Create recipe labels
	for i in range(RECIPES.size()):
		var recipe := RECIPES[i]
		
		var label := Label.new()
		label.text = recipe.name
		label.add_theme_font_size_override("font_size", 16)
		menu_container.add_child(label)
		recipe_labels.append(label)
	
	# Separator
	var sep2 := HSeparator.new()
	vbox.add_child(sep2)
	
	# Info label (shows costs)
	info_label = Label.new()
	info_label.text = ""
	info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_label.add_theme_font_size_override("font_size", 14)
	info_label.add_theme_color_override("font_color", Color.WHITE)
	vbox.add_child(info_label)

# =========================
# INPUT (WASD Navigation)
# =========================
func _process(delta: float) -> void:
	if input_cooldown > 0:
		input_cooldown -= delta
		return
	
	# Navigation Up (W or Up)
	if Input.is_action_pressed("move_up"):
		selected_index -= 1
		if selected_index < 0:
			selected_index = RECIPES.size() - 1
		input_cooldown = INPUT_DELAY
		_update_display()
	
	# Navigation Down (S or Down)
	elif Input.is_action_pressed("move_down"):
		selected_index += 1
		if selected_index >= RECIPES.size():
			selected_index = 0
		input_cooldown = INPUT_DELAY
		_update_display()
	
	# Craft (D or Right)
	elif Input.is_action_pressed("move_right"):
		_try_craft()
		input_cooldown = INPUT_DELAY * 2

# =========================
# DISPLAY
# =========================
func _update_display() -> void:
	for i in range(recipe_labels.size()):
		var label: Label = recipe_labels[i]
		var recipe: Dictionary = RECIPES[i]
		var can_craft := _can_craft(recipe)
		
		if i == selected_index:
			# Selected
			label.text = "▶ " + recipe.name
			if can_craft:
				label.add_theme_color_override("font_color", Color.GREEN)
			else:
				label.add_theme_color_override("font_color", Color.YELLOW)
		else:
			label.text = "  " + recipe.name
			if can_craft:
				label.add_theme_color_override("font_color", Color.WHITE)
			else:
				label.add_theme_color_override("font_color", Color.DIM_GRAY)
	
	# Update info label with costs
	var selected_recipe: Dictionary = RECIPES[selected_index]
	var cost_text := "Coût: "
	for mat_type in selected_recipe.cost.keys():
		var needed: int = selected_recipe.cost[mat_type]
		var have: int = 0
		if player:
			have = player.get_material_count(mat_type)
		cost_text += mat_type + " " + str(have) + "/" + str(needed) + "  "
	
	info_label.text = cost_text

func _can_craft(recipe: Dictionary) -> bool:
	if not player:
		return false
	
	for mat_type in recipe.cost.keys():
		var needed: int = recipe.cost[mat_type]
		if player.get_material_count(mat_type) < needed:
			return false
	
	return true

# =========================
# CRAFTING
# =========================
func _try_craft() -> void:
	var recipe: Dictionary = RECIPES[selected_index]
	
	if not _can_craft(recipe):
		_show_error()
		return
	
	# Spend materials
	for mat_type in recipe.cost.keys():
		var needed: int = recipe.cost[mat_type]
		player.spend_material(mat_type, needed)
	
	# Upgrade a weapon
	_upgrade_weapon(recipe.tier)
	
	_show_success()
	_update_display()

func _upgrade_weapon(tier: int) -> void:
	if not player:
		return
	
	# Find a weapon with lower tier and upgrade it
	for weapon in player.equipped_weapons:
		if is_instance_valid(weapon) and weapon.get_tier() < tier:
			weapon.upgrade()
			print("[CraftMenu] Upgraded weapon to tier ", tier)
			return
	
	print("[CraftMenu] No weapon to upgrade!")

func _show_success() -> void:
	info_label.text = "✓ FORGÉ AVEC SUCCÈS!"
	info_label.add_theme_color_override("font_color", Color.GREEN)
	
	var tween := create_tween()
	tween.tween_interval(1.0)
	tween.tween_callback(_update_display)

func _show_error() -> void:
	info_label.text = "✗ Ressources insuffisantes!"
	info_label.add_theme_color_override("font_color", Color.RED)
	
	var tween := create_tween()
	tween.tween_interval(1.0)
	tween.tween_callback(_update_display)

func _on_material_changed(_mat_type: String, _total: int) -> void:
	_update_display()

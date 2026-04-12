extends CharacterBody2D
class_name Player

# =========================
# CONFIG
# =========================
@export var move_speed: float         = 128.0
@export var base_max_health: int      = 20
@export var invincibility_time: float = 0.5
@export var pickup_radius: float      = 16.0
@export var joystick_deadzone: float  = 0.2

# Nombre de pixels de jeu visibles en hauteur — constant quelle que soit la résolution
# 180 px → sur 1080p : zoom = 3 (identique à l'actuel)
const TARGET_GAME_HEIGHT: float = 180.0

# =========================
# LEVEL & XP
# =========================
var player_level: int = 1
var xp: int           = 0

# =========================
# WEAPONS
# =========================
const MAX_SLOTS: int = 10
const WEAPON_SCENE_PATH := "res://Scenes_Scripts/weapons/weapon.tscn"

var equipped_weapons: Array[Weapon] = []
var weapon_scene: PackedScene       = null

# =========================
# INVENTORY
# =========================
var materials: Dictionary = {
	"stick": 0, "wooden": 0, "stone": 0,
	"gold":  0, "iron":   0, "diamond": 0, "netherite": 0
}
var apple_stock: int = 0

# =========================
# ARMOR
# =========================
var armor_tiers: Dictionary = {
	"boots": -1, "leggings": -1, "chestplate": -1, "helmet": -1
}

# =========================
# STATE
# =========================
var max_health: int
var health: int
var is_invincible: bool = false

# =========================
# SIGNALS
# =========================
signal health_changed(new_health: int, max_hp: int)
signal material_changed(mat_type: String, total: int)
signal weapons_changed()
signal apple_changed(stock: int)
signal armor_changed()
signal xp_changed(xp: int, xp_next: int, level: int)
signal level_up(new_level: int)
signal player_died()

# =========================
# NODES
# =========================
@onready var health_bar_fill: ColorRect = $HealthBarBG/HealthBarFill
@onready var camera: Camera2D           = $Camera2D
var invincibility_timer: Timer

# =========================
# INIT
# =========================
func _ready() -> void:
	add_to_group("player")
	max_health = base_max_health
	health     = max_health

	_setup_camera()

	invincibility_timer = Timer.new()
	invincibility_timer.one_shot = true
	add_child(invincibility_timer)
	invincibility_timer.timeout.connect(_on_invincibility_end)

	if ResourceLoader.exists(WEAPON_SCENE_PATH):
		weapon_scene = load(WEAPON_SCENE_PATH)
	else:
		push_error("[Player] Weapon scene introuvable : " + WEAPON_SCENE_PATH)

	_update_health_bar()
	await get_tree().create_timer(0.1).timeout
	_give_starting_sticks()

# =========================
# CAMERA — zoom adaptatif
# On veut toujours voir TARGET_GAME_HEIGHT pixels de jeu en hauteur.
# Le Player a scale=2, donc zoom_effectif = scale.y × camera.zoom
# camera.zoom = (viewport_height / TARGET_GAME_HEIGHT) / scale.y
# =========================
func _setup_camera() -> void:
	if not camera: return
	var vp_h   := get_viewport().get_visible_rect().size.y
	var zoom_v := vp_h / (TARGET_GAME_HEIGHT * scale.y)
	camera.zoom = Vector2(zoom_v, zoom_v)

# Recalcul si la fenêtre est redimensionnée (optionnel mais robuste)
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_SIZE_CHANGED:
		_setup_camera()

# =========================
# WEAPONS
# =========================
func _give_starting_sticks() -> void:
	if not weapon_scene: return
	for i in range(MAX_SLOTS):
		var stick: Weapon = weapon_scene.instantiate() as Weapon
		if not stick: continue
		get_parent().add_child(stick)
		equipped_weapons.append(stick)
		stick.attach_to_player(self, i)
	emit_signal("weapons_changed")

func get_weapon_count() -> int:
	var n := 0
	for w in equipped_weapons:
		if is_instance_valid(w): n += 1
	return n

func toggle_weapon_slot(slot_idx: int) -> void:
	if slot_idx >= equipped_weapons.size(): return
	var weapon: Weapon = equipped_weapons[slot_idx]
	if not is_instance_valid(weapon): return
	weapon.set_enabled(not weapon.is_enabled)
	emit_signal("weapons_changed")

# =========================
# MOVEMENT
# =========================
func _physics_process(_delta: float) -> void:
	velocity = _get_movement_input() * move_speed
	move_and_slide()
	_check_nearby_drops()

func _get_movement_input() -> Vector2:
	var kb  := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var joy := Vector2(Input.get_joy_axis(0, JOY_AXIS_LEFT_X),
					   Input.get_joy_axis(0, JOY_AXIS_LEFT_Y))
	if joy.length() < joystick_deadzone:
		joy = Vector2.ZERO
	else:
		joy = joy.normalized() * ((joy.length() - joystick_deadzone) / (1.0 - joystick_deadzone))
	if kb.length()  > 0: return kb.normalized()
	if joy.length() > 0: return joy
	return Vector2.ZERO

func _check_nearby_drops() -> void:
	for drop in get_tree().get_nodes_in_group("drops"):
		if not is_instance_valid(drop): continue
		if global_position.distance_to(drop.global_position) <= pickup_radius:
			if drop.has_method("pickup"):
				drop.pickup(self)

# =========================
# XP / LEVEL
# =========================
func add_xp(amount: int) -> void:
	if player_level >= GlobalData.MAX_LEVEL: return
	xp += amount
	while player_level < GlobalData.MAX_LEVEL \
			and xp >= GlobalData.XP_TABLE[player_level]:
		player_level += 1
		emit_signal("level_up", player_level)
		emit_signal("weapons_changed")
	emit_signal("xp_changed", xp, _xp_for_next_level(), player_level)

func _xp_for_next_level() -> int:
	if player_level >= GlobalData.MAX_LEVEL:
		return GlobalData.XP_TABLE[GlobalData.MAX_LEVEL - 1]
	return GlobalData.XP_TABLE[player_level]

func get_xp_progress() -> float:
	if player_level >= GlobalData.MAX_LEVEL: return 1.0
	var prev: int = GlobalData.XP_TABLE[player_level - 1]
	var next: int = GlobalData.XP_TABLE[player_level]
	return float(xp - prev) / float(next - prev)

# =========================
# CRAFT TABLE
# =========================
func apply_craft_table() -> void:
	print("[CraftTable] Activation !")

	# Épées
	for weapon in equipped_weapons:
		if not is_instance_valid(weapon): continue
		var upgraded := true
		while upgraded:
			upgraded = false
			var ct     := weapon.get_tier()
			if ct >= Weapon.Tier.NETHERITE: break
			var next_n  := Weapon.TIER_NAMES[ct + 1]
			if not GlobalData.UPGRADE_RECIPES.has(next_n): break
			var recipe: Dictionary = GlobalData.UPGRADE_RECIPES[next_n]
			var can    := true
			for mat in recipe.keys():
				if materials.get(mat, 0) < recipe[mat]: can = false; break
			if can:
				for mat in recipe.keys(): spend_material(mat, recipe[mat])
				weapon.upgrade(player_level)
				upgraded = true
	emit_signal("weapons_changed")

	# Armures (boots → leggings → chestplate → helmet)
	for piece in GlobalData.ARMOR_ORDER:
		var crafted := true
		while crafted:
			crafted = false
			var next_tier: int = armor_tiers[piece] + 1
			if next_tier >= GlobalData.ARMOR_MATERIAL_FOR_TIER.size(): break
			var mat:  String = GlobalData.ARMOR_MATERIAL_FOR_TIER[next_tier]
			var cost: int    = GlobalData.ARMOR_COSTS[piece]
			if materials.get(mat, 0) >= cost:
				spend_material(mat, cost)
				armor_tiers[piece] = next_tier
				var hp_bonus: int = GlobalData.ARMOR_HP_PER_PIECE[next_tier]
				max_health += hp_bonus
				health      = mini(health + hp_bonus, max_health)
				_update_health_bar()
				emit_signal("health_changed", health, max_health)
				emit_signal("armor_changed")
				crafted = true

	print("[CraftTable] Terminé.")

# =========================
# MATÉRIAU INUTILE
# =========================
func is_material_useless(mat_type: String) -> bool:
	if mat_type == "apple" or mat_type == "craft_table": return false

	if mat_type == "stick":
		for w in equipped_weapons:
			if is_instance_valid(w) and w.get_tier() < Weapon.Tier.NETHERITE:
				return false
		return true

	for weapon in equipped_weapons:
		if not is_instance_valid(weapon): continue
		var ct := weapon.get_tier()
		if ct >= Weapon.Tier.NETHERITE: continue
		var next_n: String = Weapon.TIER_NAMES[ct + 1]
		if GlobalData.UPGRADE_RECIPES.has(next_n):
			if GlobalData.UPGRADE_RECIPES[next_n].has(mat_type):
				return false

	var mat_tier_idx: int = GlobalData.ARMOR_MATERIAL_FOR_TIER.find(mat_type)
	if mat_tier_idx >= 0:
		for piece in GlobalData.ARMOR_ORDER:
			if armor_tiers[piece] + 1 == mat_tier_idx:
				return false

	return true

# =========================
# CONVERSION 16:1
# =========================
func _check_conversion(mat_type: String) -> void:
	if not GlobalData.MATERIAL_CAP.has(mat_type):    return
	if not GlobalData.CONVERSION_NEXT.has(mat_type): return

	var cap:      int    = GlobalData.MATERIAL_CAP[mat_type]
	var next_mat: String = GlobalData.CONVERSION_NEXT[mat_type]

	while materials.get(mat_type, 0) > cap:
		if materials[mat_type] - cap >= GlobalData.CONVERSION_RATIO:
			materials[mat_type] -= GlobalData.CONVERSION_RATIO
			emit_signal("material_changed", mat_type, materials[mat_type])
			if next_mat == "apple":
				pickup_apple(1)
			else:
				add_material(next_mat, 1)
		else:
			break

# =========================
# COMBAT
# =========================
func take_damage(amount: int) -> void:
	if is_invincible: return
	health -= amount
	health  = maxi(0, health)

	if apple_stock > 0 and health < max_health:
		var used := 0
		while apple_stock > 0 and health < max_health:
			apple_stock -= 1; health += 1; used += 1
		emit_signal("apple_changed", apple_stock)

	_update_health_bar()
	emit_signal("health_changed", health, max_health)
	modulate      = Color.RED
	is_invincible = true
	invincibility_timer.start(invincibility_time)
	if health <= 0: die()

func _on_invincibility_end() -> void:
	is_invincible = false
	modulate      = Color.WHITE

func _update_health_bar() -> void:
	if not health_bar_fill: return
	var pct := float(health) / float(max_health)
	health_bar_fill.size.x = 16.0 * pct
	health_bar_fill.color  = Color(0, 0.9, 0, 1) if pct > 0.1 else Color(0.9, 0, 0, 1)

# =========================
# DEATH / RESPAWN
# =========================
var spawn_points: Array[Vector2] = [Vector2(0, 0)]

func die() -> void:
	emit_signal("player_died")
	for weapon in equipped_weapons:
		if is_instance_valid(weapon): weapon.degrade()
	global_position = spawn_points.pick_random()
	health = max_health; velocity = Vector2.ZERO
	is_invincible = false; modulate = Color.WHITE
	_update_health_bar()
	emit_signal("health_changed", health, max_health)
	emit_signal("weapons_changed")

# =========================
# APPLE
# =========================
func pickup_apple(amount: int = 1) -> void:
	if health < max_health:
		health = mini(health + amount, max_health)
		_update_health_bar()
		emit_signal("health_changed", health, max_health)
	else:
		apple_stock += amount
		emit_signal("apple_changed", apple_stock)

# =========================
# MATERIALS
# =========================
func add_material(mat_type: String, amount: int = 1) -> void:
	if mat_type == "apple":        pickup_apple(amount); return
	if mat_type == "craft_table":  apply_craft_table();  return
	if not materials.has(mat_type): materials[mat_type] = 0
	materials[mat_type] += amount
	emit_signal("material_changed", mat_type, materials[mat_type])
	_check_conversion(mat_type)

func get_material_count(mat_type: String) -> int:
	return materials.get(mat_type, 0)

func get_all_materials() -> Dictionary:
	return materials.duplicate()

func spend_material(mat_type: String, amount: int) -> bool:
	if materials.get(mat_type, 0) >= amount:
		materials[mat_type] -= amount
		emit_signal("material_changed", mat_type, materials[mat_type])
		return true
	return false

func get_lowest_useful_material() -> String:
	for mat_type in GlobalData.MATERIAL_ORDER:
		if mat_type == "stick": continue
		if not is_material_useless(mat_type): return mat_type
	return "netherite"

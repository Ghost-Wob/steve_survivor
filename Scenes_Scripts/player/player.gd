extends CharacterBody2D
class_name Player

# =========================
# CONFIG
# =========================
@export var move_speed: float        = 128.0
@export var max_health: int          = 20
@export var invincibility_time: float = 0.5
@export var pickup_radius: float     = 16.0
@export var joystick_deadzone: float = 0.2

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
var weapon_scene: PackedScene = null

# =========================
# INVENTORY
# =========================
var materials: Dictionary = {
	"stick": 0, "wooden": 0, "stone": 0,
	"gold":  0, "iron":   0, "diamond": 0, "netherite": 0
}
var apple_stock: int = 0

# =========================
# STATE
# =========================
var health: int
var is_invincible: bool = false

# =========================
# SIGNALS
# =========================
signal health_changed(new_health: int, max_hp: int)
signal material_changed(mat_type: String, total: int)
signal weapons_changed()
signal apple_changed(stock: int)
signal xp_changed(xp: int, xp_next: int, level: int)
signal level_up(new_level: int)
signal player_died()

# =========================
# NODES
# =========================
@onready var health_bar_fill: ColorRect = $HealthBarBG/HealthBarFill
var invincibility_timer: Timer

# =========================
# INIT
# =========================
func _ready() -> void:
	add_to_group("player")
	health = max_health

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

func _give_starting_sticks() -> void:
	if not weapon_scene:
		return
	for i in range(MAX_SLOTS):
		var stick: Weapon = weapon_scene.instantiate() as Weapon
		if not stick:
			continue
		get_parent().add_child(stick)
		equipped_weapons.append(stick)
		stick.attach_to_player(self, i)
	emit_signal("weapons_changed")

# =========================
# MOVEMENT
# =========================
func _physics_process(_delta: float) -> void:
	velocity = _get_movement_input() * move_speed
	move_and_slide()
	_check_nearby_drops()

func _get_movement_input() -> Vector2:
	var kb := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var joy_x := Input.get_joy_axis(0, JOY_AXIS_LEFT_X)
	var joy_y := Input.get_joy_axis(0, JOY_AXIS_LEFT_Y)
	var joy   := Vector2(joy_x, joy_y)
	if joy.length() < joystick_deadzone:
		joy = Vector2.ZERO
	else:
		joy = joy.normalized() * ((joy.length() - joystick_deadzone) / (1.0 - joystick_deadzone))
	if kb.length()  > 0: return kb.normalized()
	if joy.length() > 0: return joy
	return Vector2.ZERO

# =========================
# PICKUP
# =========================
func _check_nearby_drops() -> void:
	for drop in get_tree().get_nodes_in_group("drops"):
		if not is_instance_valid(drop):
			continue
		if global_position.distance_to(drop.global_position) <= pickup_radius:
			if drop.has_method("pickup"):
				drop.pickup(self)

# =========================
# XP / LEVEL
# =========================
func add_xp(amount: int) -> void:
	if player_level >= GlobalData.MAX_LEVEL:
		return
	xp += amount
	# Montée de niveau en cascade si besoin
	while player_level < GlobalData.MAX_LEVEL \
			and xp >= GlobalData.XP_TABLE[player_level]:
		player_level += 1
		emit_signal("level_up", player_level)
		emit_signal("weapons_changed")  # Refresh dégâts dans l'UI
	emit_signal("xp_changed", xp, _xp_for_next_level(), player_level)

func _xp_for_next_level() -> int:
	if player_level >= GlobalData.MAX_LEVEL:
		return GlobalData.XP_TABLE[GlobalData.MAX_LEVEL - 1]
	return GlobalData.XP_TABLE[player_level]

func get_xp_progress() -> float:
	# Retourne la progression [0.0 - 1.0] dans le niveau actuel
	if player_level >= GlobalData.MAX_LEVEL:
		return 1.0
	var xp_prev: int = GlobalData.XP_TABLE[player_level - 1]
	var xp_next: int = GlobalData.XP_TABLE[player_level]
	return float(xp - xp_prev) / float(xp_next - xp_prev)

# =========================
# MATERIAL USELESS CHECK
# Un matériau est inutile si aucune arme ne peut l'utiliser
# pour son prochain upgrade
# =========================
func is_material_useless(mat_type: String) -> bool:
	if mat_type == "apple":
		return false
	for weapon in equipped_weapons:
		if not is_instance_valid(weapon):
			continue
		var ct := weapon.get_tier()
		if ct >= Weapon.Tier.NETHERITE:
			continue
		var next_tier: String = Weapon.TIER_NAMES[ct + 1]
		if GlobalData.UPGRADE_RECIPES.has(next_tier):
			if GlobalData.UPGRADE_RECIPES[next_tier].has(mat_type):
				return false
	return true

# =========================
# WEAPONS
# =========================
func get_weapon_count() -> int:
	var n := 0
	for w in equipped_weapons:
		if is_instance_valid(w): n += 1
	return n

func _try_auto_upgrade() -> void:
	for weapon in equipped_weapons:
		if not is_instance_valid(weapon):
			continue
		var ct := weapon.get_tier()
		if ct >= Weapon.Tier.NETHERITE:
			continue
		var next: String = Weapon.TIER_NAMES[ct + 1]
		if not GlobalData.UPGRADE_RECIPES.has(next):
			continue
		var recipe: Dictionary = GlobalData.UPGRADE_RECIPES[next]
		var ok := true
		for mat in recipe.keys():
			if materials.get(mat, 0) < recipe[mat]:
				ok = false; break
		if ok:
			for mat in recipe.keys():
				spend_material(mat, recipe[mat])
			weapon.upgrade(player_level)
			emit_signal("weapons_changed")

# =========================
# COMBAT
# =========================
func take_damage(amount: int) -> void:
	if is_invincible:
		return
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
	if health <= 0:
		die()

func _on_invincibility_end() -> void:
	is_invincible = false
	modulate      = Color.WHITE

func _update_health_bar() -> void:
	if not health_bar_fill:
		return
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
		if is_instance_valid(weapon):
			weapon.degrade()
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
	if mat_type == "apple":
		pickup_apple(amount); return
	if not materials.has(mat_type):
		materials[mat_type] = 0
	materials[mat_type] += amount
	emit_signal("material_changed", mat_type, materials[mat_type])
	_try_auto_upgrade()

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

extends CharacterBody2D
class_name Player

# =========================
# CONFIG
# =========================
@export var move_speed: float = 128.0
@export var max_health: int = 20
@export var invincibility_time: float = 0.5
@export var pickup_radius: float = 16.0

# =========================
# LEVEL (bloqué à 1 en attendant feature leveling)
# =========================
var player_level: int = 1

# =========================
# JOYSTICK
# =========================
@export var joystick_deadzone: float = 0.2

# =========================
# WEAPONS (10 slots)
# =========================
const MAX_SLOTS: int = 10
const WEAPON_SCENE_PATH := "res://Scenes_Scripts/weapons/weapon.tscn"

var equipped_weapons: Array[Weapon] = []
var weapon_scene: PackedScene = null

# =========================
# INVENTORY
# =========================
var materials: Dictionary = {
	"stick":     0,
	"wooden":    0,
	"stone":     0,
	"gold":      0,
	"iron":      0,
	"diamond":   0,
	"netherite": 0
}

# =========================
# APPLE STOCK
# =========================
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
		push_error("[Player] Weapon scene NOT found: " + WEAPON_SCENE_PATH)
	
	_update_health_bar()
	
	await get_tree().create_timer(0.1).timeout
	_give_starting_sticks()
	
	_print_inventory()

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
	print("[Player] 10 sticks équipés!")

# =========================
# MOVEMENT
# =========================
func _physics_process(_delta: float) -> void:
	var input_vector := _get_movement_input()
	velocity = input_vector * move_speed
	move_and_slide()
	_check_nearby_drops()

func _get_movement_input() -> Vector2:
	var keyboard_input := Input.get_vector(
		"move_left", "move_right", "move_up", "move_down"
	)
	
	var joy_x := Input.get_joy_axis(0, JOY_AXIS_LEFT_X)
	var joy_y := Input.get_joy_axis(0, JOY_AXIS_LEFT_Y)
	var joystick_input := Vector2(joy_x, joy_y)
	
	if joystick_input.length() < joystick_deadzone:
		joystick_input = Vector2.ZERO
	else:
		var input_length := (joystick_input.length() - joystick_deadzone) / (1.0 - joystick_deadzone)
		joystick_input = joystick_input.normalized() * input_length
	
	if keyboard_input.length() > 0:
		return keyboard_input.normalized()
	elif joystick_input.length() > 0:
		return joystick_input
	return Vector2.ZERO

# =========================
# PICKUP DROPS
# =========================
func _check_nearby_drops() -> void:
	var drops := get_tree().get_nodes_in_group("drops")
	for drop in drops:
		if not is_instance_valid(drop):
			continue
		var distance: float = global_position.distance_to(drop.global_position)
		if distance <= pickup_radius:
			if drop.has_method("pickup"):
				drop.pickup(self)

# =========================
# WEAPON MANAGEMENT
# =========================
func get_weapon_count() -> int:
	var count: int = 0
	for w in equipped_weapons:
		if is_instance_valid(w):
			count += 1
	return count

# Auto-upgrade : déclenché après chaque pickup de matériau
# Parcourt les slots dans l'ordre de priorité (slot 0 en premier)
# Chaque slot est indépendant
# Mode test : les matériaux ne sont PAS consommés
func _try_auto_upgrade() -> void:
	for weapon in equipped_weapons:
		if not is_instance_valid(weapon):
			continue
		
		var current_tier := weapon.get_tier()
		
		# Déjà au max
		if current_tier >= Weapon.Tier.NETHERITE:
			continue
		
		var next_tier_name: String = Weapon.TIER_NAMES[current_tier + 1]
		
		# Vérifier que la recette existe
		if not GlobalData.UPGRADE_RECIPES.has(next_tier_name):
			continue
		
		var recipe: Dictionary = GlobalData.UPGRADE_RECIPES[next_tier_name]
		
		# Vérifier que les matériaux sont disponibles
		var can_upgrade := true
		for mat_type in recipe.keys():
			var needed: int = recipe[mat_type]
			if materials.get(mat_type, 0) < needed:
				can_upgrade = false
				break
		
		if can_upgrade:
			# Consommer les matériaux
			for mat_type in recipe.keys():
				spend_material(mat_type, recipe[mat_type])
			weapon.upgrade(player_level)
			emit_signal("weapons_changed")

# =========================
# COMBAT
# =========================
func take_damage(amount: int) -> void:
	if is_invincible:
		return
	
	health -= amount
	health = maxi(0, health)
	
	# Auto-consume autant de pommes que nécessaire
	if apple_stock > 0 and health < max_health:
		var apples_used := 0
		while apple_stock > 0 and health < max_health:
			apple_stock -= 1
			health += 1
			apples_used += 1
		emit_signal("apple_changed", apple_stock)
		print("[Player] ", apples_used, " apple(s) consommée(s) | Stock: ",
			apple_stock, " | HP: ", health, "/", max_health)
	
	_update_health_bar()
	emit_signal("health_changed", health, max_health)
	
	modulate = Color.RED
	is_invincible = true
	invincibility_timer.start(invincibility_time)
	
	if health <= 0:
		die()

func _on_invincibility_end() -> void:
	is_invincible = false
	modulate = Color.WHITE

func _update_health_bar() -> void:
	if not health_bar_fill:
		return
	var percent: float = float(health) / float(max_health)
	health_bar_fill.size.x = 16.0 * percent
	if percent > 0.1:
		health_bar_fill.color = Color(0, 0.9, 0, 1)
	else:
		health_bar_fill.color = Color(0.9, 0, 0, 1)

# =========================
# DEATH / RESPAWN
# =========================
var spawn_points: Array[Vector2] = [
	Vector2(0, 0),
	#Vector2(500, 100),
	#Vector2(-300, 400),
	#Vector2(1200, -200)
]

func die() -> void:
	emit_signal("player_died")
	
	# Dégrade toutes les armes non-stick de 1 durabilité
	print("[Player] Mort ! Dégradation des armes...")
	for weapon in equipped_weapons:
		if is_instance_valid(weapon):
			weapon.degrade()
	
	global_position = spawn_points.pick_random()
	health = max_health
	velocity = Vector2.ZERO
	is_invincible = false
	modulate = Color.WHITE
	
	_update_health_bar()
	emit_signal("health_changed", health, max_health)
	emit_signal("weapons_changed")
	
	print("[Player] Respawn → ", global_position)
	_print_weapons_status()

func _print_weapons_status() -> void:
	print("======== WEAPONS STATUS ========")
	for weapon in equipped_weapons:
		if is_instance_valid(weapon):
			var dur_str: String
			if weapon.durability == Weapon.INFINITE_DURABILITY:
				dur_str = "∞"
			else:
				dur_str = str(weapon.durability) + "/" + str(weapon.max_durability)
			print("  Slot ", weapon.slot_index, " | ",
				weapon.get_tier_name().to_upper().rpad(10), " | DUR: ", dur_str)
	print("================================")

# =========================
# APPLE
# =========================
func pickup_apple(amount: int = 1) -> void:
	if health < max_health:
		health = mini(health + amount, max_health)
		_update_health_bar()
		emit_signal("health_changed", health, max_health)
		print("[Player] Apple consommée! HP: ", health, "/", max_health)
	else:
		apple_stock += amount
		emit_signal("apple_changed", apple_stock)
		print("[Player] Apple stockée! Stock: ", apple_stock)

# =========================
# MATERIALS
# =========================
func add_material(mat_type: String, amount: int = 1) -> void:
	if mat_type == "apple":
		pickup_apple(amount)
		return
	
	if not materials.has(mat_type):
		materials[mat_type] = 0
	
	materials[mat_type] += amount
	emit_signal("material_changed", mat_type, materials[mat_type])
	
	print(">>> +", amount, " ", mat_type.to_upper())
	
	# Vérifier si un upgrade est possible après chaque pickup
	_try_auto_upgrade()

func _print_inventory() -> void:
	print("========================================")
	print("              INVENTORY                ")
	print("========================================")
	for mat_type in GlobalData.MATERIAL_ORDER:
		var count: int = materials.get(mat_type, 0)
		print("  ", mat_type.to_upper().rpad(10), ": ", count)
	print("  APPLE     : ", apple_stock, " (stock)")
	print("========================================")

func get_material_count(mat_type: String) -> int:
	return materials.get(mat_type, 0)

func get_all_materials() -> Dictionary:
	return materials.duplicate()

func spend_material(mat_type: String, amount: int) -> bool:
	if materials.get(mat_type, 0) >= amount:
		materials[mat_type] -= amount
		emit_signal("material_changed", mat_type, materials[mat_type])
		print(">>> -", amount, " ", mat_type.to_upper())
		return true
	return false

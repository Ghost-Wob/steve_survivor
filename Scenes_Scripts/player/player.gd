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
# INVENTORY (All resources)
# =========================
var materials: Dictionary = {
	"stick": 0,
	"wooden": 0,
	"stone": 0,
	"gold": 0,
	"iron": 0,
	"diamond": 0,
	"netherite": 0
}

# Order for display
const MATERIAL_ORDER: Array[String] = ["stick", "wooden", "stone", "gold", "iron", "diamond", "netherite"]

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
	print("[Player] 10 sticks equipped!")

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

# =========================
# COMBAT
# =========================
func take_damage(amount: int) -> void:
	if is_invincible:
		return
	
	health -= amount
	health = maxi(0, health)
	
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

func die() -> void:
	emit_signal("player_died")
	queue_free()

# =========================
# MATERIALS (PRINT CONSOLE)
# =========================
func add_material(mat_type: String, amount: int = 1) -> void:
	if not materials.has(mat_type):
		materials[mat_type] = 0
	
	materials[mat_type] += amount
	emit_signal("material_changed", mat_type, materials[mat_type])
	
	print("")
	print(">>> +", amount, " ", mat_type.to_upper(), " <<<")
	_print_inventory()

func _print_inventory() -> void:
	print("========================================")
	print("              INVENTORY                ")
	print("========================================")
	for mat_type in MATERIAL_ORDER:
		var count: int = materials.get(mat_type, 0)
		var display_name: String = mat_type.to_upper()
		# Padding for alignment
		while display_name.length() < 10:
			display_name += " "
		print("  ", display_name, ": ", count)
	print("========================================")

func get_material_count(mat_type: String) -> int:
	return materials.get(mat_type, 0)

func get_all_materials() -> Dictionary:
	return materials.duplicate()

func spend_material(mat_type: String, amount: int) -> bool:
	if materials.get(mat_type, 0) >= amount:
		materials[mat_type] -= amount
		emit_signal("material_changed", mat_type, materials[mat_type])
		print(">>> -", amount, " ", mat_type.to_upper(), " <<<")
		_print_inventory()
		return true
	return false

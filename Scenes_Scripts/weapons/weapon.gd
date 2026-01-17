extends Node2D
class_name Weapon

# =========================
# NODES
# =========================
@onready var sprite: Sprite2D = $Sprite2D
@onready var hitbox: Area2D = $Area2D
@onready var pickup_area: Area2D = $PickupArea

# =========================
# TEXTURE PATHS
# =========================
const STICK_TEXTURE := "res://Asset/pixel_art/items/stick.png"
const SWORD_BASE_PATH := "res://Asset/pixel_art/weapons/swords/"

# =========================
# TIERS (stick evolves into swords)
# =========================
enum Tier { STICK, WOODEN, STONE, GOLD, IRON, DIAMOND, NETHERITE }

const TIER_NAMES: Array[String] = ["stick", "wooden", "stone", "gold", "iron", "diamond", "netherite"]

const TIER_DAMAGE: Dictionary = {
	"stick": 2,
	"wooden": 3,
	"stone": 5,
	"gold": 4,
	"iron": 7,
	"diamond": 10,
	"netherite": 15
}

# =========================
# ORBIT CONFIG (10 slots, equidistant)
# =========================
const MAX_SLOTS: int = 10
const SLOT_ANGLE: float = TAU / 10.0  # 2π/10 = 36 degrees

@export var orbit_radius: float = 32.0
@export var orbit_speed: float = 2.0

# Texture rotation offset (diagonal texture)
const TEXTURE_ANGLE_OFFSET := PI / 4.0

# =========================
# STATE
# =========================
var current_tier: int = Tier.STICK
var tier_name: String = "stick"
var base_damage: int = 2

var carrier: Player = null
var slot_index: int = -1
var is_picked_up: bool = false
var orbit_angle: float = 0.0

# Damage cooldown
var damage_cooldowns: Dictionary = {}
const DAMAGE_COOLDOWN: float = 0.3

# =========================
# INIT
# =========================
func _ready() -> void:
	add_to_group("weapons")
	_apply_texture()
	_setup_hitbox()
	_setup_pickup()

func _setup_hitbox() -> void:
	if hitbox:
		hitbox.collision_layer = 0
		hitbox.collision_mask = 4  # Monsters
		hitbox.monitoring = false
		
		if not hitbox.body_entered.is_connected(_on_hitbox_body_entered):
			hitbox.body_entered.connect(_on_hitbox_body_entered)

func _setup_pickup() -> void:
	if pickup_area:
		pickup_area.collision_layer = 0
		pickup_area.collision_mask = 1  # Player
		
		if not pickup_area.body_entered.is_connected(_on_pickup_area_body_entered):
			pickup_area.body_entered.connect(_on_pickup_area_body_entered)

# =========================
# ORBIT (10 equidistant slots)
# =========================
func _physics_process(delta: float) -> void:
	if not is_picked_up:
		return
	
	if not is_instance_valid(carrier):
		return
	
	# Update cooldowns
	_update_cooldowns(delta)
	
	# Orbit rotation
	orbit_angle += orbit_speed * delta
	if orbit_angle > TAU:
		orbit_angle -= TAU
	
	# Fixed slot position: slot_index * (2π/10)
	var slot_base_angle: float = float(slot_index) * SLOT_ANGLE
	var final_angle: float = slot_base_angle + orbit_angle
	
	# Position around player
	var offset := Vector2(cos(final_angle), sin(final_angle)) * orbit_radius
	global_position = carrier.global_position + offset
	
	# Rotate to point outward + texture offset
	rotation = final_angle + TEXTURE_ANGLE_OFFSET

func _update_cooldowns(delta: float) -> void:
	var to_remove: Array = []
	for monster_id in damage_cooldowns.keys():
		damage_cooldowns[monster_id] -= delta
		if damage_cooldowns[monster_id] <= 0:
			to_remove.append(monster_id)
	for monster_id in to_remove:
		damage_cooldowns.erase(monster_id)

# =========================
# ATTACH TO PLAYER
# =========================
func attach_to_player(player: Player, slot: int) -> void:
	carrier = player
	slot_index = slot
	is_picked_up = true
	orbit_angle = 0.0
	
	if hitbox:
		hitbox.monitoring = true
	
	if pickup_area:
		pickup_area.set_deferred("monitoring", false)
	
	print("[Weapon] Attached to slot ", slot, " (", tier_name, ")")

# =========================
# PICKUP (for dropped weapons)
# =========================
func _on_pickup_area_body_entered(body: Node2D) -> void:
	if is_picked_up:
		return
	
	if body is Player:
		# This is for picking up dropped weapons, not starting sticks
		pass

# =========================
# TEXTURE
# =========================
func _apply_texture() -> void:
	if not sprite:
		return
	
	var path: String
	
	if current_tier == Tier.STICK:
		path = STICK_TEXTURE
	else:
		path = SWORD_BASE_PATH + tier_name + "_sword.png"
	
	if ResourceLoader.exists(path):
		sprite.texture = load(path)
	else:
		push_warning("[Weapon] Texture not found: " + path)

# =========================
# UPGRADE (stick -> sword)
# =========================
func upgrade() -> bool:
	if current_tier >= Tier.NETHERITE:
		return false
	
	current_tier += 1
	tier_name = TIER_NAMES[current_tier]
	base_damage = TIER_DAMAGE[tier_name]
	
	_apply_texture()
	_show_upgrade_effect()
	
	print("[Weapon] Upgraded to ", tier_name, " (Damage: ", base_damage, ")")
	return true

func _show_upgrade_effect() -> void:
	if not sprite:
		return
	
	sprite.modulate = Color(3, 3, 3, 1)
	var tween := create_tween()
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.3)
	
	# Scale pop
	var original_scale := scale
	scale = original_scale * 1.3
	var tween2 := create_tween()
	tween2.set_ease(Tween.EASE_OUT)
	tween2.set_trans(Tween.TRANS_ELASTIC)
	tween2.tween_property(self, "scale", original_scale, 0.4)

func get_tier() -> int:
	return current_tier

func get_tier_name() -> String:
	return tier_name

# =========================
# COMBAT
# =========================
func _on_hitbox_body_entered(body: Node2D) -> void:
	if not is_picked_up:
		return
	
	if not (body is OverworldMonster):
		return
	
	var monster: OverworldMonster = body as OverworldMonster
	var monster_id: int = monster.get_instance_id()
	
	# Check cooldown for this monster
	if damage_cooldowns.has(monster_id):
		return
	
	# Deal damage
	monster.take_damage(base_damage)
	damage_cooldowns[monster_id] = DAMAGE_COOLDOWN
	
	# Visual feedback
	if sprite:
		sprite.modulate = Color(2, 2, 2, 1)
		var tween := create_tween()
		tween.tween_property(sprite, "modulate", Color.WHITE, 0.1)

#pas au meme endroit... je veux une position random dans un carre 16x16 BASE SUR LA POSITION DE MORT DU MONSTRE EN QUESTION

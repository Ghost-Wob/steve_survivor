extends Node2D
class_name Weapon

# =========================
# NODES
# =========================
@onready var sprite: Sprite2D = $Sprite2D
@onready var hitbox: Area2D = $Area2D
@onready var pickup_area: Area2D = $PickupArea

# =========================
# TIERS
# =========================
enum Tier { STICK, WOODEN, STONE, GOLD, IRON, DIAMOND, NETHERITE }

const TIER_NAMES: Array[String] = ["stick", "wooden", "stone", "gold", "iron", "diamond", "netherite"]

const TIER_DAMAGE: Dictionary = {
	"stick":     2,
	"wooden":    3,
	"stone":     5,
	"gold":      4,
	"iron":      7,
	"diamond":   10,
	"netherite": 15
}

# =========================
# ORBIT CONFIG
# =========================
const MAX_SLOTS: int = 10
const SLOT_ANGLE: float = TAU / 10.0

@export var orbit_radius: float = 32.0
@export var orbit_speed: float = 2.0

const TEXTURE_ANGLE_OFFSET := PI / 4.0

# =========================
# STATE
# =========================
var current_tier: int = Tier.STICK
var tier_name: String = "stick"
var base_damage: int = 2

const INFINITE_DURABILITY: int = -1
var durability: int = INFINITE_DURABILITY
var max_durability: int = INFINITE_DURABILITY

var carrier: Player = null
var slot_index: int = -1
var is_picked_up: bool = false
var orbit_angle: float = 0.0

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
		hitbox.collision_mask = 4
		hitbox.monitoring = false
		if not hitbox.body_entered.is_connected(_on_hitbox_body_entered):
			hitbox.body_entered.connect(_on_hitbox_body_entered)

func _setup_pickup() -> void:
	if pickup_area:
		pickup_area.collision_layer = 0
		pickup_area.collision_mask = 1
		if not pickup_area.body_entered.is_connected(_on_pickup_area_body_entered):
			pickup_area.body_entered.connect(_on_pickup_area_body_entered)

# =========================
# ORBIT
# =========================
func _physics_process(delta: float) -> void:
	if not is_picked_up or not is_instance_valid(carrier):
		return
	
	_update_cooldowns(delta)
	
	orbit_angle += orbit_speed * delta
	if orbit_angle > TAU:
		orbit_angle -= TAU
	
	var final_angle: float = float(slot_index) * SLOT_ANGLE + orbit_angle
	global_position = carrier.global_position + Vector2(cos(final_angle), sin(final_angle)) * orbit_radius
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
	scale = Vector2.ONE  # Garantit une taille propre à l'attachement
	
	if hitbox:
		hitbox.monitoring = true
	if pickup_area:
		pickup_area.set_deferred("monitoring", false)
	
	print("[Weapon] Slot ", slot, " | ", tier_name.to_upper(),
		" | DMG: ", base_damage, " | DUR: ", _durability_display())

func _on_pickup_area_body_entered(body: Node2D) -> void:
	if is_picked_up:
		return
	if body is Player:
		pass

# =========================
# DURABILITÉ
# =========================
func _calc_max_durability(tier: int, player_level: int) -> int:
	if tier == Tier.STICK:
		return INFINITE_DURABILITY
	return tier * player_level

func _durability_display() -> String:
	if durability == INFINITE_DURABILITY:
		return "∞"
	return str(durability) + "/" + str(max_durability)

func degrade() -> void:
	if current_tier == Tier.STICK or durability == INFINITE_DURABILITY:
		return
	
	durability -= 1
	print("[Weapon] Slot ", slot_index, " | ", tier_name.to_upper(),
		" dégradée → DUR: ", _durability_display())
	
	if durability <= 0:
		_tier_down()

func _tier_down() -> void:
	if current_tier <= Tier.STICK:
		current_tier = Tier.STICK
		tier_name = "stick"
		base_damage = TIER_DAMAGE["stick"]
		durability = INFINITE_DURABILITY
		max_durability = INFINITE_DURABILITY
	else:
		current_tier -= 1
		tier_name = TIER_NAMES[current_tier]
		base_damage = TIER_DAMAGE[tier_name]
		var player_level: int = carrier.player_level if is_instance_valid(carrier) else 1
		max_durability = _calc_max_durability(current_tier, player_level)
		durability = max_durability if max_durability != INFINITE_DURABILITY else INFINITE_DURABILITY
	
	_apply_texture()
	_show_degrade_effect()
	print("[Weapon] Slot ", slot_index, " | Cassée → ",
		tier_name.to_upper(), " | DUR: ", _durability_display())

# =========================
# TEXTURE (centralisé dans GlobalData)
# =========================
func _apply_texture() -> void:
	if not sprite:
		return
	var path: String = GlobalData.get_weapon_texture_path(tier_name)
	if path != "" and ResourceLoader.exists(path):
		sprite.texture = load(path)
	else:
		push_warning("[Weapon] Texture not found for tier: " + tier_name + " → " + path)

# =========================
# UPGRADE
# =========================
func upgrade(player_level: int) -> bool:
	if current_tier >= Tier.NETHERITE:
		return false
	
	current_tier += 1
	tier_name = TIER_NAMES[current_tier]
	base_damage = TIER_DAMAGE[tier_name]
	max_durability = _calc_max_durability(current_tier, player_level)
	durability = max_durability
	
	_apply_texture()
	_show_upgrade_effect()
	
	print("[Weapon] Slot ", slot_index, " | → ", tier_name.to_upper(),
		" | DMG: ", base_damage, " | DUR: ", _durability_display())
	return true

# Les effets visuels ne touchent JAMAIS scale directement pour éviter
# l'accumulation. On tweene depuis et vers Vector2.ONE uniquement.
func _show_upgrade_effect() -> void:
	if not sprite:
		return
	sprite.modulate = Color(3, 3, 3, 1)
	create_tween().tween_property(sprite, "modulate", Color.WHITE, 0.3)
	
	scale = Vector2(1.3, 1.3)
	var t := create_tween()
	t.set_ease(Tween.EASE_OUT)
	t.set_trans(Tween.TRANS_ELASTIC)
	t.tween_property(self, "scale", Vector2.ONE, 0.4)

func _show_degrade_effect() -> void:
	if not sprite:
		return
	sprite.modulate = Color(2, 0.3, 0.3, 1)
	create_tween().tween_property(sprite, "modulate", Color.WHITE, 0.5)
	
	scale = Vector2(0.7, 0.7)
	var t := create_tween()
	t.set_ease(Tween.EASE_OUT)
	t.set_trans(Tween.TRANS_BOUNCE)
	t.tween_property(self, "scale", Vector2.ONE, 0.4)

func get_tier() -> int:
	return current_tier

func get_tier_name() -> String:
	return tier_name

# =========================
# COMBAT
# =========================
func _on_hitbox_body_entered(body: Node2D) -> void:
	if not is_picked_up or not (body is OverworldMonster):
		return
	
	var monster: OverworldMonster = body as OverworldMonster
	var monster_id: int = monster.get_instance_id()
	
	if damage_cooldowns.has(monster_id):
		return
	
	monster.take_damage(base_damage)
	damage_cooldowns[monster_id] = DAMAGE_COOLDOWN
	
	if sprite:
		sprite.modulate = Color(2, 2, 2, 1)
		create_tween().tween_property(sprite, "modulate", Color.WHITE, 0.1)

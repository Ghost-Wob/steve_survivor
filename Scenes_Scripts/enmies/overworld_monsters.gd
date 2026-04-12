extends CharacterBody2D
class_name OverworldMonster

# =========================
# CONFIG
# =========================
@export var max_health: int        = 100
@export var move_speed: float      = 64.0
@export var damage: int            = 4
@export var attack_interval: float = 1.0

# =========================
# DROP
# =========================
const DROP_SCENE_PATH := "res://Scenes_Scripts/management/drop.tscn"
var drop_scene: PackedScene = null

# =========================
# STATE
# =========================
var health: int
var player: Player
var can_attack: bool    = true
var attack_timer: Timer
var attack_range: float = 20.0

# =========================
# NODES
# =========================
@onready var health_bar_bg: ColorRect   = $HealthBarBG
@onready var health_bar_fill: ColorRect = $HealthBarBG/HealthBarFill
@onready var sprite: Sprite2D           = $Sprite2D

# =========================
# INIT
# =========================
func _ready() -> void:
	add_to_group("monsters")
	health = max_health
	if ResourceLoader.exists(DROP_SCENE_PATH):
		drop_scene = load(DROP_SCENE_PATH)
	else:
		push_error("[Monster] Drop scene introuvable : " + DROP_SCENE_PATH)
	attack_timer = Timer.new()
	attack_timer.one_shot  = true
	attack_timer.wait_time = attack_interval
	add_child(attack_timer)
	attack_timer.timeout.connect(_on_attack_cooldown_end)
	_update_health_bar()

func setup(data: Dictionary, target_player: Player) -> void:
	player          = target_player
	move_speed      = data.get("move_speed",      move_speed)
	damage          = data.get("damage",          damage)
	attack_interval = data.get("attack_interval", attack_interval)
	attack_timer.wait_time = attack_interval
	if data.has("texture"): sprite.texture = data["texture"]

# =========================
# MOVEMENT
# =========================
func _physics_process(_delta: float) -> void:
	if not is_instance_valid(player): return
	velocity = (player.global_position - global_position).normalized() * move_speed
	move_and_slide()
	_try_attack_player()

func _try_attack_player() -> void:
	if not can_attack or not is_instance_valid(player): return
	if global_position.distance_to(player.global_position) <= attack_range:
		player.take_damage(damage)
		can_attack = false
		attack_timer.start()

func _on_attack_cooldown_end() -> void:
	can_attack = true

# =========================
# DAMAGE
# =========================
func take_damage(amount: int) -> void:
	health -= amount
	health  = maxi(0, health)
	_update_health_bar()
	modulate = Color.RED
	create_tween().tween_property(self, "modulate", Color.WHITE, 0.1)
	if health <= 0: die()

# =========================
# HEALTH BAR
# =========================
func _update_health_bar() -> void:
	if not health_bar_fill: return
	var pct := float(health) / float(max_health)
	health_bar_fill.size.x = 16.0 * pct
	health_bar_fill.color  = Color(0, 0.9, 0, 1) if pct > 0.1 else Color(0.9, 0, 0, 1)

# =========================
# DEATH + DROPS + XP
# =========================
func die() -> void:
	if is_instance_valid(player):
		player.add_xp(GlobalData.XP_PER_KILL)
	_spawn_drops()
	queue_free()

func _spawn_drops() -> void:
	if not drop_scene:
		push_error("[Monster] Cannot drop — scene non chargée")
		return

	# Drops de matériaux (skip si inutile pour le joueur)
	for mat_type in GlobalData.ZOMBIE_DROPS.keys():
		var chance: float = GlobalData.ZOMBIE_DROPS[mat_type]
		if is_instance_valid(player) and player.is_material_useless(mat_type):
			continue
		if randf() <= chance:
			_spawn_single_drop(mat_type, 1)

	# Drop de la craft table — taux = même que la ressource la plus basse utile
	if is_instance_valid(player):
		var lowest_mat: String = player.get_lowest_useful_material()
		var table_chance: float = GlobalData.ZOMBIE_DROPS.get(lowest_mat, 0.001)
		if randf() <= table_chance:
			_spawn_single_drop("craft_table", 1)

func _spawn_single_drop(mat_type: String, amount: int) -> void:
	var drop: Node = drop_scene.instantiate()
	if not drop: return
	get_parent().add_child(drop)
	drop.global_position = global_position
	if drop.has_method("setup"):
		drop.setup(mat_type, amount)

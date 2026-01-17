extends Node2D
class_name MonsterSpawner

# =========================
# CONFIG
# =========================
@export var monster_scene: PackedScene
@export var spawn_radius_min: float = 200.0
@export var spawn_radius_max: float = 400.0
@export var spawn_on_start: bool = true
@export var spawn_delay: float = 0.1
@export var spawn_interval: float = 2.0
@export var max_monsters: int = 30
@export var monsters_per_wave: int = 1

# =========================
# DIFFICULTY SCALING
# =========================
@export var difficulty_increase_time: float = 30.0
var current_difficulty: float = 1.0
var time_elapsed: float = 0.0

# =========================
# INTERNAL
# =========================
var player: Player = null
var spawn_timer: Timer

func _ready() -> void:
	print("[Spawner] _ready() called")
	
	player = _find_player()
	
	if not is_instance_valid(player):
		push_error("[Spawner] ERROR: Player not found!")
		return
	
	# Setup continuous spawn timer
	spawn_timer = Timer.new()
	spawn_timer.wait_time = spawn_interval
	spawn_timer.one_shot = false
	add_child(spawn_timer)
	spawn_timer.timeout.connect(_on_spawn_timer)
	
	if spawn_on_start:
		await get_tree().create_timer(spawn_delay).timeout
		spawn_wave()
		spawn_timer.start()

func _process(delta: float) -> void:
	# Increase difficulty over time
	time_elapsed += delta
	current_difficulty = 1.0 + (time_elapsed / difficulty_increase_time) * 0.5

func _find_player() -> Player:
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0 and players[0] is Player:
		return players[0] as Player
	return null

func _on_spawn_timer() -> void:
	var current_monsters := get_tree().get_nodes_in_group("monsters").size()
	if current_monsters < max_monsters:
		spawn_wave()

func spawn_wave() -> void:
	var to_spawn := mini(monsters_per_wave, max_monsters - get_tree().get_nodes_in_group("monsters").size())
	
	for i in range(to_spawn):
		spawn_zombie()

func spawn_zombie() -> void:
	if not monster_scene:
		push_error("[Spawner] ERROR: monster_scene not assigned!")
		return
	
	if not is_instance_valid(player):
		return
	
	var monster := monster_scene.instantiate()
	
	if not (monster is OverworldMonster):
		push_error("[Spawner] ERROR: Scene is not OverworldMonster!")
		monster.queue_free()
		return
	
	add_child(monster)
	monster.global_position = _get_spawn_position()
	monster.setup(_get_zombie_data(), player)

func _get_zombie_data() -> Dictionary:
	var texture := preload("res://Asset/pixel_art/monsters/overworld/zombie.png")
	
	return {
		"texture": texture,
		"move_speed": 60.0 + (current_difficulty * 10.0),
		"damage": int(5 * current_difficulty),
		"attack_interval": max(0.5, 1.0 - (current_difficulty * 0.1))
	}

func _get_spawn_position() -> Vector2:
	if not is_instance_valid(player):
		return Vector2.ZERO
	
	var angle := randf() * TAU
	var distance := randf_range(spawn_radius_min, spawn_radius_max)
	return player.global_position + Vector2(cos(angle), sin(angle)) * distance

extends Node2D
class_name MonsterSpawner

# =========================
# CONFIG
# =========================
@export var monster_scene: PackedScene
@export var spawn_radius_min: float     = 200.0
@export var spawn_radius_max: float     = 400.0
@export var spawn_on_start: bool        = true
@export var spawn_delay: float          = 0.1
@export var spawn_interval: float       = 2.0
@export var base_max_monsters: int      = 30    # × player_level, hard cap 300
@export var base_monsters_per_wave: int = 1     # × player_level

const HARD_CAP: int = 300

var player: Player = null
var spawn_timer: Timer

func _ready() -> void:
	player = _find_player()
	if not is_instance_valid(player):
		push_error("[Spawner] Player introuvable !")
		return

	spawn_timer = Timer.new()
	spawn_timer.wait_time = spawn_interval
	spawn_timer.one_shot  = false
	add_child(spawn_timer)
	spawn_timer.timeout.connect(_on_spawn_timer)

	if spawn_on_start:
		await get_tree().create_timer(spawn_delay).timeout
		spawn_wave()
		spawn_timer.start()

func _find_player() -> Player:
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0 and players[0] is Player:
		return players[0] as Player
	return null

func _get_current_max() -> int:
	var lvl := player.player_level if is_instance_valid(player) else 1
	return mini(base_max_monsters * lvl, HARD_CAP)

func _get_wave_size() -> int:
	var lvl := player.player_level if is_instance_valid(player) else 1
	return base_monsters_per_wave * lvl

func _on_spawn_timer() -> void:
	var current := get_tree().get_nodes_in_group("monsters").size()
	if current < _get_current_max():
		spawn_wave()

func spawn_wave() -> void:
	var current  := get_tree().get_nodes_in_group("monsters").size()
	var to_spawn := mini(_get_wave_size(), _get_current_max() - current)
	for i in range(to_spawn):
		spawn_zombie()

func spawn_zombie() -> void:
	if not monster_scene:
		push_error("[Spawner] monster_scene non assignée !"); return
	if not is_instance_valid(player): return

	var monster := monster_scene.instantiate()
	if not monster is OverworldMonster:
		push_error("[Spawner] Scène invalide !")
		monster.queue_free(); return

	add_child(monster)
	monster.global_position = _get_spawn_position()
	monster.setup(_get_zombie_data(), player)

func _get_zombie_data() -> Dictionary:
	return {
		"texture":         preload("res://Asset/pixel_art/monsters/overworld/zombie.png"),
		"move_speed":      60.0,
		"attack_interval": 1.0
	}

func _get_spawn_position() -> Vector2:
	if not is_instance_valid(player): return Vector2.ZERO
	var angle    := randf() * TAU
	var distance := randf_range(spawn_radius_min, spawn_radius_max)
	return player.global_position + Vector2(cos(angle), sin(angle)) * distance

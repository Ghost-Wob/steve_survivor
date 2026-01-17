extends Node

# =========================
# SCENES PATHS
# =========================
const OVERWORLD_SCENE := "res://Scenes_Scripts/world/overworld_map.tscn"
const HOUSE_SCENE := "res://Scenes_Scripts/world/house_map.tscn"

# =========================
# STATE
# =========================
enum Zone { OVERWORLD, HOUSE }
var current_zone: Zone = Zone.OVERWORLD

# Player data to persist between scenes
var player_data: Dictionary = {
	"health": 20,
	"materials": {},
	"weapons": []
}

# =========================
# SIGNALS
# =========================
signal zone_changed(new_zone: Zone)
signal scene_loaded()

# =========================
# SCENE TRANSITIONS
# =========================
func go_to_overworld() -> void:
	if current_zone == Zone.OVERWORLD:
		return
	
	_save_player_data()
	current_zone = Zone.OVERWORLD
	_change_scene(OVERWORLD_SCENE)
	print("[GameManager] Teleported to OVERWORLD")

func go_to_house() -> void:
	if current_zone == Zone.HOUSE:
		return
	
	_save_player_data()
	current_zone = Zone.HOUSE
	_change_scene(HOUSE_SCENE)
	print("[GameManager] Teleported to HOUSE")

func _change_scene(scene_path: String) -> void:
	# Fade out effect
	var tree := get_tree()
	
	# Change scene
	var error := tree.change_scene_to_file(scene_path)
	if error != OK:
		push_error("[GameManager] Failed to load scene: " + scene_path)
		return
	
	# Wait for scene to load
	await tree.tree_changed
	await tree.process_frame
	
	# Restore player data
	_restore_player_data()
	
	emit_signal("zone_changed", current_zone)
	emit_signal("scene_loaded")

# =========================
# PLAYER DATA PERSISTENCE
# =========================
func _save_player_data() -> void:
	var player := _find_player()
	if not player:
		return
	
	player_data.health = player.health
	player_data.materials = player.get_all_materials()
	
	print("[GameManager] Player data saved")

func _restore_player_data() -> void:
	await get_tree().process_frame
	
	var player := _find_player()
	if not player:
		return
	
	player.health = player_data.health
	
	for mat_type in player_data.materials.keys():
		player.materials[mat_type] = player_data.materials[mat_type]
	
	print("[GameManager] Player data restored")

func _find_player() -> Player:
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0 and players[0] is Player:
		return players[0] as Player
	return null

# =========================
# GETTERS
# =========================
func is_in_overworld() -> bool:
	return current_zone == Zone.OVERWORLD

func is_in_house() -> bool:
	return current_zone == Zone.HOUSE

func get_current_zone() -> Zone:
	return current_zone

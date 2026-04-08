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
	"apple_stock": 0,
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
	await _change_scene(OVERWORLD_SCENE)
	print("[GameManager] Teleported to OVERWORLD")

func go_to_house() -> void:
	if current_zone == Zone.HOUSE:
		return

	_save_player_data()
	current_zone = Zone.HOUSE
	await _change_scene(HOUSE_SCENE)
	print("[GameManager] Teleported to HOUSE")

func _change_scene(scene_path: String) -> void:
	var tree := get_tree()

	var error := tree.change_scene_to_file(scene_path)
	if error != OK:
		push_error("[GameManager] Failed to load scene: " + scene_path)
		return

	await tree.tree_changed
	await tree.process_frame

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
	player_data.apple_stock = player.apple_stock
	player_data.weapons = player.get_weapon_states()

	print("[GameManager] Player data saved")

func _restore_player_data() -> void:
	await get_tree().process_frame

	var player := _find_player()
	if not player:
		return

	player.health = player_data.health
	player.apple_stock = int(player_data.get("apple_stock", 0))
	player.emit_signal("apple_changed", player.apple_stock)

	player.materials = {}
	for mat_type in player_data.materials.keys():
		player.materials[mat_type] = player_data.materials[mat_type]
		player.emit_signal("material_changed", mat_type, player.materials[mat_type])

	player.restore_weapon_states(player_data.get("weapons", []))
	player.emit_signal("health_changed", player.health, player.max_health)
	player.emit_signal("weapons_changed")

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

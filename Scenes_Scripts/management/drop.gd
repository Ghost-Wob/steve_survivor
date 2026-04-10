extends Node2D
class_name Drop

# =========================
# STATE
# =========================
var material_type: String = "gold"
var amount: int           = 1
var is_picked_up: bool    = false

# =========================
# AIMANT
# Attend ATTRACT_DELAY secondes puis glisse vers le joueur
# =========================
const ATTRACT_DELAY: float = 1.5
const ATTRACT_SPEED: float = 120.0

var attract_target: Node2D = null
var is_attracting: bool    = false

# =========================
# NODES
# =========================
@onready var sprite: Sprite2D = $Sprite2D

# =========================
# INIT
# =========================
func _ready() -> void:
	add_to_group("drops")

func setup(mat_type: String, mat_amount: int = 1) -> void:
	material_type = mat_type
	amount        = mat_amount
	_load_texture()
	_spawn_animation()
	# Lance le timer d'attraction après le délai
	get_tree().create_timer(ATTRACT_DELAY).timeout.connect(_start_attract)

func _load_texture() -> void:
	if not sprite:
		sprite = Sprite2D.new()
		sprite.scale = Vector2(2, 2)
		add_child(sprite)
	if GlobalData.TEXTURE_PATHS.has(material_type):
		var path: String = GlobalData.TEXTURE_PATHS[material_type]
		if ResourceLoader.exists(path):
			sprite.texture = load(path)
		else:
			push_error("[Drop] Texture introuvable : " + path)
	else:
		push_error("[Drop] Type inconnu : " + material_type)

func _spawn_animation() -> void:
	var target_pos := global_position + Vector2(randf_range(-8.0, 8.0), randf_range(-8.0, 8.0))
	scale = Vector2(0.3, 0.3)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(self, "scale",           Vector2(1.0, 1.0), 0.3)
	tween.tween_property(self, "global_position", target_pos,        0.3)

func _start_attract() -> void:
	if is_picked_up: return
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		attract_target = players[0]
		is_attracting  = true

# =========================
# FLOATING + AIMANT
# =========================
func _process(delta: float) -> void:
	if is_picked_up: return

	# Flottement vertical
	if sprite:
		sprite.position.y = sin(Time.get_ticks_msec() * 0.005) * 3.0

	# Attraction vers le joueur
	if is_attracting and is_instance_valid(attract_target):
		var dir := (attract_target.global_position - global_position).normalized()
		global_position += dir * ATTRACT_SPEED * delta

# =========================
# PICKUP
# =========================
func pickup(player: Player) -> void:
	if is_picked_up: return
	is_picked_up = true
	player.add_material(material_type, amount)
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(0, 0), 0.1)
	tween.tween_callback(queue_free)

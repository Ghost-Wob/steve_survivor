extends Node2D
class_name Drop

# =========================
# TEXTURE PATHS
# =========================
const TEXTURE_PATHS: Dictionary = {
	"stick": "res://Asset/pixel_art/items/stick.png",
	"wooden": "res://Asset/pixel_art/items/oak_planks.png",
	"stone": "res://Asset/pixel_art/items/stone.png",
	"gold": "res://Asset/pixel_art/items/gold_ingot.png",
	"iron": "res://Asset/pixel_art/items/iron_ingot.png",
	"diamond": "res://Asset/pixel_art/items/diamond.png",
	"netherite": "res://Asset/pixel_art/items/netherite_ingot.png"
}

# =========================
# STATE
# =========================
var material_type: String = "gold"
var amount: int = 1
var is_picked_up: bool = false

# =========================
# NODES
# =========================
@onready var sprite: Sprite2D = $Sprite2D

# =========================
# INIT
# =========================
func _ready() -> void:
	add_to_group("drops")
	# NE PAS appeler _spawn_animation() ici car global_position n'est pas encore défini

func setup(mat_type: String, mat_amount: int = 1) -> void:
	material_type = mat_type
	amount = mat_amount
	_load_texture()
	_spawn_animation()  # Appeler ICI car global_position est maintenant défini

func _load_texture() -> void:
	if not sprite:
		sprite = Sprite2D.new()
		sprite.scale = Vector2(2, 2)
		add_child(sprite)
	
	if TEXTURE_PATHS.has(material_type):
		var path: String = TEXTURE_PATHS[material_type]
		if ResourceLoader.exists(path):
			sprite.texture = load(path)
		else:
			push_error("[Drop] Texture NOT found: " + path)
	else:
		push_error("[Drop] Unknown material type: " + material_type)

func _spawn_animation() -> void:
	# Random offset dans zone 16x16 centrée sur position actuelle
	var random_offset := Vector2(
		randf_range(-8.0, 8.0),
		randf_range(-8.0, 8.0)
	)
	var target_pos := global_position + random_offset
	
	# Start small
	scale = Vector2(0.3, 0.3)
	
	# Animate scale and position
	var tween := create_tween()
	tween.set_parallel(true)
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.3)
	tween.tween_property(self, "global_position", target_pos, 0.3)

# =========================
# FLOATING
# =========================
func _process(_delta: float) -> void:
	if sprite and not is_picked_up:
		sprite.position.y = sin(Time.get_ticks_msec() * 0.005) * 3.0

# =========================
# PICKUP
# =========================
func pickup(player: Player) -> void:
	if is_picked_up:
		return
	
	is_picked_up = true
	
	player.add_material(material_type, amount)
	
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(0, 0), 0.1)
	tween.tween_callback(queue_free)

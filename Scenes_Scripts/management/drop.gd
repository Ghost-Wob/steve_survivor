extends Node2D
class_name Drop

# =========================
# STATE
# =========================
var material_type: String = "gold"
var amount: int           = 1
var is_picked_up: bool    = false

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
	var target := global_position + Vector2(randf_range(-8.0, 8.0), randf_range(-8.0, 8.0))
	scale = Vector2(0.3, 0.3)
	var t := create_tween()
	t.set_parallel(true)
	t.set_ease(Tween.EASE_OUT)
	t.set_trans(Tween.TRANS_BACK)
	t.tween_property(self, "scale",           Vector2(1.0, 1.0), 0.3)
	t.tween_property(self, "global_position", target,            0.3)

# =========================
# FLOATING
# =========================
func _process(_delta: float) -> void:
	if sprite and not is_picked_up:
		sprite.position.y = sin(Time.get_ticks_msec() * 0.005) * 3.0

# =========================
# PICKUP au contact (géré par player._check_nearby_drops)
# =========================
func pickup(player: Player) -> void:
	if is_picked_up: return
	is_picked_up = true
	player.add_material(material_type, amount)
	var t := create_tween()
	t.tween_property(self, "scale", Vector2(0, 0), 0.1)
	t.tween_callback(queue_free)

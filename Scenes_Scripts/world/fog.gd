extends CanvasLayer

# =========================
# FOG OF WAR (VALEURS FIXES)
# =========================

# Dimensions de la zone visible en PIXELS
const TARGET_WIDTH:  float = 1280.0
const TARGET_HEIGHT: float = 720.0
const SOFTNESS:      float = 20.0   # Douceur en pixels
const FOG_COLOR:     Color = Color(0.04, 0.04, 0.06, 1.0)

const SHADER_CODE := """
shader_type canvas_item;

uniform vec2  screen_size;   // Taille du rect en pixels
uniform vec2  target_size;   // Taille de la zone visible en pixels
uniform float softness;      // Douceur en pixels
uniform vec4  fog_color : source_color;

void fragment() {
    // Conversion de l'UV en coordonnées pixels (0 à screen_size)
    vec2 pixel_pos = UV * screen_size;
    
    // On calcule la distance par rapport au centre de l'écran
    vec2 center = screen_size * 0.5;
    vec2 dist_from_center = abs(pixel_pos - center);
    
    // On définit la demi-taille de la zone visible
    vec2 half_target = target_size * 0.5;

    // Calcul du masque (smoothstep basé sur les pixels)
    float fx = smoothstep(half_target.x, half_target.x + softness, dist_from_center.x);
    float fy = smoothstep(half_target.y, half_target.y + softness, dist_from_center.y);

    float fog = max(fx, fy);
    COLOR = vec4(fog_color.rgb, fog * fog_color.a);
}
"""

var mat : ShaderMaterial

func _ready() -> void:
	var shader := Shader.new()
	shader.code = SHADER_CODE

	mat = ShaderMaterial.new()
	mat.shader = shader
	
	# Configuration initiale des paramètres
	mat.set_shader_parameter("target_size", Vector2(TARGET_WIDTH, TARGET_HEIGHT))
	mat.set_shader_parameter("softness", SOFTNESS)
	mat.set_shader_parameter("fog_color", FOG_COLOR)

	var rect := ColorRect.new()
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.material = mat

	var base := Control.new()
	base.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	base.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(base)
	base.add_child(rect)
	
	# Connecter le signal de redimensionnement pour mettre à jour screen_size
	get_viewport().size_changed.connect(_update_shader_screen_size)
	_update_shader_screen_size()

func _update_shader_screen_size() -> void:
	# On récupère la taille réelle de la fenêtre ou du viewport
	var size = get_viewport().get_visible_rect().size
	mat.set_shader_parameter("screen_size", size)

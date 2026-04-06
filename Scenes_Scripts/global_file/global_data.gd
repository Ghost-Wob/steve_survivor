extends Node

# =========================
# MATERIALS
# =========================
const MATERIAL_ORDER: Array[String] = [
	"stick", "wooden", "stone", "gold", "iron", "diamond", "netherite"
]

const TEXTURE_PATHS: Dictionary = {
	"stick":      "res://Asset/pixel_art/items/stick.png",
	"wooden":     "res://Asset/pixel_art/items/oak_planks.png",
	"stone":      "res://Asset/pixel_art/items/stone.png",
	"gold":       "res://Asset/pixel_art/items/gold_ingot.png",
	"iron":       "res://Asset/pixel_art/items/iron_ingot.png",
	"diamond":    "res://Asset/pixel_art/items/diamond.png",
	"netherite":  "res://Asset/pixel_art/items/netherite_ingot.png",
	"apple":      "res://Asset/pixel_art/items/apple.png"
}

# =========================
# WEAPON TEXTURE PATHS
# Les fichiers s'appellent golden_sword, pas gold_sword
# =========================
const WEAPON_TEXTURE_PATHS: Dictionary = {
	"stick":     "res://Asset/pixel_art/items/stick.png",
	"wooden":    "res://Asset/pixel_art/weapons/swords/wooden_sword.png",
	"stone":     "res://Asset/pixel_art/weapons/swords/stone_sword.png",
	"gold":      "res://Asset/pixel_art/weapons/swords/golden_sword.png",
	"iron":      "res://Asset/pixel_art/weapons/swords/iron_sword.png",
	"diamond":   "res://Asset/pixel_art/weapons/swords/diamond_sword.png",
	"netherite": "res://Asset/pixel_art/weapons/swords/netherite_sword.png"
}

func get_weapon_texture_path(tier_name: String) -> String:
	return WEAPON_TEXTURE_PATHS.get(tier_name, "")

# =========================
# UPGRADE RECIPES
# =========================
const UPGRADE_RECIPES: Dictionary = {
	"wooden":    {"stick": 1, "wooden": 2},
	"stone":     {"stick": 1, "stone": 2},
	"gold":      {"stick": 1, "gold": 2},
	"iron":      {"stick": 1, "iron": 2},
	"diamond":   {"stick": 1, "diamond": 2},
	"netherite": {"stick": 1, "netherite": 1}
}

# =========================
# ZOMBIE DROP CHANCES
# =========================
const ZOMBIE_DROPS: Dictionary = {
	"stick":     0.8,
	"wooden":    0.5,
	"stone":     0.25,
	"gold":      0.15,
	"iron":      0.08,
	"diamond":   0.03,
	"netherite": 0.01,
	"apple":     0.4
}

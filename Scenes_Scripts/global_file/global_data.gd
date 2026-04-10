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
	"apple":      "res://Asset/pixel_art/items/apple.png",
	"xp_orb":     "res://Asset/pixel_art/minecraft_origins/textures/entity/experience_orb.png"
}

# =========================
# WEAPON TEXTURES
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
# DROP CHANCES — divisées par 10 vs version précédente
# =========================
const ZOMBIE_DROPS: Dictionary = {
	"stick":     0.08,
	"wooden":    0.05,
	"stone":     0.025,
	"gold":      0.015,
	"iron":      0.008,
	"diamond":   0.003,
	"netherite": 0.001,
	"apple":     0.04
}

# =========================
# XP SYSTEM
# =========================
const MAX_LEVEL: int = 10
const XP_PER_KILL: int = 15

# XP total cumulatif requis pour atteindre chaque niveau
# Index = niveau cible (index 1 = XP pour passer de lvl1 à lvl2)
# Calibré pour ~40 min de jeu
const XP_TABLE: Array[int] = [
	0,      # lvl 1 (départ)
	300,    # lvl 2
	900,    # lvl 3
	2400,   # lvl 4
	5400,   # lvl 5
	10400,  # lvl 6
	18400,  # lvl 7
	30400,  # lvl 8
	48400,  # lvl 9
	74400   # lvl 10
]

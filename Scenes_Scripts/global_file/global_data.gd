extends Node

# =========================
# MATERIALS — ordre croissant de rareté
# wooden = copper (lore), stone = chain (lore)
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
	"xp_orb":     "res://Asset/pixel_art/minecraft_origins/textures/entity/experience_orb.png",
	"craft_table":"res://Asset/pixel_art/minecraft_origins/textures/block/crafting_table_front.png"
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
# ARMOR TEXTURES
# prefix_name → nom du fichier (copper, chainmail, golden, iron, diamond, netherite)
# =========================
const ARMOR_TIER_PREFIXES: Array[String] = [
	"copper", "chainmail", "golden", "iron", "diamond", "netherite"
]

# Quel matériau (MATERIAL_ORDER) correspond à quel tier d'armure (index)
const ARMOR_MATERIAL_FOR_TIER: Array[String] = [
	"wooden", "stone", "gold", "iron", "diamond", "netherite"
]

const ARMOR_PIECE_NAMES: Array[String] = ["boots", "leggings", "chestplate", "helmet"]

func get_armor_texture(tier_idx: int, piece: String) -> String:
	if tier_idx < 0 or tier_idx >= ARMOR_TIER_PREFIXES.size():
		return ""
	return "res://Asset/pixel_art/armors/" + ARMOR_TIER_PREFIXES[tier_idx] + "_" + piece + ".png"

# =========================
# ARMOR COSTS (sans stick, comme Minecraft)
# =========================
const ARMOR_COSTS: Dictionary = {
	"boots":      4,
	"leggings":   7,
	"chestplate": 8,
	"helmet":     5
}

# Ordre de craft des pièces d'armure (priorité)
const ARMOR_ORDER: Array[String] = ["boots", "leggings", "chestplate", "helmet"]

# HP bonus par pièce par tier (index = tier 0-5)
const ARMOR_HP_PER_PIECE: Array[int] = [1, 2, 2, 3, 4, 5]

# =========================
# SWORD UPGRADE RECIPES
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
# CONVERSION
# Cap avant conversion : 44 pour matériaux, 60 pour sticks
# Ratio : 16:1 vers le tier suivant
# Sticks → pommes (exception)
# =========================
const MATERIAL_CAP: Dictionary = {
	"stick":     60,
	"wooden":    44,
	"stone":     44,
	"gold":      44,
	"iron":      44,
	"diamond":   44,
	"netherite": 44   # netherite ne convertit pas (fin de chaîne)
}

const CONVERSION_NEXT: Dictionary = {
	"stick":   "apple",     # exception : sticks → pommes
	"wooden":  "stone",
	"stone":   "gold",
	"gold":    "iron",
	"iron":    "diamond",
	"diamond": "netherite"
	# netherite : absent → pas de conversion
}

const CONVERSION_RATIO: int = 16

# =========================
# ZOMBIE DROPS (÷10 vs version précédente)
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

# =========================
# XP SYSTEM
# =========================
const MAX_LEVEL: int  = 10
const XP_PER_KILL: int = 15

# XP cumulatif pour passer au niveau suivant (index = niveau actuel)
const XP_TABLE: Array[int] = [
	0, 300, 900, 2400, 5400, 10400, 18400, 30400, 48400, 74400
]

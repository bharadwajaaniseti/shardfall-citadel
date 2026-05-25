class_name GameDatabaseAutoload
extends Node

const BALLS: Dictionary = {
	"starter_ball": {
		"id": "starter_ball",
		"display_name": "Shard Pebble",
		"rarity": "common",
		"damage": 1,
		"speed": 720.0,
		"pierce": 0,
		"bounce_bonus": 0,
		"description": "A reliable ricochet shot for new citadel defenders.",
	},
	"iron_orb": {
		"id": "iron_orb",
		"display_name": "Iron Orb",
		"rarity": "uncommon",
		"damage": 2,
		"speed": 620.0,
		"pierce": 1,
		"bounce_bonus": 0,
		"description": "A heavier ball that breaks fortified blocks.",
	},
	"splinter_prism": {
		"id": "splinter_prism",
		"display_name": "Splinter Prism",
		"rarity": "rare",
		"damage": 1,
		"speed": 760.0,
		"pierce": 0,
		"bounce_bonus": 2,
		"description": "Gains extra angles after each wall bounce.",
	},
}

const RELICS: Dictionary = {
	"echo_chamber": {
		"id": "echo_chamber",
		"display_name": "Echo Chamber",
		"rarity": "common",
		"description": "The first shot each wave repeats at reduced force.",
		"tags": ["shot", "duplicate"],
	},
	"citadel_heart": {
		"id": "citadel_heart",
		"display_name": "Citadel Heart",
		"rarity": "uncommon",
		"description": "Heal the citadel after every third completed wave.",
		"tags": ["defense", "healing"],
	},
	"prism_lens": {
		"id": "prism_lens",
		"display_name": "Prism Lens",
		"rarity": "rare",
		"description": "Critical ricochets create a short-lived shard beam.",
		"tags": ["ricochet", "critical"],
	},
}

const BLOCKS: Dictionary = {
	"stone_block": {
		"id": "stone_block",
		"display_name": "Stone Block",
		"hp": 2,
		"armor": 0,
		"reward": {"shards": 1},
	},
	"crystal_block": {
		"id": "crystal_block",
		"display_name": "Crystal Block",
		"hp": 1,
		"armor": 0,
		"reward": {"shards": 2},
	},
	"bulwark_block": {
		"id": "bulwark_block",
		"display_name": "Bulwark Block",
		"hp": 4,
		"armor": 1,
		"reward": {"shards": 3},
	},
}

const ENEMIES: Dictionary = {
	"shardling": {
		"id": "shardling",
		"display_name": "Shardling",
		"hp": 3,
		"damage": 5,
		"speed": 80.0,
		"reward": {"shards": 2},
	},
	"siege_wisp": {
		"id": "siege_wisp",
		"display_name": "Siege Wisp",
		"hp": 5,
		"damage": 8,
		"speed": 55.0,
		"reward": {"shards": 4},
	},
	"rift_bulwark": {
		"id": "rift_bulwark",
		"display_name": "Rift Bulwark",
		"hp": 12,
		"damage": 15,
		"speed": 25.0,
		"reward": {"shards": 8, "relic_dust": 1},
	},
}

const UPGRADES: Dictionary = {
	"citadel_plating": {
		"id": "citadel_plating",
		"display_name": "Citadel Plating",
		"max_level": 10,
		"base_cost": {"shards": 25},
		"description": "Increase maximum citadel HP between runs.",
	},
	"extra_reserve_shot": {
		"id": "extra_reserve_shot",
		"display_name": "Reserve Shot",
		"max_level": 5,
		"base_cost": {"shards": 40},
		"description": "Begin each run with an extra shot every few levels.",
	},
	"ricochet_training": {
		"id": "ricochet_training",
		"display_name": "Ricochet Training",
		"max_level": 8,
		"base_cost": {"cores": 1, "shards": 20},
		"description": "Improve ball speed and wall-bounce consistency.",
	},
	"relic_attunement": {
		"id": "relic_attunement",
		"display_name": "Relic Attunement",
		"max_level": 6,
		"base_cost": {"relic_dust": 5},
		"description": "Improve the quality of relic choices during a run.",
	},
}


func get_ball(id: StringName) -> Dictionary:
	return _get_entry(BALLS, id)


func get_relic(id: StringName) -> Dictionary:
	return _get_entry(RELICS, id)


func get_block(id: StringName) -> Dictionary:
	return _get_entry(BLOCKS, id)


func get_enemy(id: StringName) -> Dictionary:
	return _get_entry(ENEMIES, id)


func get_upgrade(id: StringName) -> Dictionary:
	return _get_entry(UPGRADES, id)


func get_all_balls() -> Dictionary:
	return BALLS.duplicate(true)


func get_all_relics() -> Dictionary:
	return RELICS.duplicate(true)


func get_all_blocks() -> Dictionary:
	return BLOCKS.duplicate(true)


func get_all_enemies() -> Dictionary:
	return ENEMIES.duplicate(true)


func get_all_upgrades() -> Dictionary:
	return UPGRADES.duplicate(true)


func _get_entry(source: Dictionary, id: StringName) -> Dictionary:
	var key: String = String(id)
	if not source.has(key):
		return {}
	var entry: Variant = source[key]
	if not (entry is Dictionary):
		return {}
	var entry_data: Dictionary = entry as Dictionary
	return entry_data.duplicate(true)

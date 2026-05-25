class_name GameDatabaseAutoload
extends Node

const BALLS: Dictionary = {
	"basic_orb": {
		"id": "basic_orb",
		"display_name": "Basic Orb",
		"description": "A balanced starter orb with normal damage, speed, and bounce.",
		"base_damage": 1,
		"speed": 840.0,
		"radius": 12.0,
		"color": "#dfffe8",
		"behaviour_type": "basic",
		"parameters": {},
	},
	"heavy_orb": {
		"id": "heavy_orb",
		"display_name": "Heavy Orb",
		"description": "A slower, larger orb that hits harder and resists void pull.",
		"base_damage": 2,
		"speed": 680.0,
		"radius": 16.0,
		"color": "#d6b85f",
		"behaviour_type": "heavy",
		"parameters": {
			"void_pull_resistance": 0.45,
		},
	},
	"ember_orb": {
		"id": "ember_orb",
		"display_name": "Ember Orb",
		"description": "Applies short burn damage after direct hits.",
		"base_damage": 1,
		"speed": 840.0,
		"radius": 12.0,
		"color": "#f26a3d",
		"behaviour_type": "ember",
		"parameters": {
			"burn_damage": 1,
			"burn_ticks": 2,
		},
	},
	"frost_orb": {
		"id": "frost_orb",
		"display_name": "Frost Orb",
		"description": "Chills blocks so the next hit deals bonus damage.",
		"base_damage": 1,
		"speed": 800.0,
		"radius": 12.0,
		"color": "#78e1ff",
		"behaviour_type": "frost",
		"parameters": {
			"chill_duration": 3.0,
			"freeze_bonus_multiplier": 1.75,
		},
	},
	"spark_orb": {
		"id": "spark_orb",
		"display_name": "Spark Orb",
		"description": "Can chain small damage to a nearby block on hit.",
		"base_damage": 1,
		"speed": 900.0,
		"radius": 11.0,
		"color": "#f4e85f",
		"behaviour_type": "spark",
		"parameters": {
			"chain_range": 150.0,
			"chain_damage": 1,
			"chain_chance": 0.45,
		},
	},
	"split_orb": {
		"id": "split_orb",
		"display_name": "Split Orb",
		"description": "Splits once into smaller orbs after enough bounces.",
		"base_damage": 1,
		"speed": 820.0,
		"radius": 11.0,
		"color": "#d7ff56",
		"behaviour_type": "split",
		"parameters": {
			"split_after_bounces": 3,
			"split_count": 2,
			"split_damage_multiplier": 0.65,
		},
	},
	"drill_orb": {
		"id": "drill_orb",
		"display_name": "Drill Orb",
		"description": "Pierces through the first block it hits, then behaves normally.",
		"base_damage": 1,
		"speed": 800.0,
		"radius": 12.0,
		"color": "#8de2d4",
		"behaviour_type": "drill",
		"parameters": {
			"pierce_count": 1,
		},
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
	"basic_block": {
		"id": "basic_block",
		"display_name": "Basic Block",
		"base_hp": 1,
		"color": "#2f97c7",
		"description": "A simple shard block that takes normal damage.",
		"behaviour_type": "basic",
		"parameters": {},
		"reward": {"shards": 1},
	},
	"stone_block": {
		"id": "stone_block",
		"display_name": "Stone Block",
		"base_hp": 3,
		"color": "#7f858d",
		"description": "A durable stone block with higher HP.",
		"behaviour_type": "stone",
		"parameters": {},
		"reward": {"shards": 2},
	},
	"bloom_pod": {
		"id": "bloom_pod",
		"display_name": "Bloom Pod",
		"base_hp": 2,
		"color": "#4fbf65",
		"description": "Heals nearby blocks when hit, but not when destroyed.",
		"behaviour_type": "bloom",
		"parameters": {
			"heal_radius": 120.0,
			"heal_amount": 1,
		},
		"reward": {"shards": 2},
	},
	"ember_crystal": {
		"id": "ember_crystal",
		"display_name": "Ember Crystal",
		"base_hp": 2,
		"color": "#e46936",
		"description": "Explodes on destruction and damages nearby blocks.",
		"behaviour_type": "ember",
		"parameters": {
			"explosion_radius": 130.0,
			"explosion_damage": 1,
		},
		"reward": {"shards": 3},
	},
	"frost_shell": {
		"id": "frost_shell",
		"display_name": "Frost Shell",
		"base_hp": 3,
		"color": "#54c8df",
		"description": "Armoured ice that reduces incoming damage.",
		"behaviour_type": "frost",
		"parameters": {
			"armour": 1,
		},
		"reward": {"shards": 3},
	},
	"mirror_shard": {
		"id": "mirror_shard",
		"display_name": "Mirror Shard",
		"base_hp": 2,
		"color": "#35c7bd",
		"description": "Boosts the ball slightly when struck.",
		"behaviour_type": "mirror",
		"parameters": {
			"speed_multiplier": 1.12,
			"max_speed": 1120.0,
		},
		"reward": {"shards": 3},
	},
	"void_stone": {
		"id": "void_stone",
		"display_name": "Void Stone",
		"base_hp": 4,
		"color": "#7650b8",
		"description": "Pulls nearby balls toward itself with a weak attraction.",
		"behaviour_type": "void",
		"parameters": {
			"attraction_radius": 190.0,
			"attraction_strength": 210.0,
		},
		"reward": {"shards": 4},
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


func get_ball(id: String) -> Dictionary:
	return _get_entry(BALLS, StringName(id))


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

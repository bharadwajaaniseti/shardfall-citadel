class_name GameStateAutoload
extends Node

signal progress_loaded
signal progress_reset

var shards: int = 0
var cores: int = 0
var relic_dust: int = 0
var seasonal_essence: int = 0
var citadel_level: int = 1
var unlocked_balls: Array = ["starter_ball"]
var unlocked_relics: Array = []
var permanent_upgrades: Dictionary = {}

const CURRENCY_IDS: Array = ["shards", "cores", "relic_dust", "seasonal_essence"]


func add_currency(currency_id: StringName, amount: int) -> bool:
	if not CURRENCY_IDS.has(String(currency_id)):
		push_warning("Unknown currency: %s" % String(currency_id))
		return false

	var new_total: int = maxi(0, get_currency(currency_id) + amount)
	set_currency(currency_id, new_total)
	_emit_currency_changed(currency_id, amount, new_total)
	return true


func spend_currency(currency_id: StringName, amount: int) -> bool:
	if amount <= 0:
		return true
	if get_currency(currency_id) < amount:
		return false
	return add_currency(currency_id, -amount)


func set_currency(currency_id: StringName, value: int) -> bool:
	var clamped_value: int = maxi(0, value)
	match String(currency_id):
		"shards":
			shards = clamped_value
		"cores":
			cores = clamped_value
		"relic_dust":
			relic_dust = clamped_value
		"seasonal_essence":
			seasonal_essence = clamped_value
		_:
			push_warning("Unknown currency: %s" % String(currency_id))
			return false
	return true


func get_currency(currency_id: StringName) -> int:
	match String(currency_id):
		"shards":
			return shards
		"cores":
			return cores
		"relic_dust":
			return relic_dust
		"seasonal_essence":
			return seasonal_essence
		_:
			return 0


func unlock_ball(ball_id: StringName) -> bool:
	var id: String = String(ball_id)
	if id.is_empty() or unlocked_balls.has(id):
		return false
	unlocked_balls.append(id)
	return true


func unlock_relic(relic_id: StringName) -> bool:
	var id: String = String(relic_id)
	if id.is_empty() or unlocked_relics.has(id):
		return false
	unlocked_relics.append(id)
	return true


func has_ball(ball_id: StringName) -> bool:
	return unlocked_balls.has(String(ball_id))


func has_relic(relic_id: StringName) -> bool:
	return unlocked_relics.has(String(relic_id))


func set_upgrade_level(upgrade_id: StringName, level: int) -> void:
	var id: String = String(upgrade_id)
	if id.is_empty():
		return
	permanent_upgrades[id] = max(0, level)


func get_upgrade_level(upgrade_id: StringName) -> int:
	return int(permanent_upgrades.get(String(upgrade_id), 0))


func raise_citadel_level(amount: int = 1) -> void:
	citadel_level = max(1, citadel_level + amount)


func to_save_data() -> Dictionary:
	return {
		"shards": shards,
		"cores": cores,
		"relic_dust": relic_dust,
		"seasonal_essence": seasonal_essence,
		"citadel_level": citadel_level,
		"unlocked_balls": unlocked_balls.duplicate(),
		"unlocked_relics": unlocked_relics.duplicate(),
		"permanent_upgrades": permanent_upgrades.duplicate(true),
	}


func apply_save_data(data: Dictionary) -> void:
	shards = maxi(0, int(data.get("shards", 0)))
	cores = maxi(0, int(data.get("cores", 0)))
	relic_dust = maxi(0, int(data.get("relic_dust", 0)))
	seasonal_essence = maxi(0, int(data.get("seasonal_essence", 0)))
	citadel_level = maxi(1, int(data.get("citadel_level", 1)))
	unlocked_balls = _as_string_array(data.get("unlocked_balls", ["starter_ball"]))
	unlocked_relics = _as_string_array(data.get("unlocked_relics", []))
	permanent_upgrades = _as_upgrade_dictionary(data.get("permanent_upgrades", {}))

	if not unlocked_balls.has("starter_ball"):
		unlocked_balls.insert(0, "starter_ball")

	progress_loaded.emit()


func reset_to_defaults() -> void:
	shards = 0
	cores = 0
	relic_dust = 0
	seasonal_essence = 0
	citadel_level = 1
	unlocked_balls = ["starter_ball"]
	unlocked_relics = []
	permanent_upgrades = {}
	progress_reset.emit()


func _as_string_array(value: Variant) -> Array:
	var result: Array = []
	if value is Array:
		for item in value:
			var id: String = String(item)
			if not id.is_empty() and not result.has(id):
				result.append(id)
	return result


func _as_upgrade_dictionary(value: Variant) -> Dictionary:
	var result: Dictionary = {}
	if value is Dictionary:
		for key in value.keys():
			var id: String = String(key)
			if not id.is_empty():
				result[id] = maxi(0, int(value[key]))
	return result


func _emit_currency_changed(currency_id: StringName, amount: int, total: int) -> void:
	var bus: Node = get_node_or_null("/root/EventBus")
	if bus != null and bus.has_signal("currency_changed"):
		bus.emit_signal("currency_changed", currency_id, amount, total)

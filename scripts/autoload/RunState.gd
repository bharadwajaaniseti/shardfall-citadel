class_name RunStateAutoload
extends Node

var current_wave: int = 0
var citadel_hp: int = 100
var max_citadel_hp: int = 100
var shots_remaining: int = 0
var active_relics: Array = []
var run_modifiers: Dictionary = {}
var run_rewards: Dictionary = {}
var is_run_active: bool = false


func start_run(starting_hp: int = 100, starting_shots: int = 8, modifiers: Dictionary = {}) -> void:
	max_citadel_hp = maxi(1, starting_hp)
	citadel_hp = max_citadel_hp
	shots_remaining = maxi(0, starting_shots)
	current_wave = 0
	active_relics = []
	run_modifiers = modifiers.duplicate(true)
	run_rewards = {
		"shards": 0,
		"relic_dust": 0,
	}
	is_run_active = true
	_emit_run_started()
	_emit_citadel_hp_changed(0)


func end_run(victory: bool = false) -> void:
	if not is_run_active:
		return
	is_run_active = false
	_emit_run_ended(victory)


func start_wave(wave_number: int, shots_for_wave: int = -1) -> void:
	if not is_run_active:
		start_run(max_citadel_hp, maxi(shots_for_wave, 0), run_modifiers)
	current_wave = maxi(1, wave_number)
	if shots_for_wave >= 0:
		shots_remaining = shots_for_wave
	_emit_wave_started()


func complete_wave(rewards: Dictionary = {}) -> void:
	if current_wave <= 0:
		return
	for reward_id in rewards.keys():
		add_reward(StringName(String(reward_id)), int(rewards[reward_id]))
	_emit_wave_completed(rewards)


func spend_shot(amount: int = 1) -> bool:
	if amount <= 0:
		return true
	if shots_remaining < amount:
		return false
	shots_remaining -= amount
	return true


func restore_shots(amount: int) -> void:
	shots_remaining = maxi(0, shots_remaining + amount)


func damage_citadel(amount: int) -> void:
	if amount <= 0:
		return
	var previous_hp: int = citadel_hp
	citadel_hp = maxi(0, citadel_hp - amount)
	_emit_citadel_hp_changed(citadel_hp - previous_hp)
	if citadel_hp <= 0:
		end_run(false)


func heal_citadel(amount: int) -> void:
	if amount <= 0:
		return
	var previous_hp: int = citadel_hp
	citadel_hp = mini(max_citadel_hp, citadel_hp + amount)
	_emit_citadel_hp_changed(citadel_hp - previous_hp)


func add_relic(relic_id: StringName) -> bool:
	var id: String = String(relic_id)
	if id.is_empty() or active_relics.has(id):
		return false
	active_relics.append(id)
	_emit_relic_selected(relic_id)
	return true


func add_modifier(modifier_id: StringName, value: Variant) -> void:
	var id: String = String(modifier_id)
	if id.is_empty():
		return
	run_modifiers[id] = value


func add_reward(reward_id: StringName, amount: int) -> void:
	if amount == 0:
		return
	var id: String = String(reward_id)
	run_rewards[id] = maxi(0, int(run_rewards.get(id, 0)) + amount)


func get_run_snapshot() -> Dictionary:
	return {
		"current_wave": current_wave,
		"citadel_hp": citadel_hp,
		"max_citadel_hp": max_citadel_hp,
		"shots_remaining": shots_remaining,
		"active_relics": active_relics.duplicate(),
		"run_modifiers": run_modifiers.duplicate(true),
		"run_rewards": run_rewards.duplicate(true),
		"is_run_active": is_run_active,
	}


func reset_run() -> void:
	current_wave = 0
	citadel_hp = max_citadel_hp
	shots_remaining = 0
	active_relics = []
	run_modifiers = {}
	run_rewards = {}
	is_run_active = false


func _emit_run_started() -> void:
	var bus: Node = get_node_or_null("/root/EventBus")
	if bus != null and bus.has_signal("run_started"):
		bus.emit_signal("run_started", get_run_snapshot())


func _emit_run_ended(victory: bool) -> void:
	var bus: Node = get_node_or_null("/root/EventBus")
	if bus != null and bus.has_signal("run_ended"):
		bus.emit_signal("run_ended", victory, run_rewards.duplicate(true))


func _emit_wave_started() -> void:
	var bus: Node = get_node_or_null("/root/EventBus")
	if bus != null and bus.has_signal("wave_started"):
		bus.emit_signal("wave_started", current_wave)


func _emit_wave_completed(rewards: Dictionary) -> void:
	var bus: Node = get_node_or_null("/root/EventBus")
	if bus != null and bus.has_signal("wave_completed"):
		bus.emit_signal("wave_completed", current_wave, rewards.duplicate(true))


func _emit_relic_selected(relic_id: StringName) -> void:
	var bus: Node = get_node_or_null("/root/EventBus")
	if bus != null and bus.has_signal("relic_selected"):
		bus.emit_signal("relic_selected", relic_id)


func _emit_citadel_hp_changed(delta: int) -> void:
	var bus: Node = get_node_or_null("/root/EventBus")
	if bus != null and bus.has_signal("citadel_hp_changed"):
		bus.emit_signal("citadel_hp_changed", citadel_hp, max_citadel_hp, delta)

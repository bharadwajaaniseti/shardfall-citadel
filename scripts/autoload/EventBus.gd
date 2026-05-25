class_name EventBusAutoload
extends Node

signal currency_changed(currency_id: StringName, amount: int, total: int)
signal run_started(run_data: Dictionary)
signal run_ended(victory: bool, rewards: Dictionary)
signal wave_started(wave: int)
signal wave_completed(wave: int, rewards: Dictionary)
signal block_destroyed(block_id: StringName, world_position: Vector2, rewards: Dictionary)
signal relic_selected(relic_id: StringName)
signal citadel_hp_changed(current_hp: int, max_hp: int, delta: int)


func notify_currency_changed(currency_id: StringName, amount: int, total: int) -> void:
	currency_changed.emit(currency_id, amount, total)


func notify_run_started(run_data: Dictionary) -> void:
	run_started.emit(run_data.duplicate(true))


func notify_run_ended(victory: bool, rewards: Dictionary) -> void:
	run_ended.emit(victory, rewards.duplicate(true))


func notify_wave_started(wave: int) -> void:
	wave_started.emit(wave)


func notify_wave_completed(wave: int, rewards: Dictionary) -> void:
	wave_completed.emit(wave, rewards.duplicate(true))


func notify_block_destroyed(block_id: StringName, world_position: Vector2, rewards: Dictionary = {}) -> void:
	block_destroyed.emit(block_id, world_position, rewards.duplicate(true))


func notify_relic_selected(relic_id: StringName) -> void:
	relic_selected.emit(relic_id)


func notify_citadel_hp_changed(current_hp: int, max_hp: int, delta: int) -> void:
	citadel_hp_changed.emit(current_hp, max_hp, delta)

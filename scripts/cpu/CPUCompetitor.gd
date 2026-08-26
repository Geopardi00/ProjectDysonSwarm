extends RefCounted
class_name CPUCompetitor

const GameDataScript := preload("res://scripts/data/GameData.gd")

var faction_id := ""
var display_name := ""
var progress_percent := 0.0
var speed_per_day := 0.0
var crash_chance := 0.0
var news_style := ""
var difficulty := GameDataScript.DEFAULT_DIFFICULTY
var difficulty_profile: Dictionary = {}


func setup(id: String, data: Dictionary, selected_difficulty: String = GameDataScript.DEFAULT_DIFFICULTY) -> void:
	faction_id = id
	display_name = data.get("display_name", id)
	progress_percent = 0.0
	speed_per_day = float(data.get("speed_per_day", 0.0))
	crash_chance = float(data.get("crash_chance", 0.0))
	news_style = data.get("news_style", "")
	difficulty = GameDataScript.normalize_difficulty(selected_difficulty)
	difficulty_profile = GameDataScript.get_difficulty_profile(difficulty)


func advance_days(days: int, rng: RandomNumberGenerator) -> Dictionary:
	var vehicle_id := _choose_vehicle(rng)
	var vehicle := GameDataScript.get_vehicle(vehicle_id)
	var speed_multiplier := float(difficulty_profile.get("cpu_speed_multiplier", 1.0))
	var vehicle_multiplier := float(GameDataScript.CPU_VEHICLE_PROGRESS_MULTIPLIERS.get(vehicle_id, 1.0))
	var effective_crash_chance := clampf(
		crash_chance * float(difficulty_profile.get("cpu_crash_multiplier", 1.0)),
		0.0,
		1.0
	)
	var base_gain := float(days) * speed_per_day * speed_multiplier * vehicle_multiplier
	var crashed := rng.randf() < effective_crash_chance
	var actual_gain := base_gain * 0.25 if crashed else base_gain
	var previous_progress := progress_percent
	progress_percent = clampf(progress_percent + actual_gain, 0.0, 100.0)

	return {
		"faction_id": faction_id,
		"display_name": display_name,
		"difficulty": difficulty,
		"vehicle_id": vehicle_id,
		"vehicle_name": String(vehicle.get("display_name", vehicle_id)),
		"days": days,
		"crashed": crashed,
		"effective_crash_chance": effective_crash_chance,
		"base_gain": base_gain,
		"actual_gain": actual_gain,
		"previous_progress": previous_progress,
		"progress_percent": progress_percent,
	}


func _choose_vehicle(rng: RandomNumberGenerator) -> String:
	var weights: Dictionary = difficulty_profile.get("cpu_vehicle_weights", {})
	var available: Array[String] = []
	var total_weight := 0.0
	for vehicle_id: String in ["big_rocket", "space_shuttle", "spinlaunch"]:
		var weight := maxf(0.0, float(weights.get(vehicle_id, 0.0)))
		if weight > 0.0:
			available.append(vehicle_id)
			total_weight += weight
	if available.size() == 1:
		return available[0]
	if available.is_empty() or total_weight <= 0.0:
		return "big_rocket"
	var roll := rng.randf() * total_weight
	for vehicle_id: String in available:
		roll -= float(weights.get(vehicle_id, 0.0))
		if roll < 0.0:
			return vehicle_id
	return available[-1]


func is_complete() -> bool:
	return progress_percent >= 100.0

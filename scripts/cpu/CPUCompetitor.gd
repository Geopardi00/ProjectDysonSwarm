extends RefCounted
class_name CPUCompetitor

var faction_id := ""
var display_name := ""
var progress_percent := 0.0
var speed_per_day := 0.0
var crash_chance := 0.0
var news_style := ""


func setup(id: String, data: Dictionary) -> void:
	faction_id = id
	display_name = data.get("display_name", id)
	progress_percent = 0.0
	speed_per_day = float(data.get("speed_per_day", 0.0))
	crash_chance = float(data.get("crash_chance", 0.0))
	news_style = data.get("news_style", "")


func advance_days(days: int, rng: RandomNumberGenerator) -> Dictionary:
	var base_gain := float(days) * speed_per_day
	var crashed := rng.randf() < crash_chance
	var actual_gain := base_gain * 0.25 if crashed else base_gain
	var previous_progress := progress_percent
	progress_percent = clampf(progress_percent + actual_gain, 0.0, 100.0)

	return {
		"faction_id": faction_id,
		"display_name": display_name,
		"days": days,
		"crashed": crashed,
		"base_gain": base_gain,
		"actual_gain": actual_gain,
		"previous_progress": previous_progress,
		"progress_percent": progress_percent,
	}


func is_complete() -> bool:
	return progress_percent >= 100.0

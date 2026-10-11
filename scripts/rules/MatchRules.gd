extends RefCounted
class_name MatchRules

# Challenge restrictions layered on top of a standard match. The defaults
# describe a normal match; each challenge modifier overrides one or more
# fields. Rules never change cargo or launch resolution, only what the player
# may use, what counts as a loss, and which data the match starts from.

const GameDataScript := preload("res://scripts/data/GameData.gd")

const UNLIMITED := -1
const RANDOM_SEED := -1

var cpu_enabled := true
var max_failures := UNLIMITED
var max_launches := UNLIMITED
var allowed_vehicles: Array[String] = []
var piece_set_id := GameDataScript.STANDARD_PIECE_SET_ID
var moonbase_requirements: Dictionary = {}
var cpu_profile_override := ""
var rng_seed := RANDOM_SEED


func is_vehicle_allowed(vehicle_id: String) -> bool:
	return allowed_vehicles.is_empty() or allowed_vehicles.has(vehicle_id)


func get_moonbase_requirements() -> Dictionary:
	if moonbase_requirements.is_empty():
		return GameDataScript.MOONBASE_REQUIREMENTS.duplicate(true)
	return moonbase_requirements.duplicate(true)


func get_launches_remaining(launches_attempted: int) -> int:
	if max_launches == UNLIMITED:
		return UNLIMITED
	return maxi(max_launches - launches_attempted, 0)

extends Node
class_name GameState

const GameDataScript := preload("res://scripts/data/GameData.gd")
const MoonbaseScript := preload("res://scripts/moonbase/Moonbase.gd")
const CPUCompetitorScript := preload("res://scripts/cpu/CPUCompetitor.gd")
const NewsManagerScript := preload("res://scripts/news/NewsManager.gd")
const MatchRulesScript := preload("res://scripts/rules/MatchRules.gd")

const LOSS_REASON_RIVAL_FINISHED := "rival_finished"
const LOSS_REASON_FAILURE_LIMIT := "failure_limit"
const LOSS_REASON_LAUNCH_LIMIT := "launch_limit"

var player_faction := "USA"
var days_elapsed := 0
var launches_attempted := 0
var successful_launches := 0
var failed_launches := 0
var game_over := false
var player_won := false
var winner_name := ""
var loss_reason := ""
var active_difficulty := GameDataScript.DEFAULT_DIFFICULTY
var active_rules: MatchRules = MatchRulesScript.new()

var moonbase: Moonbase
var competitors: Array[CPUCompetitor] = []
var news: NewsManager
var rng := RandomNumberGenerator.new()


func _ready() -> void:
	start_new_match(player_faction)


func start_new_match(
	selected_faction: String = "USA",
	selected_difficulty: String = GameDataScript.DEFAULT_DIFFICULTY,
	rules: MatchRules = null
) -> void:
	player_faction = selected_faction
	active_difficulty = GameDataScript.normalize_difficulty(selected_difficulty)
	active_rules = rules if rules != null else MatchRulesScript.new()
	days_elapsed = 0
	launches_attempted = 0
	successful_launches = 0
	failed_launches = 0
	game_over = false
	player_won = false
	winner_name = ""
	loss_reason = ""

	if active_rules.rng_seed == MatchRules.RANDOM_SEED:
		rng.randomize()
	else:
		rng.seed = active_rules.rng_seed
	moonbase = MoonbaseScript.new()
	moonbase.setup(active_rules.get_moonbase_requirements())
	news = NewsManagerScript.new()
	news.add_message("The lunar construction race begins. %s takes command." % player_faction)
	_setup_cpu_competitors()


func advance_time(days: int) -> Array[Dictionary]:
	days_elapsed += days
	var cpu_results: Array[Dictionary] = []
	for competitor: CPUCompetitor in competitors:
		cpu_results.append(competitor.advance_days(days, rng))
	return cpu_results


func get_player_readiness_percent() -> float:
	return moonbase.get_readiness_percent()


func is_vehicle_allowed(vehicle_id: String) -> bool:
	return active_rules.is_vehicle_allowed(vehicle_id)


# Completing the moonbase is checked first, so a challenge run that finishes on
# its last allowed launch still wins.
func check_for_winner() -> Dictionary:
	if moonbase.is_complete():
		game_over = true
		player_won = true
		winner_name = player_faction
		return _get_match_result()

	var rule_loss_reason := _get_rule_loss_reason()
	if not rule_loss_reason.is_empty():
		game_over = true
		player_won = false
		loss_reason = rule_loss_reason
		return _get_match_result()

	for competitor: CPUCompetitor in competitors:
		if competitor.is_complete():
			game_over = true
			player_won = false
			winner_name = competitor.display_name
			loss_reason = LOSS_REASON_RIVAL_FINISHED
			return _get_match_result()

	return _get_match_result()


func get_summary() -> Dictionary:
	return {
		"player_faction": player_faction,
		"difficulty": active_difficulty,
		"days_elapsed": days_elapsed,
		"launches_attempted": launches_attempted,
		"successful_launches": successful_launches,
		"failed_launches": failed_launches,
		"player_readiness_percent": get_player_readiness_percent(),
		"remaining_requirements": moonbase.remaining_requirements.duplicate(true),
		"competitors": _get_competitor_summaries(),
		"news": news.messages.duplicate(),
		"game_over": game_over,
		"player_won": player_won,
		"winner_name": winner_name,
		"loss_reason": loss_reason,
		"useful_delivered": moonbase.useful_delivered,
		"wasted_materials": moonbase.wasted_materials,
		"total_requirements": moonbase.initial_requirements.duplicate(true),
		"cpu_enabled": active_rules.cpu_enabled,
		"allowed_vehicles": active_rules.allowed_vehicles.duplicate(),
		"max_failures": active_rules.max_failures,
		"max_launches": active_rules.max_launches,
	}


func _get_match_result() -> Dictionary:
	return {
		"game_over": game_over,
		"has_winner": game_over and not winner_name.is_empty(),
		"winner_name": winner_name,
		"player_won": player_won,
		"loss_reason": loss_reason,
	}


func _get_rule_loss_reason() -> String:
	if active_rules.max_failures != MatchRules.UNLIMITED and failed_launches > active_rules.max_failures:
		return LOSS_REASON_FAILURE_LIMIT
	if active_rules.max_launches != MatchRules.UNLIMITED and launches_attempted >= active_rules.max_launches:
		return LOSS_REASON_LAUNCH_LIMIT
	return ""


func _setup_cpu_competitors() -> void:
	competitors.clear()
	if not active_rules.cpu_enabled:
		return
	var cpu_profile := active_difficulty
	if not active_rules.cpu_profile_override.is_empty():
		cpu_profile = active_rules.cpu_profile_override
	for faction_id: String in GameDataScript.get_cpu_faction_ids(player_faction):
		var competitor: CPUCompetitor = CPUCompetitorScript.new()
		competitor.setup(faction_id, GameDataScript.FACTIONS[faction_id], cpu_profile)
		competitors.append(competitor)


func _get_competitor_summaries() -> Array[Dictionary]:
	var summaries: Array[Dictionary] = []
	for competitor: CPUCompetitor in competitors:
		summaries.append({
			"display_name": competitor.display_name,
			"progress_percent": competitor.progress_percent,
		})
	return summaries

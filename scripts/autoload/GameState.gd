extends Node
class_name GameState

const GameDataScript := preload("res://scripts/data/GameData.gd")
const MoonbaseScript := preload("res://scripts/moonbase/Moonbase.gd")
const CPUCompetitorScript := preload("res://scripts/cpu/CPUCompetitor.gd")
const NewsManagerScript := preload("res://scripts/news/NewsManager.gd")

var player_faction := "USA"
var days_elapsed := 0
var launches_attempted := 0
var successful_launches := 0
var failed_launches := 0
var game_over := false
var player_won := false
var winner_name := ""

var moonbase: Moonbase
var competitors: Array[CPUCompetitor] = []
var news: NewsManager
var rng := RandomNumberGenerator.new()


func _ready() -> void:
	start_new_match(player_faction)


func start_new_match(selected_faction: String = "USA") -> void:
	player_faction = selected_faction
	days_elapsed = 0
	launches_attempted = 0
	successful_launches = 0
	failed_launches = 0
	game_over = false
	player_won = false
	winner_name = ""

	rng.randomize()
	moonbase = MoonbaseScript.new()
	moonbase.setup(GameDataScript.MOONBASE_REQUIREMENTS)
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


func check_for_winner() -> Dictionary:
	if moonbase.is_complete():
		game_over = true
		player_won = true
		winner_name = player_faction
		return {"has_winner": true, "winner_name": winner_name, "player_won": true}

	for competitor: CPUCompetitor in competitors:
		if competitor.is_complete():
			game_over = true
			player_won = false
			winner_name = competitor.display_name
			return {"has_winner": true, "winner_name": winner_name, "player_won": false}

	return {"has_winner": false, "winner_name": "", "player_won": false}


func get_summary() -> Dictionary:
	return {
		"player_faction": player_faction,
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
		"useful_delivered": moonbase.useful_delivered,
		"wasted_materials": moonbase.wasted_materials,
	}


func _setup_cpu_competitors() -> void:
	competitors.clear()
	for faction_id: String in GameDataScript.get_cpu_faction_ids(player_faction):
		var competitor: CPUCompetitor = CPUCompetitorScript.new()
		competitor.setup(faction_id, GameDataScript.FACTIONS[faction_id])
		competitors.append(competitor)


func _get_competitor_summaries() -> Array[Dictionary]:
	var summaries: Array[Dictionary] = []
	for competitor: CPUCompetitor in competitors:
		summaries.append({
			"display_name": competitor.display_name,
			"progress_percent": competitor.progress_percent,
		})
	return summaries

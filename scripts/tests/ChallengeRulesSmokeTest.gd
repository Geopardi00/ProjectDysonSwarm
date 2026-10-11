extends SceneTree

const GameDataScript := preload("res://scripts/data/GameData.gd")
const GameStateScript := preload("res://scripts/autoload/GameState.gd")
const LaunchManagerScript := preload("res://scripts/launch/LaunchManager.gd")
const MatchRulesScript := preload("res://scripts/rules/MatchRules.gd")
const CargoAssignmentScript := preload("res://scripts/cargo/CargoAssignment.gd")

var game_state: GameState
var launch_manager: LaunchManager


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	game_state = GameStateScript.new()
	launch_manager = LaunchManagerScript.new()
	launch_manager.setup(game_state)

	# Default rules must behave exactly like a standard match.
	game_state.start_new_match("USA", "hard")
	if game_state.competitors.size() != 2:
		return _fail("Default rules did not create two CPU competitors.")
	if game_state.moonbase.initial_requirements != GameDataScript.MOONBASE_REQUIREMENTS:
		return _fail("Default rules did not use the standard moonbase requirements.")
	if game_state.get_summary()["total_requirements"] != GameDataScript.MOONBASE_REQUIREMENTS:
		return _fail("The match summary did not report the standard requirement totals.")
	if GameDataScript.get_piece_set("big_rocket", "standard") != GameDataScript.get_piece_set("big_rocket"):
		return _fail("The standard piece set id did not resolve to the standard pieces.")
	if GameDataScript.get_piece_set("space_shuttle", "missing_set") != GameDataScript.get_piece_set("space_shuttle"):
		return _fail("An unknown piece set did not fall back to the standard pieces.")
	var assignment = CargoAssignmentScript.new()
	assignment.setup("big_rocket", game_state.active_rules.piece_set_id)
	if assignment.available_pieces.size() != 20:
		return _fail("Big Rocket assignment no longer starts with 20 standard pieces.")
	launch_manager.resolve_launch("big_rocket", GameDataScript.get_test_manifest("failed_rocket"))
	if game_state.game_over:
		return _fail("A crashed launch ended a standard match.")

	# One Life: the first crash loses.
	var one_life = MatchRulesScript.new()
	one_life.max_failures = 0
	game_state.start_new_match("USA", "medium", one_life)
	launch_manager.resolve_launch("space_shuttle", GameDataScript.get_test_manifest("shuttle_success"))
	if game_state.game_over:
		return _fail("A successful launch ended a One Life run.")
	var crash_result := launch_manager.resolve_launch("big_rocket", GameDataScript.get_test_manifest("failed_rocket"))
	var crash_outcome: Dictionary = crash_result["winner_result"]
	if (
		not bool(crash_outcome["game_over"])
		or bool(crash_outcome["has_winner"])
		or bool(crash_outcome["player_won"])
		or String(crash_outcome["loss_reason"]) != GameStateScript.LOSS_REASON_FAILURE_LIMIT
	):
		return _fail("A crash did not end a One Life run with the failure-limit reason.")
	if not String(game_state.news.messages[0]).begins_with("Challenge failed"):
		return _fail("A One Life loss did not post a challenge-failed news message.")

	# Launch Limit: running out of launches loses.
	var launch_limit = MatchRulesScript.new()
	launch_limit.max_launches = 2
	launch_limit.cpu_enabled = false
	game_state.start_new_match("USA", "medium", launch_limit)
	launch_manager.resolve_launch("space_shuttle", GameDataScript.get_test_manifest("shuttle_success"))
	if game_state.game_over or game_state.active_rules.get_launches_remaining(game_state.launches_attempted) != 1:
		return _fail("Launch Limit ended early or miscounted the launches left.")
	launch_manager.resolve_launch("space_shuttle", GameDataScript.get_test_manifest("shuttle_success"))
	if not game_state.game_over or game_state.loss_reason != GameStateScript.LOSS_REASON_LAUNCH_LIMIT:
		return _fail("Running out of launches did not end the run with the launch-limit reason.")

	# Finishing the moonbase on the last allowed launch still wins.
	var final_launch = MatchRulesScript.new()
	final_launch.max_launches = 1
	final_launch.max_failures = 0
	final_launch.moonbase_requirements = {"copper": 20}
	game_state.start_new_match("USA", "medium", final_launch)
	launch_manager.resolve_launch("spinlaunch", GameDataScript.get_test_manifest("spinlaunch"))
	if not game_state.player_won or not game_state.loss_reason.is_empty():
		return _fail("Completing the moonbase on the final allowed launch did not win.")
	if game_state.moonbase.initial_requirements != {"copper": 20}:
		return _fail("Custom moonbase requirements were not used.")

	# Time Trial: no CPU rivals, and time still advances.
	var time_trial = MatchRulesScript.new()
	time_trial.cpu_enabled = false
	game_state.start_new_match("USA", "hard", time_trial)
	if not game_state.competitors.is_empty():
		return _fail("Time Trial rules still created CPU competitors.")
	launch_manager.resolve_launch("big_rocket", GameDataScript.get_test_manifest("big_rocket_success"))
	if game_state.days_elapsed != 30 or game_state.game_over:
		return _fail("A Time Trial launch did not simply advance the day count.")

	# Fixed Vehicle: other vehicles are refused without spending a launch.
	var fixed_vehicle = MatchRulesScript.new()
	fixed_vehicle.allowed_vehicles.append("space_shuttle")
	game_state.start_new_match("USA", "medium", fixed_vehicle)
	var refused := launch_manager.resolve_launch("big_rocket", GameDataScript.get_test_manifest("big_rocket_success"))
	if String(refused.get("reason", "")) != "vehicle_not_allowed" or game_state.launches_attempted != 0:
		return _fail("Fixed Vehicle rules did not refuse a disallowed vehicle.")
	if not game_state.is_vehicle_allowed("space_shuttle"):
		return _fail("Fixed Vehicle rules refused the allowed vehicle.")

	# Extreme Rivals: a challenge-only CPU profile that Options cannot select.
	var extreme = MatchRulesScript.new()
	extreme.cpu_profile_override = "extreme"
	game_state.start_new_match("USA", "easy", extreme)
	if game_state.competitors[0].difficulty != "extreme" or game_state.active_difficulty != "easy":
		return _fail("The Extreme Rivals override did not reach the CPU competitors.")
	if GameDataScript.normalize_difficulty("extreme") != GameDataScript.DEFAULT_DIFFICULTY:
		return _fail("Extreme became selectable as a normal difficulty.")

	# A fixed seed makes the whole match repeatable.
	var seeded = MatchRulesScript.new()
	seeded.rng_seed = 4242
	var first_run := _run_seeded_match(seeded)
	var second_run := _run_seeded_match(seeded)
	if first_run != second_run:
		return _fail("Two matches with the same seed played out differently.")

	game_state.free()
	print("Challenge rules smoke test passed.")
	quit(0)


func _run_seeded_match(rules: MatchRules) -> Array:
	game_state.start_new_match("USA", "medium", rules)
	var trace: Array = []
	for _step: int in range(6):
		for result: Dictionary in game_state.advance_time(20):
			trace.append([result["vehicle_id"], result["crashed"], result["progress_percent"]])
	return trace


func _fail(message: String) -> void:
	push_error(message)
	if game_state != null:
		game_state.free()
	quit(1)

extends SceneTree

const GameDataScript := preload("res://scripts/data/GameData.gd")
const CPUCompetitorScript := preload("res://scripts/cpu/CPUCompetitor.gd")
const GameStateScript := preload("res://scripts/autoload/GameState.gd")


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	if GameDataScript.normalize_difficulty("unknown") != "hard":
		return _fail("Unknown difficulty did not fall back to Hard.")

	var hard_cpu = CPUCompetitorScript.new()
	hard_cpu.setup("China", GameDataScript.FACTIONS["China"], "hard")
	var hard_rng := RandomNumberGenerator.new()
	hard_rng.seed = 12345
	var hard_result: Dictionary = hard_cpu.advance_days(30, hard_rng)
	if (
		String(hard_result.get("vehicle_id", "")) != "big_rocket"
		or not is_equal_approx(float(hard_result.get("base_gain", 0.0)), 28.5)
		or not is_equal_approx(float(hard_result.get("effective_crash_chance", 0.0)), 0.10)
	):
		return _fail("Hard difficulty no longer matches the original CPU behavior.")

	var alternate_vehicle_counts := {}
	for difficulty: String in ["easy", "medium", "hard"]:
		var cpu = CPUCompetitorScript.new()
		cpu.setup("China", GameDataScript.FACTIONS["China"], difficulty)
		var rng := RandomNumberGenerator.new()
		rng.seed = 24680
		var counts := {"big_rocket": 0, "space_shuttle": 0, "spinlaunch": 0}
		for _sample: int in range(400):
			var result: Dictionary = cpu.advance_days(1, rng)
			var vehicle_id := String(result.get("vehicle_id", ""))
			counts[vehicle_id] = int(counts.get(vehicle_id, 0)) + 1
		alternate_vehicle_counts[difficulty] = int(counts["space_shuttle"]) + int(counts["spinlaunch"])
		if difficulty != "hard" and (int(counts["space_shuttle"]) == 0 or int(counts["spinlaunch"]) == 0):
			return _fail("%s difficulty did not use both smaller CPU vehicles." % difficulty.capitalize())

	if not (
		int(alternate_vehicle_counts["easy"]) > int(alternate_vehicle_counts["medium"])
		and int(alternate_vehicle_counts["medium"]) > int(alternate_vehicle_counts["hard"])
	):
		return _fail("Smaller CPU vehicle usage did not increase toward Easy.")

	var expected_crash_chances := {"easy": 0.20, "medium": 0.15, "hard": 0.10}
	for difficulty: String in expected_crash_chances:
		var cpu = CPUCompetitorScript.new()
		cpu.setup("China", GameDataScript.FACTIONS["China"], difficulty)
		var rng := RandomNumberGenerator.new()
		rng.seed = 13579
		var result: Dictionary = cpu.advance_days(1, rng)
		if not is_equal_approx(
			float(result.get("effective_crash_chance", 0.0)),
			float(expected_crash_chances[difficulty])
		):
			return _fail("%s difficulty used the wrong CPU crash chance." % difficulty.capitalize())

	var game_state = GameStateScript.new()
	game_state.start_new_match("USA", "hard")
	if game_state.active_difficulty != "hard" or game_state.competitors[0].difficulty != "hard":
		return _fail("Game state did not capture Hard for the active match.")
	game_state.start_new_match("USA", "easy")
	if game_state.active_difficulty != "easy" or game_state.competitors[0].difficulty != "easy":
		return _fail("A new match did not adopt the newly selected difficulty.")
	game_state.free()

	print("CPU difficulty smoke test passed.")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)

extends SceneTree

const MainScene := preload("res://scenes/main/Main.tscn")
const ChallengeDataScript := preload("res://scripts/data/ChallengeData.gd")
const ChallengeRecordsScript := preload("res://scripts/records/ChallengeRecords.gd")
const GameDataScript := preload("res://scripts/data/GameData.gd")
const TEST_SETTINGS_PATH := "user://challenges_screen_smoke_settings.cfg"
const TEST_RECORDS_PATH := "user://challenges_screen_smoke_records.cfg"


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	_remove_test_files()
	var data_error := _check_challenge_data()
	if not data_error.is_empty():
		return _fail(null, data_error)
	var records_error := _check_records()
	if not records_error.is_empty():
		return _fail(null, records_error)

	var main := MainScene.instantiate()
	main.settings_file_path = TEST_SETTINGS_PATH
	main.challenge_records_path = TEST_RECORDS_PATH
	main.demo_mode = false
	main.play_intro_on_boot = false
	main.opening_glitch_duration = 0.0
	root.add_child(main)
	main.set_anchors_preset(Control.PRESET_TOP_LEFT)
	main.size = Vector2(1920.0, 1080.0)
	await process_frame
	await process_frame

	# Building a challenge on the Challenges screen.
	main._show_challenges_screen()
	await process_frame
	var screen := main.active_screen as ChallengesScreen
	if screen == null:
		return _fail(main, "The Challenges button flow did not open ChallengesScreen.")
	if not screen.continue_button.disabled:
		return _fail(main, "Continue was enabled with no modifiers selected.")
	screen.set_modifier_enabled(ChallengeDataScript.TIME_TRIAL, true)
	var extreme_toggle := screen.modifier_rows[ChallengeDataScript.EXTREME_RIVALS]["toggle"] as CheckBox
	if not extreme_toggle.disabled:
		return _fail(main, "Extreme Rivals stayed available alongside Time Trial.")
	screen.set_modifier_enabled(ChallengeDataScript.ONE_LIFE, true)
	if screen.continue_button.disabled or not screen.record_label.text.contains("not cleared yet"):
		return _fail(main, "A built challenge did not enable Continue or show its record line.")

	main._on_challenge_continue_requested(screen.get_selection())
	await create_timer(0.3).timeout
	if main.active_screen == null or main.active_screen.get_node_or_null("ChallengeLabel") == null:
		return _fail(main, "Faction select did not show the active challenge.")

	# Playing a Time Trial + One Life match through to a recorded win.
	main.selected_faction = "USA"
	main._on_start_match_pressed()
	await process_frame
	if not main.game_state.competitors.is_empty() or main.game_state.active_rules.max_failures != 0:
		return _fail(main, "The challenge rules did not reach the match.")
	var strategy := main.active_screen as StrategyScreen
	if strategy == null or not strategy.competitors_label.text.contains("Time Trial"):
		return _fail(main, "The strategy screen did not show the Time Trial readout.")
	if not strategy.launches_label.text.contains("Crashes allowed: 0"):
		return _fail(main, "The strategy screen did not show the crash allowance.")

	main.game_state.moonbase.remaining_requirements = {"copper": 20}
	main._on_launch_requested("spinlaunch", GameDataScript.get_test_manifest("spinlaunch"))
	main._on_result_continue_pressed()
	await process_frame
	var title := main.active_screen.get_node("GameOverPanel/GameOverText/Title") as Label
	var details := main.active_screen.get_node("GameOverPanel/GameOverText/Details") as Label
	if title.text != "Time Trial Complete" or not details.text.contains("New record"):
		return _fail(main, "A Time Trial win did not show its title and new record.")
	var saved_records = ChallengeRecordsScript.new()
	saved_records.load_records(TEST_RECORDS_PATH)
	if int(saved_records.get_record(ChallengeDataScript.get_record_key(main.challenge_selection)).get("best_days", 0)) != 5:
		return _fail(main, "The Time Trial win was not saved as a record.")

	# A challenge loss explains why the run ended.
	main._on_play_again_pressed()
	main._on_launch_requested("big_rocket", GameDataScript.get_test_manifest("failed_rocket"))
	main._on_result_continue_pressed()
	await process_frame
	title = main.active_screen.get_node("GameOverPanel/GameOverText/Title") as Label
	details = main.active_screen.get_node("GameOverPanel/GameOverText/Details") as Label
	if title.text != "Challenge Failed" or not details.text.contains("no failed launches"):
		return _fail(main, "A One Life crash did not show the challenge-failed explanation.")

	# Fixed Vehicle disables the other vehicle cards.
	main.challenge_selection = {ChallengeDataScript.FIXED_VEHICLE: "space_shuttle"}
	main._start_match()
	await process_frame
	strategy = main.active_screen as StrategyScreen
	if not strategy.vehicle_cards["big_rocket"]["button"].disabled or strategy.vehicle_cards["space_shuttle"]["button"].disabled:
		return _fail(main, "Fixed Vehicle did not disable only the other vehicle cards.")

	# Start on the opening menu always plays a normal match.
	main._start_normal_match_flow()
	await create_timer(0.3).timeout
	main._on_start_match_pressed()
	await process_frame
	if main.game_state.competitors.size() != 2 or main.game_state.active_rules.max_failures != -1:
		return _fail(main, "Start after a challenge did not play a normal match.")

	# Demo builds show the screen, locked.
	main.demo_mode = true
	main._show_challenges_screen()
	await process_frame
	screen = main.active_screen as ChallengesScreen
	var one_life_toggle := screen.modifier_rows[ChallengeDataScript.ONE_LIFE]["toggle"] as CheckBox
	if not screen.locked_label.visible or not screen.continue_button.disabled or not one_life_toggle.disabled:
		return _fail(main, "The demo Challenges screen was not locked.")
	main._on_challenge_continue_requested({ChallengeDataScript.ONE_LIFE: ""})
	if main._get_active_match_rules() != null:
		return _fail(main, "A demo build could start a challenge.")

	_cleanup(main)
	print("Challenges screen smoke test passed.")
	quit(0)


func _check_challenge_data() -> String:
	var clean := ChallengeDataScript.sanitize({
		ChallengeDataScript.TIME_TRIAL: "",
		ChallengeDataScript.EXTREME_RIVALS: "",
		"unknown": "",
	})
	if clean.keys() != [ChallengeDataScript.TIME_TRIAL]:
		return "Sanitize kept a conflicting or unknown modifier."
	clean = ChallengeDataScript.sanitize({ChallengeDataScript.FIXED_VEHICLE: "spinlaunch"})
	if String(clean[ChallengeDataScript.FIXED_VEHICLE]) != "big_rocket":
		return "SpinLaunch-only was allowed without Time Trial."
	var with_trial := {ChallengeDataScript.TIME_TRIAL: "", ChallengeDataScript.FIXED_VEHICLE: "spinlaunch"}
	if String(ChallengeDataScript.sanitize(with_trial)[ChallengeDataScript.FIXED_VEHICLE]) != "spinlaunch":
		return "SpinLaunch-only was refused alongside Time Trial."
	var key_a := ChallengeDataScript.get_record_key({ChallengeDataScript.ONE_LIFE: "", ChallengeDataScript.LAUNCH_LIMIT: "4"})
	var key_b := ChallengeDataScript.get_record_key({ChallengeDataScript.LAUNCH_LIMIT: "4", ChallengeDataScript.ONE_LIFE: ""})
	if key_a != key_b or key_a != "launch_limit=4|one_life":
		return "Record keys depended on modifier order."
	var rules := ChallengeDataScript.build_rules({
		ChallengeDataScript.LAUNCH_LIMIT: "8",
		ChallengeDataScript.EXTREME_RIVALS: "",
		ChallengeDataScript.FIXED_VEHICLE: "space_shuttle",
	})
	if rules.max_launches != 8 or rules.cpu_profile_override != "extreme" or not (rules.allowed_vehicles.size() == 1 and rules.allowed_vehicles[0] == "space_shuttle"):
		return "Built rules did not match the selected modifiers."
	return ""


func _check_records() -> String:
	var records = ChallengeRecordsScript.new()
	records.load_records(TEST_RECORDS_PATH)
	if bool(records.submit_result("key", false, 90, 3)["is_new_best"]) or records.has_record("key"):
		return "A lost run was saved as a record."
	if not bool(records.submit_result("key", true, 120, 5)["is_new_best"]):
		return "A first win was not a new record."
	if bool(records.submit_result("key", true, 130, 4)["is_new_best"]):
		return "A slower win replaced the record."
	if not bool(records.submit_result("key", true, 120, 4)["is_new_best"]):
		return "Fewer launches did not break a day-count tie."
	var reloaded = ChallengeRecordsScript.new()
	reloaded.load_records(TEST_RECORDS_PATH)
	var record: Dictionary = reloaded.get_record("key")
	if int(record.get("best_days", 0)) != 120 or int(record.get("best_launches", 0)) != 4:
		return "Records did not survive a reload."
	_remove_test_files()
	return ""


func _cleanup(main) -> void:
	if main != null and is_instance_valid(main):
		main.settings_loaded = false
		main.queue_free()
	_remove_test_files()


func _remove_test_files() -> void:
	for path: String in [TEST_SETTINGS_PATH, TEST_RECORDS_PATH]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _fail(main, message: String) -> void:
	_cleanup(main)
	push_error(message)
	quit(1)

extends SceneTree

const MainScene := preload("res://scenes/main/Main.tscn")


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var main := MainScene.instantiate()
	root.add_child(main)
	await process_frame

	main._on_start_match_pressed()
	await process_frame

	if not main.active_screen is StrategyScreen:
		_fail("Start match did not open the strategy screen.")
		return

	var strategy_screen := main.active_screen as StrategyScreen
	if strategy_screen.day_label == null:
		_fail("Strategy screen day label was not ready.")
		return
	if strategy_screen.day_label.text != "Day 0":
		_fail("Strategy screen did not populate the day label.")
		return

	print("Strategy screen smoke test passed.")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)

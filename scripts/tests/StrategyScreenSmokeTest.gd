extends SceneTree

const MainScene := preload("res://scenes/main/Main.tscn")


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var main := MainScene.instantiate()
	root.add_child(main)
	await process_frame

	main._on_faction_button_pressed("USA")
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
	if not strategy_screen.has_node("Layout/Panels/NewsPanel"):
		_fail("Strategy screen is missing the right-side news panel.")
		return
	if strategy_screen.news_label.get_parent().get_parent().get_parent().get_parent().name != "NewsPanel":
		_fail("Strategy screen news feed is not inside the right-side news panel.")
		return
	var status_panel := strategy_screen.get_node("Layout/Panels/StatusPanel") as Control
	var vehicle_panel := strategy_screen.get_node("Layout/Panels/VehiclePanel") as Control
	var news_panel := strategy_screen.get_node("Layout/Panels/NewsPanel") as Control
	if not status_panel.position.x < vehicle_panel.position.x or not vehicle_panel.position.x < news_panel.position.x:
		_fail("Strategy screen panels are not ordered status, vehicles, then news.")
		return
	var target_viewport_width := float(ProjectSettings.get_setting("display/window/size/viewport_width", 1920))
	if news_panel.position.x + news_panel.size.x > target_viewport_width:
		_fail("Strategy screen right-side news panel extends beyond the target viewport.")
		return
	strategy_screen.panel_spacing = 24.0
	strategy_screen.status_text_x = 26.0
	strategy_screen.news_text_y = 90.0
	strategy_screen.big_rocket_panel_x = 7.0
	strategy_screen.big_rocket_stats_y = 9.0
	await process_frame
	var panels := strategy_screen.get_node("Layout/Panels") as HBoxContainer
	var status_margin := strategy_screen.get_node("Layout/Panels/StatusPanel/Margin") as MarginContainer
	var news_margin := strategy_screen.get_node("Layout/Panels/NewsPanel/Margin") as MarginContainer
	var big_rocket_art := strategy_screen.get_node("Layout/Panels/VehiclePanel/BigRocketCard/PanelArt") as Control
	var big_rocket_title := strategy_screen.get_node("Layout/Panels/VehiclePanel/BigRocketCard/Margin/Content/BigRocketTitle") as Control
	var big_rocket_stats := strategy_screen.get_node("Layout/Panels/VehiclePanel/BigRocketCard/Margin/Content/BigRocketStats") as Control
	if panels.get_theme_constant("separation") != 24:
		_fail("Strategy screen panel spacing slider did not update the layout.")
		return
	if status_margin.offset_left != strategy_screen.status_panel_x + 26.0 or news_margin.offset_top != strategy_screen.news_panel_y + 90.0:
		_fail("Strategy screen text position sliders did not update the layout.")
		return
	if (
		big_rocket_art.offset_left != strategy_screen.big_rocket_panel_x
		or big_rocket_title.position.y != 5.0 + strategy_screen.big_rocket_title_y
		or big_rocket_stats.position.y != 379.0
	):
		_fail("Strategy screen vehicle panel and text sliders did not update independently.")
		return

	print("Strategy screen smoke test passed.")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)

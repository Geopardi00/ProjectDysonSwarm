extends SceneTree

const DemoCompleteScene := preload("res://scenes/ui/DemoCompleteScreen.tscn")


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var screen = DemoCompleteScene.instantiate()
	root.add_child(screen)
	screen.set_anchors_preset(Control.PRESET_TOP_LEFT)
	screen.size = Vector2(1920.0, 1080.0)
	await process_frame

	var panel_art := screen.get_node_or_null("PanelCenter/Panel/PanelArt") as TextureRect
	if panel_art == null or panel_art.texture == null:
		return _fail(screen, "Demo completion screen did not display its panel art.")
	var title := screen.get_node_or_null("PanelCenter/Panel/ContentMargin/Content/Title") as Label
	var message := screen.get_node_or_null("PanelCenter/Panel/ContentMargin/Content/Message") as Label
	var steam_placeholder := screen.get_node_or_null("PanelCenter/Panel/ContentMargin/Content/SteamPlaceholder") as Label
	var replay_button := screen.get_node_or_null("PanelCenter/Panel/ContentMargin/Content/ReplayButton") as Button
	var exit_button := screen.get_node_or_null("PanelCenter/Panel/ContentMargin/Content/ExitButton") as Button
	if title == null or not title.text.contains("THANK YOU"):
		return _fail(screen, "Demo completion screen did not include its thank-you title.")
	if message == null or not message.text.to_lower().contains("wishlist"):
		return _fail(screen, "Demo completion screen did not include the wishlist message.")
	if steam_placeholder == null or not steam_placeholder.text.contains("PLACEHOLDER"):
		return _fail(screen, "Demo completion screen did not include the Steam link placeholder.")
	if replay_button == null or replay_button.text != "PLAY DEMO AGAIN":
		return _fail(screen, "Demo completion screen did not include its replay button.")
	if exit_button == null or exit_button.text != "EXIT GAME":
		return _fail(screen, "Demo completion screen did not include its exit button.")

	var emitted := {"replay": false, "exit": false}
	screen.replay_requested.connect(func(): emitted["replay"] = true)
	screen.exit_requested.connect(func(): emitted["exit"] = true)
	replay_button.pressed.emit()
	exit_button.pressed.emit()
	if not bool(emitted["replay"]) or not bool(emitted["exit"]):
		return _fail(screen, "Demo completion buttons did not emit their navigation signals.")

	screen.queue_free()
	await process_frame
	print("Demo completion screen smoke test passed.")
	quit(0)


func _fail(screen, message: String) -> void:
	if screen != null and is_instance_valid(screen):
		screen.queue_free()
	push_error(message)
	quit(1)

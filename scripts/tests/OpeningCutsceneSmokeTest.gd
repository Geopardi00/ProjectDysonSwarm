extends SceneTree

const MainScene := preload("res://scenes/main/Main.tscn")


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var main := MainScene.instantiate()
	root.add_child(main)
	main.set_anchors_preset(Control.PRESET_TOP_LEFT)
	main.size = Vector2(1920, 1080)
	await process_frame
	await process_frame
	main.get_node("EditorOpeningPreview").visible = true
	await process_frame

	var runtime_layout := main.active_screen.get_node_or_null("Layout") as VBoxContainer
	var preview_layout := main.get_node_or_null("EditorOpeningPreview/Layout") as VBoxContainer
	if runtime_layout == null or preview_layout == null:
		_fail("Opening screen layouts were not available for comparison.")
		return
	var runtime_logo := runtime_layout.get_node_or_null("TitleLogo") as TextureRect
	var preview_logo := preview_layout.get_node_or_null("TitleLogo") as TextureRect
	if runtime_logo == null or preview_logo == null:
		_fail("Opening title logos were not available for comparison.")
		return
	if not is_equal_approx(runtime_logo.global_position.y, preview_logo.global_position.y):
		_fail("Runtime opening title position did not match the editor preview: %.1f vs %.1f." % [
			runtime_logo.global_position.y,
			preview_logo.global_position.y,
		])
		return

	main.cutscene_explosion_time = 0.0
	main._show_opening_cutscene()
	await process_frame
	await process_frame

	if main.opening_cutscene_layer == null:
		_fail("Opening cutscene layer was not created.")
		return
	if main.opening_cutscene_player == null or not main.opening_cutscene_player.is_playing():
		_fail("Opening cutscene video did not start playing.")
		return
	if main.cutscene_explosion_player == null or not main.cutscene_explosion_player.is_playing():
		_fail("Cutscene explosion sound did not play at its configured time.")
		return
	if main.music_player != null and main.music_player.stream_paused:
		_fail("Background music was paused during the cutscene.")
		return

	main._finish_opening_cutscene()
	await process_frame

	if main.opening_cutscene_layer != null or main.opening_cutscene_player != null:
		_fail("Opening cutscene was not cleaned up after finishing.")
		return
	if main.active_screen == null:
		_fail("Faction selection did not open after the cutscene.")
		return
	if main.corner_logo == null or not main.corner_logo.visible:
		_fail("Faction selection did not restore the corner logo.")
		return

	print("Opening cutscene smoke test passed.")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)

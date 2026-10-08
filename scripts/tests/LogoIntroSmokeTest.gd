extends SceneTree

const MainScene := preload("res://scenes/main/Main.tscn")
const TEST_SETTINGS_PATH := "user://logo_intro_smoke_settings.cfg"


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	# Natural playthrough: the intro finishes by itself and leaves the menu usable.
	var main = _spawn_main()
	await process_frame
	var intro: LogoAssemblyIntro = main.logo_intro
	var title_logo := main.active_screen.get_node("Layout/TitleLogo") as TextureRect
	var button_stack := main.active_screen.get_node("Layout/ButtonStack") as Control
	if intro == null:
		return _fail(main, "Boot did not start the logo intro.")
	if title_logo.modulate.a != 0.0 or button_stack.modulate.a != 0.0:
		return _fail(main, "Title logo or menu was visible before the intro assembled it.")
	await process_frame
	await process_frame
	if not intro.is_playing() or intro.get_child_count() < 20:
		return _fail(main, "Logo intro did not build its flying pieces.")
	var timeout := 8.0
	while is_instance_valid(intro) and timeout > 0.0:
		await create_timer(0.1).timeout
		timeout -= 0.1
	if is_instance_valid(intro) or main.logo_intro != null:
		return _fail(main, "Logo intro did not finish on its own.")
	if title_logo.modulate.a != 1.0 or button_stack.modulate.a != 1.0 or title_logo.material != null:
		return _fail(main, "Logo intro did not restore the title logo and menu.")
	_cleanup(main)
	await process_frame

	# Skipping with any key jumps straight to the finished title screen.
	main = _spawn_main()
	await process_frame
	await process_frame
	await process_frame
	intro = main.logo_intro
	title_logo = main.active_screen.get_node("Layout/TitleLogo") as TextureRect
	button_stack = main.active_screen.get_node("Layout/ButtonStack") as Control
	var key := InputEventKey.new()
	key.keycode = KEY_SPACE
	key.pressed = true
	root.push_input(key)
	await process_frame
	if is_instance_valid(intro) and not intro.is_queued_for_deletion():
		return _fail(main, "A key press did not skip the logo intro.")
	if title_logo.modulate.a != 1.0 or button_stack.modulate.a != 1.0:
		return _fail(main, "Skipping the intro did not reveal the title screen.")
	var backlight := title_logo.get_node_or_null("Backlight") as Control
	if backlight == null or backlight.modulate.a != 1.0:
		return _fail(main, "Skipping the intro did not show the title backlight.")
	_cleanup(main)
	await process_frame

	# Leaving the opening screen mid-intro cancels it cleanly.
	main = _spawn_main()
	await process_frame
	await process_frame
	await process_frame
	intro = main.logo_intro
	main._show_faction_select()
	await process_frame
	if is_instance_valid(intro) or main.logo_intro != null:
		return _fail(main, "Changing screens did not cancel the logo intro.")
	_cleanup(main)

	print("Logo intro smoke test passed.")
	quit(0)


func _spawn_main():
	var main := MainScene.instantiate()
	main.settings_file_path = TEST_SETTINGS_PATH
	root.add_child(main)
	main.set_anchors_preset(Control.PRESET_TOP_LEFT)
	main.size = Vector2(1920.0, 1080.0)
	return main


func _fail(main, message: String) -> void:
	_cleanup(main)
	push_error(message)
	quit(1)


func _cleanup(main) -> void:
	if main != null and is_instance_valid(main):
		main.settings_loaded = false
		main.queue_free()
	if FileAccess.file_exists(TEST_SETTINGS_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SETTINGS_PATH))

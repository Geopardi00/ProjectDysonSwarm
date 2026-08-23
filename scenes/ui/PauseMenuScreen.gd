extends Control
class_name PauseMenuScreen

signal resume_requested
signal options_requested
signal instructions_requested
signal quit_to_main_requested
signal exit_game_requested

@onready var panel_center: CenterContainer = %PanelCenter


func _ready() -> void:
	%ResumeButton.pressed.connect(resume_requested.emit)
	%OptionsButton.pressed.connect(options_requested.emit)
	%HowToPlayButton.pressed.connect(instructions_requested.emit)
	%QuitToMainButton.pressed.connect(quit_to_main_requested.emit)
	%ExitGameButton.pressed.connect(exit_game_requested.emit)
	UiAssets.apply_text_outline(self)
	UiAssets.apply_semibold_font(%PauseTitle)
	%ResumeButton.grab_focus()


func set_menu_visible(is_visible: bool) -> void:
	panel_center.visible = is_visible
	if is_visible and is_inside_tree():
		%ResumeButton.grab_focus()

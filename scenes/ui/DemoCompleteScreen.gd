extends Control
class_name DemoCompleteScreen

signal replay_requested
signal exit_requested


func _ready() -> void:
	%ReplayButton.pressed.connect(replay_requested.emit)
	%ExitButton.pressed.connect(exit_requested.emit)
	UiAssets.apply_text_outline(self)
	UiAssets.apply_semibold_font(%Title)
	%ReplayButton.grab_focus()

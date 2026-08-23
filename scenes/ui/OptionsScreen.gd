extends Control
class_name OptionsScreen

signal back_requested
signal master_volume_changed(percent: float)
signal music_volume_changed(percent: float)
signal sfx_volume_changed(percent: float)
signal brightness_changed(percent: float)

@onready var panel_art: TextureRect = %PanelArt
@onready var background: TextureRect = $Background
@onready var options_page: VBoxContainer = %OptionsPage
@onready var instructions_page: VBoxContainer = %InstructionsPage
@onready var volume_slider: HSlider = %VolumeSlider
@onready var volume_value_label: Label = %VolumeValueLabel
@onready var music_volume_slider: HSlider = %MusicVolumeSlider
@onready var music_volume_value_label: Label = %MusicVolumeValueLabel
@onready var sfx_volume_slider: HSlider = %SfxVolumeSlider
@onready var sfx_volume_value_label: Label = %SfxVolumeValueLabel
@onready var brightness_slider: HSlider = %BrightnessSlider
@onready var brightness_value_label: Label = %BrightnessValueLabel
@onready var instructions_label: Label = %InstructionsLabel


func _ready() -> void:
	volume_slider.value_changed.connect(_on_volume_value_changed)
	music_volume_slider.value_changed.connect(_on_music_volume_value_changed)
	sfx_volume_slider.value_changed.connect(_on_sfx_volume_value_changed)
	brightness_slider.value_changed.connect(_on_brightness_value_changed)
	%HowToPlayButton.pressed.connect(show_instructions_page)
	%OptionsBackButton.pressed.connect(back_requested.emit)
	%InstructionsBackButton.pressed.connect(show_options_page)
	show_options_page()
	UiAssets.apply_text_outline(self)
	UiAssets.apply_semibold_font(%OptionsTitle)
	UiAssets.apply_semibold_font(%InstructionsTitle)


func setup(
	volume_percent: float,
	music_percent: float,
	sfx_percent: float,
	brightness_percent: float,
	show_background: bool = true
) -> void:
	background.visible = show_background
	volume_slider.set_value_no_signal(clampf(volume_percent, volume_slider.min_value, volume_slider.max_value))
	music_volume_slider.set_value_no_signal(clampf(music_percent, music_volume_slider.min_value, music_volume_slider.max_value))
	sfx_volume_slider.set_value_no_signal(clampf(sfx_percent, sfx_volume_slider.min_value, sfx_volume_slider.max_value))
	brightness_slider.set_value_no_signal(clampf(brightness_percent, brightness_slider.min_value, brightness_slider.max_value))
	_update_value_labels()


func show_options_page() -> void:
	options_page.visible = true
	instructions_page.visible = false
	if is_inside_tree():
		volume_slider.grab_focus()


func show_instructions_page() -> void:
	options_page.visible = false
	instructions_page.visible = true
	if is_inside_tree():
		%InstructionsBackButton.grab_focus()


func is_showing_instructions() -> bool:
	return instructions_page.visible


func _on_volume_value_changed(value: float) -> void:
	_update_value_labels()
	master_volume_changed.emit(value)


func _on_music_volume_value_changed(value: float) -> void:
	_update_value_labels()
	music_volume_changed.emit(value)


func _on_sfx_volume_value_changed(value: float) -> void:
	_update_value_labels()
	sfx_volume_changed.emit(value)


func _on_brightness_value_changed(value: float) -> void:
	_update_value_labels()
	brightness_changed.emit(value)


func _update_value_labels() -> void:
	volume_value_label.text = "%d%%" % int(round(volume_slider.value))
	music_volume_value_label.text = "%d%%" % int(round(music_volume_slider.value))
	sfx_volume_value_label.text = "%d%%" % int(round(sfx_volume_slider.value))
	brightness_value_label.text = "%d%%" % int(round(brightness_slider.value))


func _unhandled_input(event: InputEvent) -> void:
	if not visible or not event.is_action_pressed("ui_cancel"):
		return
	get_viewport().set_input_as_handled()
	if is_showing_instructions():
		show_options_page()
	else:
		back_requested.emit()

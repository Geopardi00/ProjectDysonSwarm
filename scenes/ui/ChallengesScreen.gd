extends Control
class_name ChallengesScreen

signal back_requested
signal continue_requested(selection: Dictionary)

const ChallengeDataScript := preload("res://scripts/data/ChallengeData.gd")
const UI_TWEEN_SKIP_META := &"skip_global_button_tween"
const DESCRIPTION_COLOR := Color(0.82, 0.86, 0.94, 1.0)
const BLOCKED_COLOR := Color(1.0, 0.62, 0.42, 1.0)
const HIGHLIGHT_COLOR := Color(1.0, 0.78, 0.32, 1.0)
const CHECKBOX_SIZE := 22
const CHECKBOX_BORDER_COLOR := Color(0.86, 0.89, 0.96, 1.0)
const CHECKBOX_DISABLED_BORDER_COLOR := Color(0.42, 0.45, 0.52, 1.0)
const CHECKBOX_FILL_COLOR := Color("#F08A34")
const CHECKBOX_BACKGROUND_COLOR := Color(0.04, 0.06, 0.09, 0.9)

# The default theme's unchecked box is nearly invisible on the dark panel, so
# draw clear outlined boxes instead.
var checkbox_icons: Dictionary = {}

@export_range(10, 40, 1) var modifier_name_font_size := 22
@export_range(10, 40, 1) var modifier_description_font_size := 16

var button_navigation_delay := 0.08
var button_navigation_pending := false
var selection: Dictionary = {}
var records: ChallengeRecords
var locked := false
var modifier_rows: Dictionary = {}

@onready var modifier_list: VBoxContainer = %ModifierList
@onready var record_label: Label = %RecordLabel
@onready var locked_label: Label = %LockedLabel
@onready var back_button: Button = %BackButton
@onready var continue_button: Button = %ContinueButton


func _ready() -> void:
	back_button.pressed.connect(_queue_button_navigation.bind(back_requested.emit))
	continue_button.pressed.connect(_queue_button_navigation.bind(_on_continue_pressed))
	_build_modifier_rows()
	UiAssets.apply_text_outline(self)
	UiAssets.apply_semibold_font(%Title)
	record_label.add_theme_color_override("font_color", HIGHLIGHT_COLOR)
	locked_label.add_theme_color_override("font_color", HIGHLIGHT_COLOR)
	_refresh()


func setup(initial_selection: Dictionary, challenge_records: ChallengeRecords, is_locked: bool) -> void:
	selection = {} if is_locked else ChallengeDataScript.sanitize(initial_selection)
	records = challenge_records
	locked = is_locked
	if is_node_ready():
		_refresh()


func get_selection() -> Dictionary:
	return selection.duplicate()


func set_modifier_enabled(modifier_id: String, enabled: bool) -> void:
	if locked:
		return
	if enabled:
		if not ChallengeDataScript.get_blocking_reason(selection, modifier_id).is_empty():
			return
		selection[modifier_id] = ChallengeDataScript.get_default_option(modifier_id)
	else:
		selection.erase(modifier_id)
	selection = ChallengeDataScript.sanitize(selection)
	_refresh()


func set_modifier_option(modifier_id: String, option_id: String) -> void:
	if locked or not selection.has(modifier_id):
		return
	if not ChallengeDataScript.get_option_blocking_reason(selection, modifier_id, option_id).is_empty():
		_refresh()
		return
	selection[modifier_id] = option_id
	_refresh()


func _build_modifier_rows() -> void:
	for child: Node in modifier_list.get_children():
		child.queue_free()
	modifier_rows.clear()
	for modifier: Dictionary in ChallengeDataScript.MODIFIERS:
		var modifier_id := String(modifier["id"])
		var row := VBoxContainer.new()
		row.name = "%sRow" % modifier_id.to_pascal_case()
		row.add_theme_constant_override("separation", 0)

		var header := HBoxContainer.new()
		header.add_theme_constant_override("separation", 12)
		row.add_child(header)

		var toggle := CheckBox.new()
		toggle.name = "Toggle"
		toggle.text = String(modifier["name"])
		toggle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		toggle.add_theme_font_size_override("font_size", modifier_name_font_size)
		toggle.set_meta(UI_TWEEN_SKIP_META, true)
		_apply_checkbox_icons(toggle)
		toggle.toggled.connect(func(pressed: bool) -> void: set_modifier_enabled(modifier_id, pressed))
		header.add_child(toggle)

		var option_button: OptionButton = null
		if not modifier["options"].is_empty():
			option_button = OptionButton.new()
			option_button.name = "Option"
			option_button.custom_minimum_size = Vector2(190, 34)
			option_button.set_meta(UI_TWEEN_SKIP_META, true)
			for option: Dictionary in modifier["options"]:
				option_button.add_item(String(option["label"]))
			option_button.item_selected.connect(func(index: int) -> void:
				set_modifier_option(modifier_id, String(modifier["options"][index]["id"]))
			)
			header.add_child(option_button)

		var description := Label.new()
		description.name = "Description"
		description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		description.add_theme_font_size_override("font_size", modifier_description_font_size)
		description.add_theme_color_override("font_color", DESCRIPTION_COLOR)
		row.add_child(description)

		modifier_list.add_child(row)
		modifier_rows[modifier_id] = {
			"toggle": toggle,
			"option": option_button,
			"description": description,
		}


func _apply_checkbox_icons(toggle: CheckBox) -> void:
	if checkbox_icons.is_empty():
		checkbox_icons = {
			"unchecked": _build_checkbox_icon(false, CHECKBOX_BORDER_COLOR),
			"checked": _build_checkbox_icon(true, CHECKBOX_BORDER_COLOR),
			"unchecked_disabled": _build_checkbox_icon(false, CHECKBOX_DISABLED_BORDER_COLOR),
			"checked_disabled": _build_checkbox_icon(true, CHECKBOX_DISABLED_BORDER_COLOR),
		}
	for icon_name: String in checkbox_icons.keys():
		toggle.add_theme_icon_override(icon_name, checkbox_icons[icon_name])


static func _build_checkbox_icon(checked: bool, border_color: Color) -> ImageTexture:
	var image := Image.create_empty(CHECKBOX_SIZE, CHECKBOX_SIZE, false, Image.FORMAT_RGBA8)
	image.fill(border_color)
	image.fill_rect(Rect2i(2, 2, CHECKBOX_SIZE - 4, CHECKBOX_SIZE - 4), CHECKBOX_BACKGROUND_COLOR)
	if checked:
		var fill := CHECKBOX_FILL_COLOR if border_color == CHECKBOX_BORDER_COLOR else CHECKBOX_FILL_COLOR.darkened(0.5)
		image.fill_rect(Rect2i(5, 5, CHECKBOX_SIZE - 10, CHECKBOX_SIZE - 10), fill)
	return ImageTexture.create_from_image(image)


func _refresh() -> void:
	for modifier: Dictionary in ChallengeDataScript.MODIFIERS:
		var modifier_id := String(modifier["id"])
		var row: Dictionary = modifier_rows.get(modifier_id, {})
		if row.is_empty():
			continue
		var is_selected := selection.has(modifier_id)
		var blocking_reason := "" if is_selected else ChallengeDataScript.get_blocking_reason(selection, modifier_id)

		var toggle := row["toggle"] as CheckBox
		toggle.set_pressed_no_signal(is_selected)
		toggle.disabled = locked or not blocking_reason.is_empty()

		var option_button := row["option"] as OptionButton
		if option_button != null:
			var option_id := String(selection.get(modifier_id, ChallengeDataScript.get_default_option(modifier_id)))
			var options: Array = modifier["options"]
			for index: int in range(options.size()):
				var option: Dictionary = options[index]
				if String(option["id"]) == option_id:
					option_button.select(index)
				var option_reason := ChallengeDataScript.get_option_blocking_reason(selection, modifier_id, String(option["id"]))
				option_button.set_item_disabled(index, not option_reason.is_empty())
				option_button.set_item_text(
					index,
					String(option["label"]) if option_reason.is_empty() else "%s (%s)" % [option["label"], option_reason.to_lower()]
				)
			option_button.disabled = locked or not is_selected

		var description := row["description"] as Label
		if blocking_reason.is_empty():
			description.text = String(modifier["description"])
			description.add_theme_color_override("font_color", DESCRIPTION_COLOR)
		else:
			description.text = "%s. %s" % [blocking_reason, modifier["description"]]
			description.add_theme_color_override("font_color", BLOCKED_COLOR)

	locked_label.visible = locked
	record_label.visible = not locked
	record_label.text = _format_record_text()
	continue_button.disabled = locked or selection.is_empty()


func _format_record_text() -> String:
	if selection.is_empty():
		return "Switch on one or more modifiers to build a challenge."
	var summary := ChallengeDataScript.describe(selection)
	if records == null:
		return summary
	var record := records.get_record(ChallengeDataScript.get_record_key(selection))
	return "%s\nBest: %s" % [summary, ChallengeRecords.format_record(record)]


func _on_continue_pressed() -> void:
	if locked or selection.is_empty():
		return
	continue_requested.emit(selection.duplicate())


func _queue_button_navigation(action: Callable) -> void:
	if button_navigation_pending:
		return
	button_navigation_pending = true
	if button_navigation_delay > 0.0:
		await get_tree().create_timer(button_navigation_delay).timeout
	if is_inside_tree() and action.is_valid():
		action.call()
	button_navigation_pending = false


func _unhandled_input(event: InputEvent) -> void:
	if not visible or not event.is_action_pressed("ui_cancel"):
		return
	get_viewport().set_input_as_handled()
	back_requested.emit()

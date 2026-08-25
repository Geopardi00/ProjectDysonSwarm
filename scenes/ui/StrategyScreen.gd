@tool
extends Control
class_name StrategyScreen

signal vehicle_selected(vehicle_id: String)
signal reset_requested
signal debug_add_news_requested
signal debug_force_player_win_requested
signal debug_force_cpu_win_requested
signal debug_launch_failure_requested
signal debug_launch_success_requested

const GameDataScript := preload("res://scripts/data/GameData.gd")
const UiAssetsScript := preload("res://scripts/data/UiAssets.gd")

@export_category("Strategy Panel Layout")
@export_range(0.0, 180.0, 1.0, "suffix:px") var panel_top_position := 76.0:
	set(value):
		panel_top_position = value
		_queue_layout_preview()
@export_range(0.0, 100.0, 1.0, "suffix:px") var panel_spacing := 20.0:
	set(value):
		panel_spacing = value
		_queue_layout_preview()
@export_range(340.0, 500.0, 1.0, "suffix:px") var side_panel_width := 430.0:
	set(value):
		side_panel_width = value
		_queue_layout_preview()

@export_category("Status and News Font Sizes")
@export_range(10, 64, 1, "suffix:px") var day_font_size := 40:
	set(value):
		day_font_size = value
		_queue_layout_preview()
@export_range(10, 48, 1, "suffix:px") var faction_font_size := 24:
	set(value):
		faction_font_size = value
		_queue_layout_preview()
@export_range(10, 40, 1, "suffix:px") var status_info_font_size := 16:
	set(value):
		status_info_font_size = value
		_queue_layout_preview()
@export_range(10, 40, 1, "suffix:px") var readiness_percent_font_size := 16:
	set(value):
		readiness_percent_font_size = value
		_queue_layout_preview()
@export_range(10, 48, 1, "suffix:px") var news_title_font_size := 20:
	set(value):
		news_title_font_size = value
		_queue_layout_preview()
@export_range(10, 40, 1, "suffix:px") var news_body_font_size := 16:
	set(value):
		news_body_font_size = value
		_queue_layout_preview()

@export_category("Status Panel")
@export_range(-150.0, 150.0, 1.0, "suffix:px") var status_panel_x := 0.0:
	set(value):
		status_panel_x = value
		_queue_layout_preview()
@export_range(-150.0, 150.0, 1.0, "suffix:px") var status_panel_y := 0.0:
	set(value):
		status_panel_y = value
		_queue_layout_preview()
@export_range(-40.0, 100.0, 1.0, "suffix:px") var status_text_x := 22.0:
	set(value):
		status_text_x = value
		_queue_layout_preview()
@export_range(0.0, 180.0, 1.0, "suffix:px") var status_text_y := 82.0:
	set(value):
		status_text_y = value
		_queue_layout_preview()
@export_range(20.0, 120.0, 1.0, "suffix:px") var status_content_right_inset := 40.0:
	set(value):
		status_content_right_inset = value
		_queue_layout_preview()
@export_range(20.0, 160.0, 1.0, "suffix:px") var status_content_bottom_inset := 70.0:
	set(value):
		status_content_bottom_inset = value
		_queue_layout_preview()

@export_category("Big Rocket Panel")
@export_range(-150.0, 150.0, 1.0, "suffix:px") var big_rocket_panel_x := 0.0:
	set(value):
		big_rocket_panel_x = value
		_queue_layout_preview()
@export_range(-150.0, 150.0, 1.0, "suffix:px") var big_rocket_panel_y := 0.0:
	set(value):
		big_rocket_panel_y = value
		_queue_layout_preview()
@export_range(-100.0, 100.0, 1.0, "suffix:px") var big_rocket_title_x := 0.0:
	set(value):
		big_rocket_title_x = value
		_queue_layout_preview()
@export_range(-100.0, 100.0, 1.0, "suffix:px") var big_rocket_title_y := 4.0:
	set(value):
		big_rocket_title_y = value
		_queue_layout_preview()
@export_range(-100.0, 100.0, 1.0, "suffix:px") var big_rocket_stats_x := 0.0:
	set(value):
		big_rocket_stats_x = value
		_queue_layout_preview()
@export_range(-100.0, 100.0, 1.0, "suffix:px") var big_rocket_stats_y := 4.0:
	set(value):
		big_rocket_stats_y = value
		_queue_layout_preview()
@export_range(-100.0, 100.0, 1.0, "suffix:px") var big_rocket_button_x := 0.0:
	set(value):
		big_rocket_button_x = value
		_queue_layout_preview()
@export_range(-100.0, 100.0, 1.0, "suffix:px") var big_rocket_button_y := 4.0:
	set(value):
		big_rocket_button_y = value
		_queue_layout_preview()

@export_category("Space Shuttle Panel")
@export_range(-150.0, 150.0, 1.0, "suffix:px") var shuttle_panel_x := 0.0:
	set(value):
		shuttle_panel_x = value
		_queue_layout_preview()
@export_range(-150.0, 150.0, 1.0, "suffix:px") var shuttle_panel_y := 0.0:
	set(value):
		shuttle_panel_y = value
		_queue_layout_preview()
@export_range(-100.0, 100.0, 1.0, "suffix:px") var shuttle_title_x := 0.0:
	set(value):
		shuttle_title_x = value
		_queue_layout_preview()
@export_range(-100.0, 100.0, 1.0, "suffix:px") var shuttle_title_y := 4.0:
	set(value):
		shuttle_title_y = value
		_queue_layout_preview()
@export_range(-100.0, 100.0, 1.0, "suffix:px") var shuttle_stats_x := 0.0:
	set(value):
		shuttle_stats_x = value
		_queue_layout_preview()
@export_range(-100.0, 100.0, 1.0, "suffix:px") var shuttle_stats_y := 4.0:
	set(value):
		shuttle_stats_y = value
		_queue_layout_preview()
@export_range(-100.0, 100.0, 1.0, "suffix:px") var shuttle_button_x := 0.0:
	set(value):
		shuttle_button_x = value
		_queue_layout_preview()
@export_range(-100.0, 100.0, 1.0, "suffix:px") var shuttle_button_y := 4.0:
	set(value):
		shuttle_button_y = value
		_queue_layout_preview()

@export_category("SpinLaunch Panel")
@export_range(-150.0, 150.0, 1.0, "suffix:px") var spinlaunch_panel_x := 0.0:
	set(value):
		spinlaunch_panel_x = value
		_queue_layout_preview()
@export_range(-150.0, 150.0, 1.0, "suffix:px") var spinlaunch_panel_y := 0.0:
	set(value):
		spinlaunch_panel_y = value
		_queue_layout_preview()
@export_range(-100.0, 100.0, 1.0, "suffix:px") var spinlaunch_title_x := 0.0:
	set(value):
		spinlaunch_title_x = value
		_queue_layout_preview()
@export_range(-100.0, 100.0, 1.0, "suffix:px") var spinlaunch_title_y := 4.0:
	set(value):
		spinlaunch_title_y = value
		_queue_layout_preview()
@export_range(-100.0, 100.0, 1.0, "suffix:px") var spinlaunch_stats_x := 0.0:
	set(value):
		spinlaunch_stats_x = value
		_queue_layout_preview()
@export_range(-100.0, 100.0, 1.0, "suffix:px") var spinlaunch_stats_y := 4.0:
	set(value):
		spinlaunch_stats_y = value
		_queue_layout_preview()
@export_range(-100.0, 100.0, 1.0, "suffix:px") var spinlaunch_button_x := 0.0:
	set(value):
		spinlaunch_button_x = value
		_queue_layout_preview()
@export_range(-100.0, 100.0, 1.0, "suffix:px") var spinlaunch_button_y := 4.0:
	set(value):
		spinlaunch_button_y = value
		_queue_layout_preview()

@export_category("News Panel")
@export_range(-150.0, 150.0, 1.0, "suffix:px") var news_panel_x := 0.0:
	set(value):
		news_panel_x = value
		_queue_layout_preview()
@export_range(-150.0, 150.0, 1.0, "suffix:px") var news_panel_y := 0.0:
	set(value):
		news_panel_y = value
		_queue_layout_preview()
@export_range(-40.0, 100.0, 1.0, "suffix:px") var news_text_x := 22.0:
	set(value):
		news_text_x = value
		_queue_layout_preview()
@export_range(0.0, 180.0, 1.0, "suffix:px") var news_text_y := 82.0:
	set(value):
		news_text_y = value
		_queue_layout_preview()
@export_range(20.0, 120.0, 1.0, "suffix:px") var news_feed_right_inset := 40.0:
	set(value):
		news_feed_right_inset = value
		_queue_layout_preview()
@export_range(20.0, 160.0, 1.0, "suffix:px") var news_feed_bottom_inset := 70.0:
	set(value):
		news_feed_bottom_inset = value
		_queue_layout_preview()

@onready var day_label: Label = %DayLabel
@onready var faction_label: Label = %FactionLabel
@onready var readiness_label: Label = %ReadinessLabel
@onready var readiness_bar: ProgressBar = %ReadinessBar
@onready var launches_label: Label = %LaunchesLabel
@onready var needs_label: Label = %NeedsLabel
@onready var competitors_label: Label = %CompetitorsLabel
@onready var news_label: Label = %NewsLabel
@onready var reset_button: Button = %ResetButton
@onready var debug_row: HBoxContainer = %DebugRow

var vehicle_cards: Dictionary = {}


func _ready() -> void:
	_apply_layout_settings()
	if Engine.is_editor_hint():
		return

	vehicle_cards = {
		"big_rocket": {
			"icon": %BigRocketIcon,
			"title": %BigRocketTitle,
			"payload": %BigRocketPayloadLabel,
			"fuel": %BigRocketFuelLabel,
			"days": %BigRocketDaysLabel,
			"grid": %BigRocketGridLabel,
			"button": %BigRocketButton,
		},
		"space_shuttle": {
			"icon": %ShuttleIcon,
			"title": %ShuttleTitle,
			"payload": %ShuttlePayloadLabel,
			"fuel": %ShuttleFuelLabel,
			"days": %ShuttleDaysLabel,
			"grid": %ShuttleGridLabel,
			"button": %ShuttleButton,
		},
		"spinlaunch": {
			"icon": %SpinLaunchIcon,
			"title": %SpinLaunchTitle,
			"payload": %SpinLaunchPayloadLabel,
			"fuel": %SpinLaunchFuelLabel,
			"days": %SpinLaunchDaysLabel,
			"grid": %SpinLaunchGridLabel,
			"button": %SpinLaunchButton,
		},
	}

	reset_button.pressed.connect(reset_requested.emit)
	%DebugAddNewsButton.pressed.connect(debug_add_news_requested.emit)
	%DebugForcePlayerWinButton.pressed.connect(debug_force_player_win_requested.emit)
	%DebugForceCpuWinButton.pressed.connect(debug_force_cpu_win_requested.emit)
	%DebugLaunchFailureButton.pressed.connect(debug_launch_failure_requested.emit)
	%DebugLaunchSuccessButton.pressed.connect(debug_launch_success_requested.emit)

	for vehicle_id: String in vehicle_cards.keys():
		var card: Dictionary = vehicle_cards[vehicle_id]
		var button := card["button"] as Button
		button.pressed.connect(vehicle_selected.emit.bind(vehicle_id))

	UiAssetsScript.apply_text_outline(self)


func _queue_layout_preview() -> void:
	if not is_inside_tree():
		return
	_apply_layout_settings()


func _apply_layout_settings() -> void:
	var top_spacer := get_node_or_null("Layout/PanelTopSpacer") as Control
	var panels := get_node_or_null("Layout/Panels") as HBoxContainer
	var status_panel := get_node_or_null("Layout/Panels/StatusPanel") as Control
	var news_panel := get_node_or_null("Layout/Panels/NewsPanel") as Control
	var status_art := get_node_or_null("Layout/Panels/StatusPanel/PanelArt") as Control
	var news_art := get_node_or_null("Layout/Panels/NewsPanel/PanelArt") as Control
	var status_margin := get_node_or_null("Layout/Panels/StatusPanel/Margin") as MarginContainer
	var news_margin := get_node_or_null("Layout/Panels/NewsPanel/Margin") as MarginContainer
	if top_spacer != null:
		top_spacer.custom_minimum_size.y = panel_top_position
	if panels != null:
		panels.add_theme_constant_override("separation", int(panel_spacing))
	if status_panel != null:
		status_panel.custom_minimum_size.x = side_panel_width
	if news_panel != null:
		news_panel.custom_minimum_size.x = side_panel_width
	_set_stretched_offsets(status_art, Vector4.ZERO, Vector2(status_panel_x, status_panel_y))
	_set_stretched_offsets(news_art, Vector4.ZERO, Vector2(news_panel_x, news_panel_y))
	_set_status_content_bounds(status_margin)
	_set_news_feed_bounds(news_margin)
	_apply_font_size("Layout/Panels/StatusPanel/Margin/StatusContent/DayLabel", day_font_size)
	_apply_font_size("Layout/Panels/StatusPanel/Margin/StatusContent/FactionLabel", faction_font_size)
	_apply_font_size("Layout/Panels/StatusPanel/Margin/StatusContent/ReadinessLabel", status_info_font_size)
	_apply_font_size("Layout/Panels/StatusPanel/Margin/StatusContent/LaunchesLabel", status_info_font_size)
	_apply_font_size("Layout/Panels/StatusPanel/Margin/StatusContent/NeedsLabel", status_info_font_size)
	_apply_font_size("Layout/Panels/StatusPanel/Margin/StatusContent/CompetitorsLabel", status_info_font_size)
	_apply_font_size("Layout/Panels/StatusPanel/Margin/StatusContent/ReadinessBar", readiness_percent_font_size)
	_apply_font_size("Layout/Panels/NewsPanel/Margin/NewsContent/NewsTitle", news_title_font_size)
	_apply_font_size("Layout/Panels/NewsPanel/Margin/NewsContent/NewsScroll/NewsLabel", news_body_font_size)
	_apply_vehicle_panel_layout(
		"BigRocketCard",
		Vector2(big_rocket_panel_x, big_rocket_panel_y),
		Vector2(big_rocket_title_x, big_rocket_title_y),
		Vector2(big_rocket_stats_x, big_rocket_stats_y),
		Vector2(big_rocket_button_x, big_rocket_button_y),
		"BigRocketTitle",
		"BigRocketStats",
		"BigRocketButton",
		Vector2(0.0, 5.0)
	)
	_apply_vehicle_panel_layout(
		"ShuttleCard",
		Vector2(shuttle_panel_x, shuttle_panel_y),
		Vector2(shuttle_title_x, shuttle_title_y),
		Vector2(shuttle_stats_x, shuttle_stats_y),
		Vector2(shuttle_button_x, shuttle_button_y),
		"ShuttleTitle",
		"ShuttleStats",
		"ShuttleButton",
		Vector2(0.0, 4.0)
	)
	_apply_vehicle_panel_layout(
		"SpinLaunchCard",
		Vector2(spinlaunch_panel_x, spinlaunch_panel_y),
		Vector2(spinlaunch_title_x, spinlaunch_title_y),
		Vector2(spinlaunch_stats_x, spinlaunch_stats_y),
		Vector2(spinlaunch_button_x, spinlaunch_button_y),
		"SpinLaunchTitle",
		"SpinLaunchStats",
		"SpinLaunchButton",
		Vector2(0.0, 5.0)
	)
	if panels != null:
		panels.queue_sort()
	var layout := get_node_or_null("Layout") as VBoxContainer
	if layout != null:
		layout.queue_sort()
	UiAssetsScript.apply_text_outline(self)
	queue_redraw()


func _set_text_margin_position(margin: MarginContainer, x: float, y: float) -> void:
	if margin == null:
		return
	margin.offset_left = x
	margin.offset_top = y
	margin.offset_right = x + 12.0
	margin.offset_bottom = y + 5.0


func _set_news_feed_bounds(margin: MarginContainer) -> void:
	if margin == null:
		return
	margin.scale = Vector2.ONE
	margin.offset_left = news_panel_x + news_text_x
	margin.offset_top = news_panel_y + news_text_y
	margin.offset_right = news_panel_x - news_feed_right_inset
	margin.offset_bottom = news_panel_y - news_feed_bottom_inset


func _set_status_content_bounds(margin: MarginContainer) -> void:
	if margin == null:
		return
	margin.scale = Vector2.ONE
	margin.offset_left = status_panel_x + status_text_x
	margin.offset_top = status_panel_y + status_text_y
	margin.offset_right = status_panel_x - status_content_right_inset
	margin.offset_bottom = status_panel_y - status_content_bottom_inset


func _apply_font_size(node_path: String, font_size: Variant) -> void:
	# Exported @tool properties initialize in declaration order. During a hot
	# reload, a setter can refresh the preview before later properties have a
	# value, so skip those temporary Nil values until initialization completes.
	if font_size == null:
		return
	var control := get_node_or_null(node_path) as Control
	if control == null:
		return
	var resolved_size := int(font_size)
	if control is Label:
		(control as Label).label_settings = null
	control.add_theme_font_size_override("font_size", resolved_size)


func _apply_vehicle_panel_layout(
	card_name: String,
	panel_offset: Vector2,
	title_offset: Vector2,
	stats_offset: Vector2,
	button_offset: Vector2,
	title_name: String,
	stats_name: String,
	button_name: String,
	title_base_position: Vector2
) -> void:
	var base_path := "Layout/Panels/VehiclePanel/%s" % card_name
	var panel_art := get_node_or_null("%s/PanelArt" % base_path) as Control
	var margin := get_node_or_null("%s/Margin" % base_path) as Control
	var content_path := "%s/Margin/Content" % base_path
	var title := get_node_or_null("%s/%s" % [content_path, title_name]) as Control
	var stats := get_node_or_null("%s/%s" % [content_path, stats_name]) as Control
	var button := get_node_or_null("%s/%s" % [content_path, button_name]) as Control
	_set_stretched_offsets(panel_art, Vector4.ZERO, panel_offset)
	_set_stretched_offsets(margin, Vector4(28.0, 28.0, -28.0, -28.0), panel_offset)
	if title != null:
		title.position = title_base_position + title_offset
	if stats != null:
		stats.position = Vector2(12.0, 370.0) + stats_offset
	if button != null:
		button.position = Vector2(32.0, 518.0) + button_offset


func _set_stretched_offsets(control: Control, base: Vector4, delta: Vector2) -> void:
	if control == null:
		return
	control.offset_left = base.x + delta.x
	control.offset_top = base.y + delta.y
	control.offset_right = base.z + delta.x
	control.offset_bottom = base.w + delta.y


func setup(summary: Dictionary, show_debug_actions: bool) -> void:
	day_label.text = "Day %d" % int(summary["days_elapsed"])
	faction_label.text = "Player faction: %s" % String(summary["player_faction"])
	readiness_label.text = "Moonbase readiness: %.1f%%" % float(summary["player_readiness_percent"])
	readiness_bar.max_value = 100.0
	readiness_bar.value = float(summary["player_readiness_percent"])
	launches_label.text = "Launches: %d  Success: %d  Failed: %d" % [
		int(summary["launches_attempted"]),
		int(summary["successful_launches"]),
		int(summary["failed_launches"]),
	]
	needs_label.text = _format_needs(summary["remaining_requirements"])
	competitors_label.text = _format_competitors(summary["competitors"])
	news_label.text = _format_news(summary["news"])
	debug_row.visible = show_debug_actions

	for vehicle_id: String in vehicle_cards.keys():
		_populate_vehicle_card(vehicle_id)

	UiAssetsScript.apply_text_outline(self)


func _populate_vehicle_card(vehicle_id: String) -> void:
	var vehicle := GameDataScript.get_vehicle(vehicle_id)
	var card: Dictionary = vehicle_cards[vehicle_id]

	var title := card["title"] as Label
	title.text = String(vehicle.get("display_name", vehicle_id))

	var icon := card["icon"] as TextureRect
	icon.texture = UiAssetsScript.get_vehicle_icon(vehicle_id)

	var payload_label := card["payload"] as Label
	payload_label.text = "Payload: %d" % int(vehicle.get("max_payload", 0))

	var fuel_label := card["fuel"] as Label
	fuel_label.text = "Fuel needed: %d" % int(vehicle.get("required_fuel", 0))

	var days_label := card["days"] as Label
	days_label.text = "Days to launch: %d" % int(vehicle.get("launch_days", 0))

	var grid_label := card["grid"] as Label
	grid_label.text = "Cargo Grid: %dx%d" % [
		int(vehicle.get("grid_width", 0)),
		int(vehicle.get("grid_height", 0)),
	]


func _format_needs(remaining_requirements: Dictionary) -> String:
	var lines: Array[String] = ["Remaining moonbase needs:"]
	for material: String in GameDataScript.CONSTRUCTION_MATERIALS:
		lines.append("- %s: %d / %d" % [
			_format_material_name(material),
			int(remaining_requirements.get(material, 0)),
			int(GameDataScript.MOONBASE_REQUIREMENTS.get(material, 0)),
		])
	return "\n".join(lines)


func _format_competitors(competitors: Array) -> String:
	var lines: Array[String] = ["CPU competitors:"]
	for competitor: Dictionary in competitors:
		lines.append("- %s: %.1f%%" % [
			String(competitor["display_name"]),
			float(competitor["progress_percent"]),
		])
	return "\n".join(lines)


func _format_news(messages: Array) -> String:
	var lines: Array[String] = []
	for message: String in messages:
		lines.append("- %s" % message)
	return "\n".join(lines)


func _format_material_name(material: String) -> String:
	return material.replace("_", " ").capitalize()

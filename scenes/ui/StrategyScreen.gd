extends Control
class_name StrategyScreen

signal vehicle_selected(vehicle_id: String)
signal reset_requested
signal debug_add_news_requested
signal debug_force_player_win_requested
signal debug_force_cpu_win_requested

const GameDataScript := preload("res://scripts/data/GameData.gd")
const UiAssetsScript := preload("res://scripts/data/UiAssets.gd")

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

	for vehicle_id: String in vehicle_cards.keys():
		var card: Dictionary = vehicle_cards[vehicle_id]
		var button := card["button"] as Button
		button.pressed.connect(vehicle_selected.emit.bind(vehicle_id))

	UiAssetsScript.apply_text_outline(self)


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

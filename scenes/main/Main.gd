extends Control

const GameDataScript := preload("res://scripts/data/GameData.gd")
const LaunchManagerScript := preload("res://scripts/launch/LaunchManager.gd")

@onready var strategy_root: MarginContainer = $RootMargin
@onready var cargo_loading_screen: Control = %CargoLoadingScreen
@onready var status_label: Label = %StatusLabel
@onready var needs_label: Label = %NeedsLabel
@onready var competitors_label: Label = %CompetitorsLabel
@onready var news_label: Label = %NewsLabel

var game_state: GameState
var launch_manager: LaunchManager
var current_packing_state: CargoPackingState


func _ready() -> void:
	game_state = GameState.new()
	add_child(game_state)

	launch_manager = LaunchManagerScript.new()
	launch_manager.setup(game_state)
	cargo_loading_screen.launch_requested.connect(_on_launch_requested)
	cargo_loading_screen.assignment_cancelled.connect(_on_assignment_cancelled)
	_refresh_view()


func test_big_rocket_success() -> Dictionary:
	return _launch_test_manifest("big_rocket", "big_rocket_success")


func test_shuttle_success() -> Dictionary:
	return _launch_test_manifest("space_shuttle", "shuttle_success")


func test_failed_rocket() -> Dictionary:
	return _launch_test_manifest("big_rocket", "failed_rocket")


func test_spinlaunch() -> Dictionary:
	return _launch_test_manifest("spinlaunch", "spinlaunch")


func _launch_test_manifest(vehicle_id: String, manifest_id: String) -> Dictionary:
	var result := launch_manager.resolve_launch(vehicle_id, GameDataScript.get_test_manifest(manifest_id))
	_refresh_view()
	return result


func _on_big_rocket_button_pressed() -> void:
	_open_assignment_screen("big_rocket")


func _on_shuttle_button_pressed() -> void:
	_open_assignment_screen("space_shuttle")


func _on_failed_rocket_button_pressed() -> void:
	test_failed_rocket()


func _on_spinlaunch_button_pressed() -> void:
	_open_assignment_screen("spinlaunch")


func _on_reset_button_pressed() -> void:
	game_state.start_new_match("USA")
	current_packing_state = null
	strategy_root.visible = true
	cargo_loading_screen.visible = false
	_refresh_view()


func _open_assignment_screen(vehicle_id: String) -> void:
	strategy_root.visible = false
	cargo_loading_screen.start_assignment(vehicle_id, game_state.moonbase.remaining_requirements.duplicate(true))


func _on_launch_requested(vehicle_id: String, manifest: Dictionary) -> void:
	launch_manager.resolve_launch(vehicle_id, manifest)
	current_packing_state = null
	cargo_loading_screen.visible = false
	strategy_root.visible = true
	_refresh_view()


func _on_assignment_cancelled() -> void:
	cargo_loading_screen.visible = false
	strategy_root.visible = true
	_refresh_view()


func _refresh_view() -> void:
	var summary := game_state.get_summary()
	status_label.text = _format_status(summary)
	needs_label.text = _format_needs(summary["remaining_requirements"])
	competitors_label.text = _format_competitors(summary["competitors"])
	news_label.text = _format_news(summary["news"])


func _format_status(summary: Dictionary) -> String:
	var lines: Array[String] = [
		"Project Dyson Swarm - Data Loop Prototype",
		"Faction: %s" % String(summary["player_faction"]),
		"Days elapsed: %d" % int(summary["days_elapsed"]),
		"Player readiness: %.1f%%" % float(summary["player_readiness_percent"]),
		"Launches: %d, Successes: %d, Failures: %d" % [
			int(summary["launches_attempted"]),
			int(summary["successful_launches"]),
			int(summary["failed_launches"]),
		],
		"Useful delivered: %d, Wasted: %d" % [
			int(summary["useful_delivered"]),
			int(summary["wasted_materials"]),
		],
	]

	if bool(summary["game_over"]):
		lines.append("GAME OVER: %s wins." % String(summary["winner_name"]))

	return "\n".join(lines)


func _format_needs(remaining_requirements: Dictionary) -> String:
	var lines: Array[String] = ["Moonbase material needs:"]
	for material: String in GameDataScript.CONSTRUCTION_MATERIALS:
		lines.append("- %s: %d" % [material, int(remaining_requirements.get(material, 0))])
	return "\n".join(lines)


func _format_competitors(competitors: Array) -> String:
	var lines: Array[String] = ["Competitors:"]
	for competitor: Dictionary in competitors:
		lines.append("- %s: %.1f%%" % [
			String(competitor["display_name"]),
			float(competitor["progress_percent"]),
		])
	return "\n".join(lines)


func _format_news(messages: Array) -> String:
	var lines: Array[String] = ["News feed:"]
	for message: String in messages:
		lines.append("- %s" % message)
	return "\n".join(lines)

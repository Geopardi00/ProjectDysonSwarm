extends RefCounted
class_name LaunchManager

const GameDataScript := preload("res://scripts/data/GameData.gd")

var game_state: GameState


func setup(state: GameState) -> void:
	game_state = state


func resolve_launch(vehicle_id: String, placed_manifest: Dictionary) -> Dictionary:
	if game_state == null:
		push_error("LaunchManager requires setup(game_state) before resolving launches.")
		return {}
	if game_state.game_over:
		return {"ignored": true, "reason": "game_over"}

	var vehicle := GameDataScript.get_vehicle(vehicle_id)
	if vehicle.is_empty():
		push_error("Unknown vehicle id: %s" % vehicle_id)
		return {}

	var vehicle_name := String(vehicle["display_name"])
	var required_fuel := int(vehicle["required_fuel"])
	var placed_fuel := int(placed_manifest.get(GameDataScript.MATERIAL_FUEL, 0))
	var launch_days := int(vehicle["launch_days"])
	var success := placed_fuel >= required_fuel
	var readiness_before := game_state.get_player_readiness_percent()
	var remaining_before := game_state.moonbase.remaining_requirements.duplicate(true)

	game_state.launches_attempted += 1

	var delivery_result := {}
	if success:
		game_state.successful_launches += 1
		delivery_result = game_state.moonbase.apply_delivery(placed_manifest)
		game_state.news.add_player_launch_success(vehicle_name, delivery_result, placed_manifest)
	else:
		game_state.failed_launches += 1
		game_state.news.add_player_launch_crash(vehicle_name, placed_fuel, required_fuel)
	var readiness_after := game_state.get_player_readiness_percent()

	var cpu_results := game_state.advance_time(launch_days)
	for cpu_result: Dictionary in cpu_results:
		game_state.news.add_cpu_update(cpu_result)

	var winner_result := game_state.check_for_winner()
	if bool(winner_result.get("has_winner", false)):
		game_state.news.add_game_over_winner(
			String(winner_result.get("winner_name", "")),
			bool(winner_result.get("player_won", false))
		)

	return {
		"vehicle_id": vehicle_id,
		"vehicle_name": vehicle_name,
		"success": success,
		"placed_fuel": placed_fuel,
		"required_fuel": required_fuel,
		"launch_days": launch_days,
		"placed_manifest": placed_manifest.duplicate(true),
		"readiness_before": readiness_before,
		"readiness_after": readiness_after,
		"remaining_before": remaining_before,
		"remaining_after": game_state.moonbase.remaining_requirements.duplicate(true),
		"delivery_result": delivery_result,
		"cpu_results": cpu_results,
		"winner_result": winner_result,
	}

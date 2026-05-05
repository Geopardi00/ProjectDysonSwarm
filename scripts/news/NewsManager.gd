extends RefCounted
class_name NewsManager

const MAX_MESSAGES := 12

var messages: Array[String] = []


func clear() -> void:
	messages.clear()


func add_message(message: String) -> void:
	messages.push_front(message)
	if messages.size() > MAX_MESSAGES:
		messages.resize(MAX_MESSAGES)


func add_player_launch_success(vehicle_name: String, delivery_result: Dictionary) -> void:
	add_message("Your %s reaches lunar transfer. Useful cargo delivered: %d. Wasted: %d." % [
		vehicle_name,
		int(delivery_result.get("used_total", 0)),
		int(delivery_result.get("wasted_total", 0)),
	])


func add_player_launch_crash(vehicle_name: String, placed_fuel: int, required_fuel: int) -> void:
	add_message("Your %s crashes after insufficient fuel loading: %d / %d. The mission board avoids eye contact." % [
		vehicle_name,
		placed_fuel,
		required_fuel,
	])


func add_cpu_update(result: Dictionary) -> void:
	var name := String(result.get("display_name", "CPU"))
	var progress := float(result.get("progress_percent", 0.0))
	var gain := float(result.get("actual_gain", 0.0))
	if bool(result.get("crashed", false)):
		add_message("%s suffers a launch anomaly. Progress still crawls forward to %.1f%%." % [name, progress])
	else:
		add_message("%s advances lunar construction by %.1f points, reaching %.1f%% readiness." % [name, gain, progress])


func add_game_over_winner(winner_name: String, player_won: bool) -> void:
	if player_won:
		add_message("Project Dyson Swarm successful. Your faction completed the moonbase first.")
	else:
		add_message("Space race lost. %s completed its moonbase before you." % winner_name)

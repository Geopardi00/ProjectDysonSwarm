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


func add_player_launch_success(vehicle_name: String, delivery_result: Dictionary, placed_manifest: Dictionary = {}) -> void:
	add_message("%s launch confirmed. Moonbase accepts %d construction units; %d units are surplus." % [
		vehicle_name,
		int(delivery_result.get("used_total", 0)),
		int(delivery_result.get("wasted_total", 0)),
	])
	var delivered_summary := _format_nonzero_materials(delivery_result.get("used", {}))
	if delivered_summary != "":
		add_message("Delivered: %s." % delivered_summary)
	var wasted_summary := _format_nonzero_materials(delivery_result.get("wasted", {}))
	if wasted_summary != "":
		add_message("Overdelivery warning: %s wasted at the moonbase." % wasted_summary)
	if int(placed_manifest.get("fuel", 0)) > 0:
		add_message("Fuel loaded and spent: %d." % int(placed_manifest.get("fuel", 0)))


func add_player_launch_crash(vehicle_name: String, placed_fuel: int, required_fuel: int) -> void:
	add_message("%s launch failure. Fuel loaded %d / %d; cargo lost and schedule still advances." % [
		vehicle_name,
		placed_fuel,
		required_fuel,
	])


func add_cpu_update(result: Dictionary) -> void:
	var name := String(result.get("display_name", "CPU"))
	var progress := float(result.get("progress_percent", 0.0))
	var gain := float(result.get("actual_gain", 0.0))
	if bool(result.get("crashed", false)):
		add_message("%s suffers a launch anomaly. Readiness still crawls to %.1f%%." % [name, progress])
	else:
		add_message("%s advances by %.1f points, reaching %.1f%% readiness." % [name, gain, progress])
	if float(result.get("previous_progress", 0.0)) < 50.0 and progress >= 50.0:
		add_message("%s passes 50%% moonbase readiness." % name)
	if float(result.get("previous_progress", 0.0)) < 75.0 and progress >= 75.0:
		add_message("%s passes 75%% moonbase readiness." % name)


func add_game_over_winner(winner_name: String, player_won: bool) -> void:
	if player_won:
		add_message("Project Dyson Swarm successful. Your faction completed the moonbase first.")
	else:
		add_message("Space race lost. %s completed its moonbase before you." % winner_name)


func _format_nonzero_materials(materials: Dictionary) -> String:
	var parts: Array[String] = []
	for material: String in materials.keys():
		var amount := int(materials.get(material, 0))
		if amount > 0:
			parts.append("%s %d" % [material.replace("_", " ").capitalize(), amount])
	return ", ".join(parts)

extends SceneTree

const GameDataScript := preload("res://scripts/data/GameData.gd")
const CargoAssignmentScript := preload("res://scripts/cargo/CargoAssignment.gd")


func _init() -> void:
	var passed := _run()
	quit(0 if passed else 1)


func _run() -> bool:
	var big_previews := GameDataScript.get_piece_set_preview_data("big_rocket")
	var shuttle_previews := GameDataScript.get_piece_set_preview_data("space_shuttle")
	var spinlaunch_previews := GameDataScript.get_piece_set_preview_data("spinlaunch")
	var shuttle_vehicle := GameDataScript.get_vehicle("space_shuttle")
	if int(shuttle_vehicle.get("launch_days", 0)) != 20:
		return _fail("Expected Space Shuttle launch_days to be 20.")
	if big_previews.size() != 10:
		return _fail("Expected 10 Big Rocket piece definitions.")
	if shuttle_previews.size() != 8:
		return _fail("Expected 8 Shuttle piece definitions.")
	if spinlaunch_previews.size() != 1:
		return _fail("Expected 1 SpinLaunch stub definition.")
	for preview: Dictionary in big_previews + shuttle_previews:
		if int(preview.get("cell_count", 0)) <= 1:
			return _fail("Found invalid 1-cell cargo piece.")
	var expected_big_ids := [
		"br_p_block_5",
		"br_corner_block",
		"br_tall_hook_5",
		"br_square_4",
		"br_offset_cross",
		"br_wide_hook",
		"br_double_hook",
		"br_c_block",
		"br_offset_step",
		"br_t_block",
	]
	var big_base_cell_total := 0
	for index in range(big_previews.size()):
		var preview: Dictionary = big_previews[index]
		if String(preview.get("id", "")) != expected_big_ids[index]:
			return _fail("Big Rocket shape id mismatch at index %d." % index)
		if int(preview.get("copies", 0)) != 2:
			return _fail("Big Rocket shape should have exactly 2 copies.")
		big_base_cell_total += int(preview.get("cell_count", 0))
	if big_base_cell_total != 50:
		return _fail("Big Rocket base shape set should total exactly 50 cells.")

	var big_assignment = CargoAssignmentScript.new()
	big_assignment.setup("big_rocket")
	if big_assignment.get_available_pieces().size() != 20:
		return _fail("Big Rocket should expose two copies of each base shape.")

	var assignment = CargoAssignmentScript.new()
	assignment.setup("space_shuttle")
	var available := assignment.get_available_pieces()
	if available.size() != 16:
		return _fail("Space Shuttle should expose two copies of each base shape.")
	if available[0].shape_id != available[1].shape_id:
		return _fail("Expected first two Shuttle pieces to be copies of the same shape.")

	if not assignment.assign_material(available[0].instance_id, "fuel"):
		return _fail("Could not assign fuel to first shuttle piece.")
	if not assignment.assign_material(available[1].instance_id, "copper"):
		return _fail("Could not assign copper to second shuttle piece.")
	if assignment.get_assigned_piece(available[0].instance_id).material == assignment.get_assigned_piece(available[1].instance_id).material:
		return _fail("Copies of the same shape did not keep independent material assignments.")

	var packing_state = assignment.create_packing_state()
	if assignment.assign_material(available[2].instance_id, "silicon"):
		return _fail("Assignment changed after locking.")

	if not packing_state.place_piece(available[0].instance_id, Vector2i(0, 0), 0):
		return _fail("Could not place first assigned piece.")
	if packing_state.place_piece(available[1].instance_id, Vector2i(0, 0), 0):
		return _fail("Collision placement was allowed.")
	if not packing_state.place_piece(available[1].instance_id, Vector2i(0, 2), 90):
		return _fail("Could not place second assigned piece after rotation.")

	var manifest := packing_state.get_manifest()
	if int(manifest.get("fuel", 0)) != available[0].get_payload_units():
		return _fail("Fuel manifest did not match placed fuel piece.")
	if int(manifest.get("copper", 0)) != available[1].get_payload_units():
		return _fail("Copper manifest did not match placed copper piece.")

	print("Cargo smoke test passed.")
	return true


func _fail(message: String) -> bool:
	push_error(message)
	return false

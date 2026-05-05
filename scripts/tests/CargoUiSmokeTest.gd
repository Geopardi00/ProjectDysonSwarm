extends SceneTree

const CargoLoadingScreenScene := preload("res://scenes/ui/CargoLoadingScreen.tscn")

var did_emit_launch := false


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var screen = CargoLoadingScreenScene.instantiate()
	root.add_child(screen)
	await process_frame

	screen.launch_requested.connect(_on_launch_requested)
	screen.start_assignment("big_rocket")
	var big_pieces: Array[CargoPiece] = screen.assignment.get_available_pieces()
	if big_pieces.size() != 20:
		_fail("Cargo screen did not expose 20 internal Big Rocket piece copies.")
		return
	if screen.piece_list.get_child_count() != 10:
		_fail("Cargo screen did not group Big Rocket pieces into 10 visible shape rows.")
		return
	if screen.assignment_grid_preview.grid_width != 5 or screen.assignment_grid_preview.grid_height != 10:
		_fail("Cargo screen did not show a 5x10 Big Rocket cargo hold preview.")
		return
	screen._on_assignment_group_pressed(big_pieces[0].shape_id)
	if screen.copy_buttons_row.get_child_count() != 2:
		_fail("Cargo screen did not show two copy buttons for selected Big Rocket shape.")
		return
	screen._on_assignment_copy_pressed(big_pieces[0].instance_id)
	screen._on_material_pressed("fuel")
	screen._on_assignment_copy_pressed(big_pieces[1].instance_id)
	screen._on_material_pressed("silicon")
	if screen.assignment.get_assigned_piece(big_pieces[0].instance_id).material != "fuel":
		_fail("First grouped copy did not keep its assigned material.")
		return
	if screen.assignment.get_assigned_piece(big_pieces[1].instance_id).material != "silicon":
		_fail("Second grouped copy did not keep its different assigned material.")
		return

	screen.start_assignment("space_shuttle", {"copper": 10})
	if not screen.moonbase_needs_label.text.contains("Copper: 10 / 140 remaining"):
		_fail("Cargo screen did not show passed moonbase remaining requirements.")
		return
	if screen.assignment_grid_preview.grid_width != 4 or screen.assignment_grid_preview.grid_height != 8:
		_fail("Cargo screen did not show a 4x8 Shuttle cargo hold preview.")
		return

	var pieces: Array[CargoPiece] = screen.assignment.get_available_pieces()
	if pieces.size() != 16:
		_fail("Cargo screen did not expose doubled Shuttle piece copies.")
		return

	if not screen.assignment.assign_material(pieces[0].instance_id, "fuel"):
		_fail("Could not assign fuel through cargo screen state.")
		return
	if not screen.assignment.assign_material(pieces[1].instance_id, "copper"):
		_fail("Could not assign copper through cargo screen state.")
		return
	screen._refresh()
	if not screen.moonbase_needs_label.text.contains("assigned: %d" % pieces[1].get_payload_units()):
		_fail("Cargo screen moonbase needs panel did not update assigned construction amount.")
		return
	if not screen.moonbase_needs_label.text.contains("Warning: assigned Copper exceeds remaining need"):
		_fail("Cargo screen did not warn about construction material overassignment.")
		return
	screen._on_reset_pressed()
	if not screen.moonbase_needs_label.text.contains("assigned: 0"):
		_fail("Cargo screen moonbase needs panel did not update after reset.")
		return

	if not screen.assignment.assign_material(pieces[0].instance_id, "fuel"):
		_fail("Could not reassign fuel after reset.")
		return
	if not screen.assignment.assign_material(pieces[1].instance_id, "copper"):
		_fail("Could not reassign copper after reset.")
		return

	screen._on_confirm_pressed()
	if screen.phase != screen.CargoPhase.PACKING:
		_fail("Cargo screen did not move to packing phase.")
		return

	screen.selected_piece_id = pieces[0].instance_id
	screen._rotate_selected_piece()
	if screen.selected_rotation != 90:
		_fail("Cargo screen did not rotate selected piece before placement.")
		return
	screen._on_grid_cell_clicked(Vector2i(0, 0), MOUSE_BUTTON_LEFT)
	if screen.packing_state.get_placed_payload() != pieces[0].get_payload_units():
		_fail("Cargo screen did not place selected piece.")
		return
	screen._on_grid_cell_clicked(Vector2i(0, 0), MOUSE_BUTTON_LEFT)
	if screen.selected_piece_id != pieces[0].instance_id:
		_fail("Cargo screen did not pick up placed piece for moving.")
		return
	if screen.packing_state.get_placed_payload() != 0:
		_fail("Picked up piece still counted as placed payload.")
		return
	screen._on_grid_cell_clicked(Vector2i(1, 0), MOUSE_BUTTON_LEFT)
	if screen.packing_state.get_placed_payload() != pieces[0].get_payload_units():
		_fail("Cargo screen did not move picked-up piece.")
		return

	screen._on_launch_pressed()
	if not did_emit_launch:
		_fail("Cargo screen did not emit launch request.")
		return

	print("Cargo UI smoke test passed.")
	quit(0)


func _on_launch_requested(_vehicle_id: String, _manifest: Dictionary) -> void:
	did_emit_launch = true


func _fail(message: String) -> void:
	push_error(message)
	quit(1)

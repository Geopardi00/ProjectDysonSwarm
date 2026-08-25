extends SceneTree

const CargoLoadingScreenScene := preload("res://scenes/ui/CargoLoadingScreen.tscn")
const LARGE_MATERIAL_ICON_PATHS := {
	"fuel": "res://assets/ui/materials/bigger/fuel_big.png",
	"carbon_metals": "res://assets/ui/materials/bigger/carbon_big.png",
	"silicon": "res://assets/ui/materials/bigger/silicon_big.png",
	"copper": "res://assets/ui/materials/bigger/copper_big.png",
	"electronics": "res://assets/ui/materials/bigger/electronics_big.png",
	"rare_metals": "res://assets/ui/materials/bigger/rare_materials_big.png",
	"propellant": "res://assets/ui/materials/bigger/propellant_big.png",
}
const TEST_MATERIALS: Array[String] = [
	"fuel",
	"carbon_metals",
	"silicon",
	"copper",
	"electronics",
	"rare_metals",
	"propellant",
]

var did_emit_launch := false
var did_emit_cancel := false


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var screen = CargoLoadingScreenScene.instantiate()
	root.add_child(screen)
	await process_frame
	var back_button := screen.get_node("BackButton") as Button
	if screen.get_child(screen.get_child_count() - 1) != back_button:
		_fail("Cargo Back button overlay did not have top GUI input priority.")
		return
	screen.assignment_cancelled.connect(func() -> void: did_emit_cancel = true)
	screen.button_navigation_delay = 0.05
	back_button.pressed.emit()
	if did_emit_cancel:
		_fail("Cargo Back button ignored its configured navigation delay.")
		return
	await create_timer(0.08).timeout
	if not did_emit_cancel:
		_fail("Cargo Back button did not emit assignment cancellation after its configured delay.")
		return
	screen.button_navigation_delay = 0.08
	var assignment_panel := screen.get_node("RootMargin/Layout/AssignmentPanel") as HBoxContainer
	var moonbase_panel := screen.get_node(
		"RootMargin/Layout/AssignmentPanel/AssignmentCenter/MoonbaseMaterialPanel"
	) as TextureRect
	var moonbase_label := screen.get_node(
		"RootMargin/Layout/AssignmentPanel/AssignmentCenter/MoonbaseNeedsLabel"
	) as Label
	if moonbase_panel.texture == null or not moonbase_panel.texture.resource_path.ends_with("empty_panel02.png"):
		_fail("Cargo screen did not use empty_panel02.png for the moonbase material panel.")
		return
	if moonbase_panel.size != Vector2(778.0, 385.0) or moonbase_panel.texture.get_size() != Vector2(778.0, 385.0):
		_fail("Moonbase material panel did not retain the PNG's native 778x385 size.")
		return
	if not is_equal_approx(moonbase_panel.modulate.a, 0.85):
		_fail("Moonbase material panel opacity did not match the other cargo panels.")
		return
	var original_moonbase_panel_position := moonbase_panel.position
	var original_moonbase_text_position := moonbase_label.position
	screen.moonbase_panel_x += 7.0
	screen.moonbase_panel_y += 9.0
	screen.moonbase_text_x += 11.0
	screen.moonbase_text_y += 13.0
	if moonbase_panel.position != original_moonbase_panel_position + Vector2(7.0, 9.0):
		_fail("Moonbase panel Inspector position controls did not update live.")
		return
	if moonbase_label.position != original_moonbase_text_position + Vector2(11.0, 13.0):
		_fail("Moonbase text Inspector position controls did not update live.")
		return
	var assignment_info_margin := screen.get_node("RootMargin/Layout/AssignmentPanel/AssignmentInfoPanel/Margin") as MarginContainer
	var packing_info_margin := screen.get_node("RootMargin/Layout/PackingPanel/PackingInfoPanel/Margin") as MarginContainer
	if (
		not packing_info_margin.scale.is_equal_approx(assignment_info_margin.scale)
		or not packing_info_margin.position.is_equal_approx(assignment_info_margin.position)
	):
		_fail("Packing information typography did not match the assignment information transform.")
		return
	var assignment_fuel_button := screen.get_node(
		"RootMargin/Layout/AssignmentPanel/AssignmentInfoPanel/Margin/InfoContent/MaterialButtons/FuelButton"
	) as Button
	var packing_fuel_button := screen.get_node(
		"RootMargin/Layout/PackingPanel/PackingInfoPanel/Margin/PackingInfoContent/PackingManifestFuelButton"
	) as Button
	var packing_fuel_status := screen.get_node(
		"RootMargin/Layout/PackingPanel/PackingInfoPanel/Margin/PackingInfoContent/PackingFuelStatusLabel"
	) as Label
	var assignment_capacity := screen.get_node(
		"RootMargin/Layout/AssignmentPanel/AssignmentInfoPanel/Margin/InfoContent/AssignmentMeters/CapacityLabel"
	) as Label
	var packing_capacity := screen.get_node(
		"RootMargin/Layout/PackingPanel/PackingInfoPanel/Margin/PackingInfoContent/PackingMeters/CapacityLabel"
	) as Label
	if packing_fuel_button.scale != Vector2.ONE or packing_fuel_button.size != assignment_fuel_button.size:
		_fail("Packing manifest buttons did not match assignment button sizing (%s versus %s, scale %s)." % [
			packing_fuel_button.size,
			assignment_fuel_button.size,
			packing_fuel_button.scale,
		])
		return
	if packing_fuel_button.position != assignment_fuel_button.get_parent().position + assignment_fuel_button.position:
		_fail("Packing manifest button placement did not match the assignment material block.")
		return
	if packing_fuel_button.icon == null:
		_fail("Packing manifest icon was not integrated into its button.")
		return
	if packing_capacity.position != assignment_capacity.position or packing_capacity.size != assignment_capacity.size:
		_fail("Packing meter geometry did not match the assignment meter geometry.")
		return
	if packing_fuel_status.get_theme_font_size("font_size") != screen.meter_text_font_size:
		_fail("Packing fuel warning did not match the assignment meter text style.")
		return
	var assignment_y_before_resize: float = assignment_panel.position.y
	screen.back_button_width = 196.0
	screen.back_button_height = 52.0
	screen.back_button_font_size = 25
	await process_frame
	if back_button.size != Vector2(196.0, 52.0) or back_button.get_theme_font_size("font_size") != 25:
		_fail("Cargo Back button Inspector controls did not update the runtime button.")
		return
	screen.back_button_height = 80.0
	await process_frame
	if not is_equal_approx(assignment_panel.position.y, assignment_y_before_resize):
		_fail("Resizing the independent Cargo Back button moved the assignment panel.")
		return
	if screen.capacity_label.get_theme_font_size("font_size") != 18:
		_fail("Cargo meter labels did not use the readability font size.")
		return
	var packing_selected_label := screen.get_node(
		"RootMargin/Layout/PackingPanel/PackingInfoPanel/Margin/PackingInfoContent/PackingSelectedCargoLabel"
	) as Label
	var configured_packing_label_size: int = screen.packing_selected_label_font_size
	if packing_selected_label.get_theme_font_size("font_size") != configured_packing_label_size:
		_fail("Packing selected-material label did not use its configured font size.")
		return
	screen.packing_selected_label_font_size = configured_packing_label_size + 2
	if packing_selected_label.get_theme_font_size("font_size") != configured_packing_label_size + 2:
		_fail("Packing selected-material font-size Inspector control did not update live.")
		return
	screen.packing_selected_label_font_size = configured_packing_label_size
	screen.meter_text_font_size = 20
	screen.meter_character_spacing = 2
	var meter_font := screen.capacity_label.get_theme_font("font") as FontVariation
	if screen.capacity_label.get_theme_font_size("font_size") != 20 or meter_font == null or meter_font.spacing_glyph != 2:
		_fail("Cargo meter text Inspector controls did not update the labels.")
		return

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
	if (
		screen.selected_piece_preview.texture == null
		or not screen.selected_piece_preview.texture.resource_path.contains("/cargo_pieces/")
	):
		_fail("Assignment phase no longer used its cargo-shape preview.")
		return
	screen._on_assignment_copy_pressed(big_pieces[1].instance_id)
	screen._on_material_pressed("silicon")
	if screen.assignment.get_assigned_piece(big_pieces[0].instance_id).material != "fuel":
		_fail("First grouped copy did not keep its assigned material.")
		return
	if screen.assignment.get_assigned_piece(big_pieces[1].instance_id).material != "silicon":
		_fail("Second grouped copy did not keep its different assigned material.")
		return
	screen._on_reset_pressed()
	screen._on_assignment_group_pressed(big_pieces[0].shape_id)
	var copy_a_button := screen.copy_buttons_row.get_child(0) as Button
	var copy_b_button := screen.copy_buttons_row.get_child(1) as Button
	copy_a_button.pressed.emit()
	screen._on_material_pressed("fuel")
	copy_b_button = screen.copy_buttons_row.get_child(1) as Button
	copy_b_button.pressed.emit()
	screen._on_material_pressed("silicon")
	if screen.assignment.get_assigned_piece(big_pieces[0].instance_id).material != "fuel":
		_fail("Copy A button did not assign material to the first copy.")
		return
	if screen.assignment.get_assigned_piece(big_pieces[1].instance_id).material != "silicon":
		_fail("Copy B button did not assign material to the second copy.")
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

	for index: int in range(TEST_MATERIALS.size()):
		if not screen.assignment.assign_material(pieces[index].instance_id, TEST_MATERIALS[index]):
			_fail("Could not assign %s for the packing material-preview test." % TEST_MATERIALS[index])
			return

	screen._on_confirm_pressed()
	if screen.phase != screen.CargoPhase.PACKING:
		_fail("Cargo screen did not move to packing phase.")
		return
	if screen.packing_selected_material_preview.visible:
		_fail("Packing material preview was visible before a piece was selected.")
		return

	if not screen.packing_state.place_piece(pieces[0].instance_id, Vector2i.ZERO, 0):
		_fail("Could not prepare a placed piece for the partial-overlap preview test.")
		return
	var placed_test_piece: Dictionary = screen.packing_state.get_placed_pieces()[0]
	var overlap_cell: Vector2i = placed_test_piece.get("occupied_cells", [Vector2i.ZERO])[0]
	var clear_cell := Vector2i(-1, -1)
	for x: int in range(screen.packing_state.grid.width):
		for y: int in range(screen.packing_state.grid.height):
			var candidate := Vector2i(x, y)
			if screen.packing_state.get_placed_piece_at_cell(candidate).is_empty():
				clear_cell = candidate
				break
		if clear_cell != Vector2i(-1, -1):
			break
	screen.packing_grid_view.set_selected_piece(pieces[1], 0)
	var grid_overlay: CargoGridView = screen.packing_grid_view.grid_overlay
	if grid_overlay._get_selected_preview_cell_color(overlap_cell) != Color(1.0, 0.18, 0.12, 0.38):
		_fail("An overlapping movable-piece cell did not use the red blocked color.")
		return
	if (
		clear_cell == Vector2i(-1, -1)
		or grid_overlay._get_selected_preview_cell_color(clear_cell)
		!= Color(0.88, 0.92, 0.95, 0.42)
	):
		_fail("A clear movable-piece cell did not remain gray.")
		return
	screen.packing_state.remove_piece(pieces[0].instance_id)
	screen.packing_grid_view.set_selected_piece(null, 0)

	for index: int in range(TEST_MATERIALS.size()):
		var material := TEST_MATERIALS[index]
		screen._on_packing_piece_pressed(pieces[index].instance_id)
		var preview_texture: Texture2D = screen.packing_selected_material_preview.texture
		if (
			preview_texture == null
			or preview_texture.resource_path != String(LARGE_MATERIAL_ICON_PATHS[material])
			or screen.packing_selected_material_preview.modulate != Color.WHITE
		):
			_fail("Packing selection did not show the untinted large %s icon." % material)
			return
		if screen.packing_selected_cargo_label.text == "" or not screen.packing_selected_cargo_label.visible:
			_fail("Packing material preview did not keep its material/unit label.")
			return

	screen._on_packing_piece_pressed(pieces[0].instance_id)
	var fuel_preview_path: String = screen.packing_selected_material_preview.texture.resource_path
	screen._rotate_selected_piece()
	if screen.selected_rotation != 90:
		_fail("Cargo screen did not rotate selected piece before placement.")
		return
	if screen.packing_selected_material_preview.texture.resource_path != fuel_preview_path:
		_fail("Rotating a piece changed its selected-material icon.")
		return
	screen._on_grid_cell_clicked(Vector2i(0, 0), MOUSE_BUTTON_LEFT)
	if screen.packing_state.get_placed_payload() != pieces[0].get_payload_units():
		_fail("Cargo screen did not place selected piece.")
		return
	if screen.packing_selected_material_preview.visible or screen.packing_selected_cargo_label.visible:
		_fail("Packing material preview did not hide after placement.")
		return
	screen._on_grid_cell_clicked(Vector2i(0, 0), MOUSE_BUTTON_LEFT)
	if screen.selected_piece_id != pieces[0].instance_id:
		_fail("Cargo screen did not pick up placed piece for moving.")
		return
	if screen.packing_state.get_placed_payload() != 0:
		_fail("Picked up piece still counted as placed payload.")
		return
	if (
		not screen.packing_selected_material_preview.visible
		or screen.packing_selected_material_preview.texture.resource_path != fuel_preview_path
	):
		_fail("Picking up a placed piece did not restore its large material icon.")
		return
	screen._on_grid_cell_clicked(Vector2i(1, 0), MOUSE_BUTTON_LEFT)
	if screen.packing_state.get_placed_payload() != pieces[0].get_payload_units():
		_fail("Cargo screen did not move picked-up piece.")
		return
	if screen.packing_selected_material_preview.visible:
		_fail("Packing material preview remained visible after moving the piece.")
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

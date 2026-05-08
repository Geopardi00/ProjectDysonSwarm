extends Control
class_name CargoLoadingScreen

signal launch_requested(vehicle_id: String, manifest: Dictionary)
signal assignment_cancelled

const GameDataScript := preload("res://scripts/data/GameData.gd")
const CargoAssignmentScript := preload("res://scripts/cargo/CargoAssignment.gd")
const UiAssetsScript := preload("res://scripts/data/UiAssets.gd")

enum CargoPhase { ASSIGNMENT, PACKING }

var assignment: CargoAssignment
var packing_state: CargoPackingState
var phase := CargoPhase.ASSIGNMENT
var selected_shape_id := ""
var selected_piece_id := ""
var selected_rotation := 0
var packing_status_text := ""
var moonbase_remaining_requirements: Dictionary = {}
var piece_buttons: Dictionary = {}
var packing_piece_buttons: Dictionary = {}
var half_size_piece_textures: Dictionary = {}

var root: VBoxContainer
var vehicle_label: Label
var capacity_label: Label
var fuel_label: Label
var warning_label: Label
var selected_piece_label: Label
var selected_piece_preview: TextureRect
var copy_buttons_row: HBoxContainer
var moonbase_needs_label: Label
var assignment_grid_preview: Control
var assignment_grid_label: Label
var payload_bar: ProgressBar
var fuel_bar: ProgressBar
var assignment_panel: HBoxContainer
var packing_panel: HBoxContainer
var piece_list: Control
var material_buttons: Control
var material_amount_labels: Dictionary = {}
var confirm_button: Button
var packing_piece_list: VBoxContainer
var packing_summary_label: Label
var packing_warning_label: Label
var packing_grid_view: Control
var launch_button: Button
var meters_container: VBoxContainer
var meter_sets: Array[Dictionary] = []


func _ready() -> void:
	_bind_scene_nodes()
	_build_material_buttons()
	UiAssetsScript.apply_text_outline(self)
	visible = false


func start_assignment(vehicle_id: String, remaining_requirements: Dictionary = {}) -> void:
	assignment = CargoAssignmentScript.new()
	assignment.setup(vehicle_id)
	set_moonbase_requirements(remaining_requirements)
	packing_state = null
	phase = CargoPhase.ASSIGNMENT
	selected_shape_id = ""
	selected_piece_id = ""
	selected_rotation = 0
	packing_status_text = ""
	visible = true
	assignment_panel.visible = true
	packing_panel.visible = false
	_rebuild_assignment_piece_buttons()
	_refresh()


func set_moonbase_requirements(requirements: Dictionary) -> void:
	if requirements.is_empty():
		moonbase_remaining_requirements = GameDataScript.MOONBASE_REQUIREMENTS.duplicate(true)
	else:
		moonbase_remaining_requirements = requirements.duplicate(true)


func _bind_scene_nodes() -> void:
	root = %Layout
	vehicle_label = %VehicleLabel
	assignment_panel = %AssignmentPanel
	packing_panel = %PackingPanel
	selected_piece_label = %SelectedPieceLabel
	selected_piece_preview = %SelectedPiecePreview
	copy_buttons_row = %CopyButtonsRow
	moonbase_needs_label = %MoonbaseNeedsLabel
	assignment_grid_preview = %AssignmentCargoHoldPanel
	assignment_grid_label = %AssignmentGridLabel
	piece_list = %PieceList
	material_buttons = %MaterialButtons
	confirm_button = %ConfirmButton
	packing_piece_list = %PackingPieceList
	packing_summary_label = %PackingSummaryLabel
	packing_warning_label = %PackingWarningLabel
	packing_grid_view = %PackingCargoHoldPanel
	launch_button = %LaunchButton

	%BackButton.pressed.connect(_on_back_pressed)
	%ResetButton.pressed.connect(_on_reset_pressed)
	confirm_button.pressed.connect(_on_confirm_pressed)
	%RotateButton.pressed.connect(_rotate_selected_piece)
	%ClearButton.pressed.connect(_on_clear_placements_pressed)
	launch_button.pressed.connect(_on_launch_pressed)
	packing_grid_view.grid_cell_clicked.connect(_on_grid_cell_clicked)

	meter_sets.clear()
	_register_meter_block(%AssignmentMeters)
	_register_meter_block(%PackingMeters)


func _register_meter_block(meters: Node) -> void:
	var next_capacity_label := meters.get_node("CapacityLabel") as Label
	var next_payload_bar := meters.get_node("PayloadBar") as ProgressBar
	var next_fuel_label := meters.get_node("FuelLabel") as Label
	var next_fuel_bar := meters.get_node("FuelBar") as ProgressBar
	var next_warning_label := meters.get_node("WarningLabel") as Label

	if capacity_label == null:
		capacity_label = next_capacity_label
		payload_bar = next_payload_bar
		fuel_label = next_fuel_label
		fuel_bar = next_fuel_bar
		warning_label = next_warning_label

	meter_sets.append({
		"capacity_label": next_capacity_label,
		"payload_bar": next_payload_bar,
		"fuel_label": next_fuel_label,
		"fuel_bar": next_fuel_bar,
		"warning_label": next_warning_label,
	})


func _unhandled_key_input(event: InputEvent) -> void:
	if not visible or phase != CargoPhase.PACKING:
		return
	if event.is_action_pressed("ui_cancel"):
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_R:
		_rotate_selected_piece()


func _build_material_buttons() -> void:
	for index in range(GameDataScript.MATERIALS.size()):
		var material := String(GameDataScript.MATERIALS[index])
		var button := material_buttons.get_node_or_null(_get_material_button_name(material)) as Button
		if button == null:
			button = Button.new()
			button.name = _get_material_button_name(material)
			button.position = Vector2(float(index % 2) * 115.0, float(index / 2) * 32.0)
			button.size = Vector2(110, 30)
			material_buttons.add_child(button)
		button.text = _format_material_name(material)
		button.icon = UiAssetsScript.get_material_icon(material)
		button.expand_icon = true
		button.add_theme_constant_override("icon_max_width", 30)
		button.pressed.connect(_on_material_pressed.bind(material))

		var amount_label := material_buttons.get_node_or_null(_get_material_amount_label_name(material)) as Label
		if amount_label == null:
			amount_label = Label.new()
			amount_label.name = _get_material_amount_label_name(material)
			amount_label.position = button.position + Vector2(button.size.x + 12.0, 3.0)
			amount_label.size = Vector2(120, 24)
			material_buttons.add_child(amount_label)
		material_amount_labels[material] = amount_label


func _get_material_button_name(material: String) -> String:
	return "%sButton" % material.to_pascal_case()


func _get_material_amount_label_name(material: String) -> String:
	return "%sAmountLabel" % material.to_pascal_case()


func _rebuild_assignment_piece_buttons() -> void:
	piece_buttons.clear()

	var groups := _get_assignment_piece_groups()
	var slot_buttons := _get_piece_slot_buttons()
	for index in range(slot_buttons.size()):
		var button := slot_buttons[index]
		if index >= groups.size():
			button.visible = false
			button.disabled = true
			button.text = ""
			button.icon = null
			if button.has_meta("shape_id"):
				button.remove_meta("shape_id")
			continue
		var group: Dictionary = groups[index]
		var piece: CargoPiece = group["pieces"][0]
		button.visible = true
		button.disabled = false
		button.text = ""
		button.tooltip_text = piece.display_name
		button.icon = _get_half_size_piece_texture(piece.shape_id)
		button.expand_icon = false
		button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
		button.flat = true
		button.toggle_mode = true
		button.set_meta("shape_id", piece.shape_id)
		var pressed_callable := _on_piece_slot_pressed.bind(button)
		if not button.pressed.is_connected(pressed_callable):
			button.pressed.connect(pressed_callable)
		piece_buttons[piece.shape_id] = button
	_fit_piece_list_scroll_area()


func _rebuild_packing_piece_buttons() -> void:
	for child in packing_piece_list.get_children():
		child.queue_free()
	packing_piece_buttons.clear()

	for piece: CargoPiece in packing_state.get_unplaced_pieces():
		var button := Button.new()
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.icon = UiAssetsScript.get_cargo_piece_texture(piece.shape_id)
		button.expand_icon = true
		button.add_theme_constant_override("icon_max_width", 96)
		button.text = _format_packing_piece_button_text(piece)
		button.pressed.connect(_on_packing_piece_pressed.bind(piece.instance_id))
		packing_piece_buttons[piece.instance_id] = button
		packing_piece_list.add_child(button)


func _refresh() -> void:
	if assignment == null:
		return
	if phase == CargoPhase.ASSIGNMENT:
		_refresh_assignment()
	else:
		_refresh_packing()


func _refresh_assignment() -> void:
	var vehicle := assignment.vehicle
	var max_payload := int(vehicle.get("max_payload", 0))
	var required_fuel := int(vehicle.get("required_fuel", 0))
	var assigned_payload := assignment.get_assigned_payload()
	var assigned_fuel := assignment.get_assigned_fuel()

	vehicle_label.text = "%s assignment" % String(vehicle.get("display_name", assignment.vehicle_id))
	assignment_grid_label.text = "Cargo hold preview: %dx%d" % [
		int(vehicle.get("grid_height", 0)),
		int(vehicle.get("grid_width", 0)),
	]
	assignment_grid_preview.set_grid(
		int(vehicle.get("grid_width", 0)),
		int(vehicle.get("grid_height", 0)),
		String(vehicle.get("display_name", assignment.vehicle_id)),
		assignment.vehicle_id
	)
	_update_meters("Assigned payload", assigned_payload, max_payload, "Assigned fuel", assigned_fuel, required_fuel)
	confirm_button.disabled = not assignment.can_confirm()

	selected_piece_label.text = ""
	_update_selected_piece_preview()
	_rebuild_copy_buttons()

	warning_label.text = _get_assignment_warning_text(required_fuel, assigned_fuel, max_payload, assigned_payload)
	_update_meter_warnings(warning_label.text)
	moonbase_needs_label.text = _format_moonbase_needs()
	_update_material_amount_labels()
	_refresh_assignment_piece_button_text()
	UiAssetsScript.apply_text_outline(self)


func _refresh_packing() -> void:
	var vehicle := packing_state.vehicle
	var max_payload := packing_state.get_max_payload()
	var required_fuel := packing_state.get_required_fuel()
	var placed_payload := packing_state.get_placed_payload()
	var placed_fuel := packing_state.get_placed_fuel()

	vehicle_label.text = "%s packing" % String(vehicle.get("display_name", packing_state.vehicle_id))
	_update_meters("Placed payload", placed_payload, max_payload, "Placed fuel", placed_fuel, required_fuel)
	warning_label.text = "Packing phase: assignments are locked."
	_update_meter_warnings(warning_label.text)
	packing_summary_label.text = _format_packing_summary()
	packing_warning_label.text = _get_packing_warning_text(required_fuel, placed_fuel)
	launch_button.disabled = packing_state.get_placed_payload() <= 0
	_rebuild_packing_piece_buttons()

	var selected_piece := packing_state.get_assigned_piece(selected_piece_id)
	packing_grid_view.set_packing_state(packing_state)
	packing_grid_view.set_selected_piece(selected_piece, selected_rotation)
	UiAssetsScript.apply_text_outline(self)


func _update_meter_warnings(text: String) -> void:
	for meter_set: Dictionary in meter_sets:
		var next_warning_label := meter_set["warning_label"] as Label
		next_warning_label.text = text


func _update_meters(payload_title: String, payload_value: int, max_payload: int, fuel_title: String, fuel_value: int, required_fuel: int) -> void:
	for meter_set: Dictionary in meter_sets:
		var next_capacity_label := meter_set["capacity_label"] as Label
		var next_payload_bar := meter_set["payload_bar"] as ProgressBar
		var next_fuel_label := meter_set["fuel_label"] as Label
		var next_fuel_bar := meter_set["fuel_bar"] as ProgressBar
		next_capacity_label.text = "%s: %d / %d" % [payload_title, payload_value, max_payload]
		next_payload_bar.max_value = max_payload
		next_payload_bar.value = payload_value
		next_fuel_label.text = "%s: %d / %d" % [fuel_title, fuel_value, required_fuel]
		next_fuel_bar.max_value = maxi(maxi(required_fuel, fuel_value), 1)
		next_fuel_bar.value = fuel_value


func _refresh_assignment_piece_button_text() -> void:
	for group: Dictionary in _get_assignment_piece_groups():
		var piece: CargoPiece = group["pieces"][0]
		var button := piece_buttons.get(piece.shape_id, null) as Button
		if button != null:
			button.text = ""
			button.button_pressed = piece.shape_id == selected_shape_id


func _get_piece_slot_buttons() -> Array[Button]:
	var buttons: Array[Button] = []
	for child in piece_list.get_children():
		if child is Button:
			buttons.append(child)
	buttons.sort_custom(func(a: Button, b: Button) -> bool:
		return a.name.naturalnocasecmp_to(b.name) < 0
	)
	return buttons


func _fit_piece_list_scroll_area() -> void:
	var content_size := Vector2(360, 640)
	for button in _get_piece_slot_buttons():
		if not button.visible:
			continue
		content_size.x = maxf(content_size.x, button.position.x + button.size.x + 16.0)
		content_size.y = maxf(content_size.y, button.position.y + button.size.y + 16.0)
	piece_list.custom_minimum_size = content_size


func _get_half_size_piece_texture(shape_id: String) -> Texture2D:
	if half_size_piece_textures.has(shape_id):
		return half_size_piece_textures[shape_id]
	var texture := UiAssetsScript.get_cargo_piece_texture(shape_id)
	if texture == null:
		return null
	var image := texture.get_image()
	if image == null:
		return texture
	var width := maxi(1, int(roundi(image.get_width() * 1.0)))
	var height := maxi(1, int(roundi(image.get_height() * 1.0)))
	image.resize(width, height, Image.INTERPOLATE_LANCZOS)
	var scaled_texture := ImageTexture.create_from_image(image)
	half_size_piece_textures[shape_id] = scaled_texture
	return scaled_texture


func _on_piece_slot_pressed(button: Button) -> void:
	if not button.has_meta("shape_id"):
		return
	_on_assignment_group_pressed(String(button.get_meta("shape_id")))


func _rebuild_copy_buttons() -> void:
	for child in copy_buttons_row.get_children():
		child.queue_free()
	var group := _get_assignment_group(selected_shape_id)
	if group.is_empty():
		return
	var pieces: Array = group["pieces"]
	for index in range(pieces.size()):
		var piece: CargoPiece = pieces[index]
		var button := Button.new()
		button.custom_minimum_size = Vector2(172, 36)
		button.clip_text = true
		var assigned_piece := assignment.get_assigned_piece(piece.instance_id)
		var material_text := "Unassigned"
		if assigned_piece != null:
			material_text = _format_material_name(assigned_piece.material)
		button.text = "Copy %s: %s" % [_copy_label(index), material_text]
		button.pressed.connect(_on_assignment_copy_pressed.bind(piece.instance_id))
		copy_buttons_row.add_child(button)


func _format_assignment_group_button_text(group: Dictionary) -> String:
	var piece: CargoPiece = group["pieces"][0]
	var pieces: Array = group["pieces"]
	var assigned_summary := _format_group_assignment_summary(pieces)
	var selected_marker := " *" if piece.shape_id == selected_shape_id else ""
	return "%s%s x%d | %d units each\n%s" % [
		piece.display_name,
		selected_marker,
		pieces.size(),
		piece.get_payload_units(),
		assigned_summary,
	]


func _format_packing_piece_button_text(piece: CargoPiece) -> String:
	var selected_marker := " *" if piece.instance_id == selected_piece_id else ""
	return "%s%s | %s | %d units" % [
		piece.display_name,
		selected_marker,
		_format_material_name(piece.material),
		piece.get_payload_units(),
	]


func _update_material_amount_labels() -> void:
	for material: String in GameDataScript.MATERIALS:
		var amount_label := material_amount_labels.get(material, null) as Label
		if amount_label == null:
			continue
		amount_label.text = "%d units" % assignment.get_assigned_amount_for_material(material)


func _update_selected_piece_preview() -> void:
	var group := _get_assignment_group(selected_shape_id)
	if group.is_empty():
		selected_piece_preview.texture = null
		selected_piece_preview.visible = false
		return

	selected_piece_preview.texture = UiAssetsScript.get_cargo_piece_texture(selected_shape_id)
	selected_piece_preview.visible = selected_piece_preview.texture != null


func _format_moonbase_needs() -> String:
	var lines: Array[String] = ["Moonbase material needs"]
	for material: String in GameDataScript.CONSTRUCTION_MATERIALS:
		var remaining := int(moonbase_remaining_requirements.get(material, GameDataScript.MOONBASE_REQUIREMENTS.get(material, 0)))
		var total := int(GameDataScript.MOONBASE_REQUIREMENTS.get(material, 0))
		var assigned := assignment.get_assigned_amount_for_material(material)
		lines.append("%s: %d / %d remaining | assigned: %d" % [
			_format_material_name(material),
			remaining,
			total,
			assigned,
		])
		if assigned > remaining:
			lines.append("Warning: assigned %s exceeds remaining need. Extra will be wasted if delivered." % _format_material_name(material))
	return "\n".join(lines)


func _format_packing_summary() -> String:
	var manifest := packing_state.get_manifest()
	var lines: Array[String] = [
		"Rotation: %d" % selected_rotation,
	]
	var selected_piece := packing_state.get_assigned_piece(selected_piece_id)
	if selected_piece != null:
		lines.append("Selected: %s" % selected_piece.display_name)
		lines.append("Material: %s" % _format_material_name(selected_piece.material))
		lines.append("Payload: %d" % selected_piece.get_payload_units())
	else:
		lines.append("Selected: none")

	lines.append("")
	lines.append("Placed manifest:")
	for material: String in GameDataScript.MATERIALS:
		var amount := int(manifest.get(material, 0))
		if amount > 0:
			lines.append("- %s: %d" % [_format_material_name(material), amount])
	if lines[lines.size() - 1] == "Placed manifest:":
		lines.append("- none")
	return "\n".join(lines)


func _get_assignment_warning_text(required_fuel: int, assigned_fuel: int, max_payload: int, assigned_payload: int) -> String:
	if assigned_payload > max_payload:
		return "Assigned payload exceeds capacity."
	if assigned_fuel < required_fuel:
		return "Fuel assigned is below required minimum."
	return "Assignment ready."


func _get_packing_warning_text(required_fuel: int, placed_fuel: int) -> String:
	var unplaced_count := packing_state.get_unplaced_pieces().size()
	var lines: Array[String] = []
	if packing_status_text != "":
		lines.append(packing_status_text)
	if placed_fuel < required_fuel:
		lines.append("Not enough fuel placed. Launch will crash.")
	else:
		lines.append("Fuel requirement satisfied.")
	lines.append("Unplaced assigned pieces: %d" % unplaced_count)
	return "\n".join(lines)


func _get_available_piece(instance_id: String) -> CargoPiece:
	if assignment == null:
		return null
	for piece: CargoPiece in assignment.get_available_pieces():
		if piece.instance_id == instance_id:
			return piece
	return null


func _get_assignment_piece_groups() -> Array[Dictionary]:
	var groups: Array[Dictionary] = []
	var group_by_shape := {}
	for piece: CargoPiece in assignment.get_available_pieces():
		if not group_by_shape.has(piece.shape_id):
			var group := {
				"shape_id": piece.shape_id,
				"pieces": [],
			}
			group_by_shape[piece.shape_id] = group
			groups.append(group)
		group_by_shape[piece.shape_id]["pieces"].append(piece)
	return groups


func _get_assignment_group(shape_id: String) -> Dictionary:
	if shape_id == "":
		return {}
	for group: Dictionary in _get_assignment_piece_groups():
		if String(group.get("shape_id", "")) == shape_id:
			return group
	return {}


func _format_group_assignment_summary(pieces: Array) -> String:
	var material_names: Array[String] = []
	var assigned_count := 0
	for piece: CargoPiece in pieces:
		var assigned_piece := assignment.get_assigned_piece(piece.instance_id)
		if assigned_piece != null:
			assigned_count += 1
			material_names.append(_format_material_name(assigned_piece.material))
	if material_names.is_empty():
		return "0 / %d assigned" % pieces.size()
	return "%d / %d assigned: %s" % [
		assigned_count,
		pieces.size(),
		" + ".join(material_names),
	]


func _copy_label(index: int) -> String:
	return char(65 + index)


func _format_material_name(material: String) -> String:
	return material.replace("_", " ").capitalize()


func _get_rotated_preview_rows(piece: CargoPiece, rotation: int) -> Array[String]:
	var cells: Array[Vector2i] = packing_state.grid.rotate_piece(piece.cells, rotation)
	var size := _get_preview_size(cells)
	var rows: Array[String] = []
	for y in range(size.y):
		var row := ""
		for x in range(size.x):
			row += "#" if cells.has(Vector2i(x, y)) else "."
		rows.append(row)
	return rows


func _get_preview_size(cells: Array[Vector2i]) -> Vector2i:
	if cells.is_empty():
		return Vector2i.ZERO
	var max_x := cells[0].x
	var max_y := cells[0].y
	for cell: Vector2i in cells:
		max_x = maxi(max_x, cell.x)
		max_y = maxi(max_y, cell.y)
	return Vector2i(max_x + 1, max_y + 1)


func _on_assignment_group_pressed(shape_id: String) -> void:
	selected_shape_id = shape_id
	var group := _get_assignment_group(shape_id)
	if group.is_empty():
		selected_piece_id = ""
	else:
		var pieces: Array = group["pieces"]
		var first_piece: CargoPiece = pieces[0]
		selected_piece_id = first_piece.instance_id
	_refresh()


func _on_assignment_copy_pressed(instance_id: String) -> void:
	selected_piece_id = instance_id
	_refresh()


func _on_material_pressed(material: String) -> void:
	if selected_piece_id == "":
		warning_label.text = "Select a piece first."
		return
	if not assignment.assign_material(selected_piece_id, material):
		warning_label.text = "Assignment rejected. Payload capacity would be exceeded."
		return
	_refresh()


func _on_reset_pressed() -> void:
	assignment.reset_assignments()
	_refresh()


func _on_confirm_pressed() -> void:
	packing_state = assignment.create_packing_state()
	phase = CargoPhase.PACKING
	selected_piece_id = ""
	selected_rotation = 0
	packing_status_text = ""
	assignment_panel.visible = false
	packing_panel.visible = true
	_refresh()


func _on_packing_piece_pressed(instance_id: String) -> void:
	selected_piece_id = instance_id
	selected_rotation = 0
	packing_status_text = "Selected piece. Rotate it or click the grid to place it."
	_refresh()


func _rotate_selected_piece() -> void:
	if selected_piece_id == "":
		return
	selected_rotation = (selected_rotation + 90) % 360
	packing_status_text = "Rotation set to %d." % selected_rotation
	_refresh()


func _on_grid_cell_clicked(cell: Vector2i, mouse_button: int) -> void:
	if mouse_button == MOUSE_BUTTON_RIGHT:
		var placed_piece := packing_state.get_placed_piece_at_cell(cell)
		if not placed_piece.is_empty():
			packing_state.remove_piece(String(placed_piece.get("instance_id", "")))
			packing_status_text = "Removed placed piece."
			_refresh()
		return

	if mouse_button != MOUSE_BUTTON_LEFT:
		return
	var placed_piece := packing_state.get_placed_piece_at_cell(cell)
	if selected_piece_id == "" and not placed_piece.is_empty():
		selected_piece_id = String(placed_piece.get("instance_id", ""))
		selected_rotation = int(placed_piece.get("rotation", 0))
		packing_state.remove_piece(selected_piece_id)
		packing_status_text = "Picked up placed piece. Move it or rotate it before placing."
		_refresh()
		return
	if selected_piece_id == "":
		return
	if packing_state.place_piece(selected_piece_id, cell, selected_rotation):
		selected_piece_id = ""
		selected_rotation = 0
		packing_status_text = "Piece placed."
	else:
		packing_status_text = "Piece does not fit there."
	_refresh()


func _on_clear_placements_pressed() -> void:
	packing_state.clear_placements()
	selected_piece_id = ""
	selected_rotation = 0
	packing_status_text = "Placements cleared."
	_refresh()


func _on_launch_pressed() -> void:
	launch_requested.emit(packing_state.vehicle_id, packing_state.get_manifest())


func _on_back_pressed() -> void:
	if phase == CargoPhase.PACKING:
		assignment_cancelled.emit()
	else:
		assignment_cancelled.emit()

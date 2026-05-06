extends Control
class_name CargoLoadingScreen

signal launch_requested(vehicle_id: String, manifest: Dictionary)
signal assignment_cancelled

const GameDataScript := preload("res://scripts/data/GameData.gd")
const CargoAssignmentScript := preload("res://scripts/cargo/CargoAssignment.gd")
const CargoGridViewScript := preload("res://scenes/ui/CargoGridView.gd")
const CargoHoldPreviewScript := preload("res://scenes/ui/CargoHoldPreview.gd")
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

var root: VBoxContainer
var vehicle_label: Label
var capacity_label: Label
var fuel_label: Label
var warning_label: Label
var selected_piece_label: Label
var copy_buttons_row: HBoxContainer
var moonbase_needs_label: Label
var assignment_grid_preview: Control
var assignment_grid_label: Label
var assigned_label: Label
var payload_bar: ProgressBar
var fuel_bar: ProgressBar
var assignment_panel: HBoxContainer
var packing_panel: HBoxContainer
var piece_list: VBoxContainer
var material_buttons: GridContainer
var confirm_button: Button
var packing_piece_list: VBoxContainer
var packing_summary_label: Label
var packing_warning_label: Label
var packing_grid_view: Control
var launch_button: Button
var meters_container: VBoxContainer
var meter_sets: Array[Dictionary] = []


func _ready() -> void:
	_add_scene_background()
	_build_ui()
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


func _add_scene_background() -> void:
	var texture := UiAssetsScript.get_background()
	if texture == null:
		return
	var background := TextureRect.new()
	background.name = "Background"
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.texture = texture
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	move_child(background, 0)


func _with_panel_art(content: Control, frame_id: String, minimum_size: Vector2) -> Control:
	var wrapper := Control.new()
	wrapper.custom_minimum_size = minimum_size
	wrapper.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	wrapper.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var frame_texture := UiAssetsScript.get_panel_frame(frame_id)
	if frame_texture != null:
		var frame := TextureRect.new()
		frame.set_anchors_preset(Control.PRESET_FULL_RECT)
		frame.texture = frame_texture
		frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		frame.stretch_mode = TextureRect.STRETCH_SCALE
		frame.modulate.a = 0.85
		frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
		wrapper.add_child(frame)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_top", 28)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_bottom", 28)
	wrapper.add_child(margin)
	margin.add_child(content)

	return wrapper


func _with_cargo_hold_panel(content: Control) -> Control:
	var wrapper := Control.new()
	wrapper.custom_minimum_size = Vector2(778, 478)
	wrapper.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	wrapper.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var frame_texture := UiAssetsScript.get_panel_frame("cargo_hold")
	if frame_texture != null:
		var frame := TextureRect.new()
		frame.set_anchors_preset(Control.PRESET_FULL_RECT)
		frame.texture = frame_texture
		frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		frame.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		frame.modulate.a = 0.95
		frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
		wrapper.add_child(frame)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 84)
	margin.add_theme_constant_override("margin_top", 104)
	margin.add_theme_constant_override("margin_right", 72)
	margin.add_theme_constant_override("margin_bottom", 64)
	wrapper.add_child(margin)
	margin.add_child(content)

	return wrapper


func _build_meter_block() -> VBoxContainer:
	var meters := VBoxContainer.new()
	meters.add_theme_constant_override("separation", 6)

	var next_capacity_label := Label.new()
	meters.add_child(next_capacity_label)

	var next_payload_bar := ProgressBar.new()
	next_payload_bar.show_percentage = false
	meters.add_child(next_payload_bar)

	var next_fuel_label := Label.new()
	meters.add_child(next_fuel_label)

	var next_fuel_bar := ProgressBar.new()
	next_fuel_bar.show_percentage = false
	meters.add_child(next_fuel_bar)

	var next_warning_label := Label.new()
	next_warning_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	meters.add_child(next_warning_label)

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

	return meters


func _unhandled_key_input(event: InputEvent) -> void:
	if not visible or phase != CargoPhase.PACKING:
		return
	if event.is_action_pressed("ui_cancel"):
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_R:
		_rotate_selected_piece()


func _build_ui() -> void:
	anchors_preset = Control.PRESET_FULL_RECT

	var root_margin := MarginContainer.new()
	root_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_margin.add_theme_constant_override("margin_left", 24)
	root_margin.add_theme_constant_override("margin_top", 24)
	root_margin.add_theme_constant_override("margin_right", 24)
	root_margin.add_theme_constant_override("margin_bottom", 24)
	add_child(root_margin)

	root = VBoxContainer.new()
	root.add_theme_constant_override("separation", 12)
	root_margin.add_child(root)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	root.add_child(header)

	vehicle_label = Label.new()
	vehicle_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vehicle_label.add_theme_font_size_override("font_size", 22)
	header.add_child(vehicle_label)

	var back_button := Button.new()
	back_button.text = "Back"
	back_button.pressed.connect(_on_back_pressed)
	header.add_child(back_button)

	_build_assignment_panel()
	_build_packing_panel()


func _build_assignment_panel() -> void:
	assignment_panel = HBoxContainer.new()
	assignment_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	assignment_panel.add_theme_constant_override("separation", 16)
	root.add_child(assignment_panel)

	var piece_scroll := ScrollContainer.new()
	piece_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	piece_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	piece_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED

	piece_list = VBoxContainer.new()
	piece_list.add_theme_constant_override("separation", 6)
	piece_scroll.add_child(piece_list)

	var center_panel := VBoxContainer.new()
	center_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	center_panel.add_theme_constant_override("separation", 10)

	moonbase_needs_label = Label.new()
	moonbase_needs_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	center_panel.add_child(moonbase_needs_label)

	assignment_grid_label = Label.new()
	assignment_grid_label.add_theme_font_size_override("font_size", 18)
	center_panel.add_child(assignment_grid_label)

	assignment_grid_preview = CargoHoldPreviewScript.new()
	assignment_grid_preview.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	assignment_grid_preview.size_flags_vertical = Control.SIZE_EXPAND_FILL
	center_panel.add_child(_with_cargo_hold_panel(assignment_grid_preview))

	var side_panel := VBoxContainer.new()
	side_panel.add_theme_constant_override("separation", 10)

	var detail_scroll := ScrollContainer.new()
	detail_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	side_panel.add_child(detail_scroll)

	var detail_content := VBoxContainer.new()
	detail_content.add_theme_constant_override("separation", 10)
	detail_scroll.add_child(detail_content)

	selected_piece_label = Label.new()
	selected_piece_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_content.add_child(selected_piece_label)

	copy_buttons_row = HBoxContainer.new()
	copy_buttons_row.add_theme_constant_override("separation", 6)
	detail_content.add_child(copy_buttons_row)

	var lower_spacer := Control.new()
	lower_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	side_panel.add_child(lower_spacer)

	meters_container = _build_meter_block()
	side_panel.add_child(meters_container)

	material_buttons = GridContainer.new()
	material_buttons.columns = 2
	material_buttons.add_theme_constant_override("h_separation", 6)
	material_buttons.add_theme_constant_override("v_separation", 6)
	side_panel.add_child(material_buttons)
	_build_material_buttons()

	assigned_label = Label.new()
	assigned_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	side_panel.add_child(assigned_label)

	var action_row := HBoxContainer.new()
	action_row.add_theme_constant_override("separation", 8)
	side_panel.add_child(action_row)

	var reset_button := Button.new()
	reset_button.text = "Reset Assignments"
	reset_button.pressed.connect(_on_reset_pressed)
	action_row.add_child(reset_button)

	confirm_button = Button.new()
	confirm_button.text = "Confirm Assignments"
	confirm_button.pressed.connect(_on_confirm_pressed)
	action_row.add_child(confirm_button)

	assignment_panel.add_child(_with_panel_art(side_panel, "vehicle_info", Vector2(420, 760)))
	assignment_panel.add_child(center_panel)
	assignment_panel.add_child(_with_panel_art(piece_scroll, "available_cargo", Vector2(460, 760)))


func _build_packing_panel() -> void:
	packing_panel = HBoxContainer.new()
	packing_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	packing_panel.add_theme_constant_override("separation", 16)
	packing_panel.visible = false
	root.add_child(packing_panel)

	var left_panel := VBoxContainer.new()
	left_panel.add_theme_constant_override("separation", 10)

	var title := Label.new()
	title.text = "Pieces to place"
	title.add_theme_font_size_override("font_size", 18)
	left_panel.add_child(title)

	var piece_scroll := ScrollContainer.new()
	piece_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_panel.add_child(piece_scroll)

	packing_piece_list = VBoxContainer.new()
	packing_piece_list.add_theme_constant_override("separation", 6)
	piece_scroll.add_child(packing_piece_list)

	var rotate_button := Button.new()
	rotate_button.text = "Rotate Selected"
	rotate_button.pressed.connect(_rotate_selected_piece)
	left_panel.add_child(rotate_button)

	var clear_button := Button.new()
	clear_button.text = "Clear Placements"
	clear_button.pressed.connect(_on_clear_placements_pressed)
	left_panel.add_child(clear_button)

	var center_panel := VBoxContainer.new()
	center_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	center_panel.add_theme_constant_override("separation", 10)

	packing_grid_view = CargoGridViewScript.new()
	packing_grid_view.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	packing_grid_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	packing_grid_view.grid_cell_clicked.connect(_on_grid_cell_clicked)
	center_panel.add_child(_with_cargo_hold_panel(packing_grid_view))

	var right_panel := VBoxContainer.new()
	right_panel.add_theme_constant_override("separation", 10)

	packing_summary_label = Label.new()
	packing_summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	right_panel.add_child(packing_summary_label)

	packing_warning_label = Label.new()
	packing_warning_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	packing_warning_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_panel.add_child(packing_warning_label)

	var packing_lower_spacer := Control.new()
	packing_lower_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_panel.add_child(packing_lower_spacer)

	right_panel.add_child(_build_meter_block())

	launch_button = Button.new()
	launch_button.text = "Launch"
	launch_button.pressed.connect(_on_launch_pressed)
	right_panel.add_child(launch_button)

	packing_panel.add_child(_with_panel_art(right_panel, "vehicle_info", Vector2(420, 760)))
	packing_panel.add_child(center_panel)
	packing_panel.add_child(_with_panel_art(left_panel, "available_cargo", Vector2(460, 760)))


func _build_material_buttons() -> void:
	for material: String in GameDataScript.MATERIALS:
		var button := Button.new()
		button.text = _format_material_name(material)
		button.icon = UiAssetsScript.get_material_icon(material)
		button.expand_icon = true
		button.add_theme_constant_override("icon_max_width", 30)
		button.pressed.connect(_on_material_pressed.bind(material))
		material_buttons.add_child(button)


func _rebuild_assignment_piece_buttons() -> void:
	for child in piece_list.get_children():
		child.queue_free()
	piece_buttons.clear()

	for group: Dictionary in _get_assignment_piece_groups():
		var piece: CargoPiece = group["pieces"][0]
		var button := Button.new()
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.icon = UiAssetsScript.get_cargo_piece_texture(piece.shape_id)
		button.expand_icon = true
		button.add_theme_constant_override("icon_max_width", 96)
		button.text = _format_assignment_group_button_text(group)
		button.pressed.connect(_on_assignment_group_pressed.bind(piece.shape_id))
		piece_buttons[piece.shape_id] = button
		piece_list.add_child(button)


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
		String(vehicle.get("display_name", assignment.vehicle_id))
	)
	_update_meters("Assigned payload", assigned_payload, max_payload, "Assigned fuel", assigned_fuel, required_fuel)
	confirm_button.disabled = not assignment.can_confirm()

	selected_piece_label.text = _format_selected_shape_details()
	_rebuild_copy_buttons()

	warning_label.text = _get_assignment_warning_text(required_fuel, assigned_fuel, max_payload, assigned_payload)
	_update_meter_warnings(warning_label.text)
	moonbase_needs_label.text = _format_moonbase_needs()
	assigned_label.text = _format_assigned_list()
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
			button.text = _format_assignment_group_button_text(group)


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


func _format_assigned_list() -> String:
	var lines: Array[String] = ["Assigned pieces:"]
	var assigned_pieces := assignment.get_assigned_pieces()
	if assigned_pieces.is_empty():
		lines.append("- none")
	else:
		for piece: CargoPiece in assigned_pieces:
			lines.append("- %s = %s, %d units" % [
				piece.display_name,
				_format_material_name(piece.material),
				piece.get_payload_units(),
			])
	return "\n".join(lines)


func _format_selected_shape_details() -> String:
	var group := _get_assignment_group(selected_shape_id)
	if group.is_empty():
		return "Selected shape: none"

	var pieces: Array = group["pieces"]
	var first_piece: CargoPiece = pieces[0]
	var lines: Array[String] = [
		"Selected shape: %s x%d" % [first_piece.display_name, pieces.size()],
		"Payload per copy: %d" % first_piece.get_payload_units(),
		"",
		"Copies:",
	]
	for index in range(pieces.size()):
		var piece: CargoPiece = pieces[index]
		var assigned_piece := assignment.get_assigned_piece(piece.instance_id)
		var material_text := "Unassigned"
		if assigned_piece != null:
			material_text = _format_material_name(assigned_piece.material)
		var selected_marker := " *" if piece.instance_id == selected_piece_id else ""
		lines.append("Copy %s%s: %s" % [_copy_label(index), selected_marker, material_text])
	lines.append("")
	lines.append("Select a copy below, then choose a material.")
	return "\n".join(lines)


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

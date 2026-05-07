extends Control
class_name CargoGridView

signal grid_cell_clicked(cell: Vector2i, mouse_button: int)

const MATERIAL_COLORS := {
	"fuel": Color(0.95, 0.32, 0.12),
	"carbon_metals": Color(0.35, 0.37, 0.39),
	"silicon": Color(0.20, 0.55, 0.95),
	"copper": Color(0.82, 0.43, 0.18),
	"electronics": Color(0.20, 0.68, 0.35),
	"rare_metals": Color(0.60, 0.36, 0.86),
	"propellant": Color(0.10, 0.70, 0.72),
}

var packing_state
var selected_piece: CargoPiece
var selected_rotation := 0
var grid_width := 0
var grid_height := 0
var vehicle_name := ""
var cell_size := 48.0

@export var fixed_cell_size := 0.0:
	set(value):
		fixed_cell_size = value
		queue_redraw()
@export var debug_draw_grid := false:
	set(value):
		debug_draw_grid = value
		queue_redraw()
@export var manual_grid_origin := Vector2.ZERO:
	set(value):
		manual_grid_origin = value
		queue_redraw()
@export var manual_grid_size := Vector2(620, 300):
	set(value):
		manual_grid_size = value
		queue_redraw()
@export var use_manual_grid_rect := false:
	set(value):
		use_manual_grid_rect = value
		queue_redraw()


func set_grid(next_width: int, next_height: int, next_vehicle_name: String = "") -> void:
	grid_width = next_width
	grid_height = next_height
	vehicle_name = next_vehicle_name
	queue_redraw()


func set_packing_state(next_packing_state) -> void:
	packing_state = next_packing_state
	if packing_state != null:
		grid_width = int(packing_state.vehicle.get("grid_width", 0))
		grid_height = int(packing_state.vehicle.get("grid_height", 0))
		vehicle_name = String(packing_state.vehicle.get("display_name", ""))
	queue_redraw()


func set_selected_piece(piece: CargoPiece, rotation: int) -> void:
	selected_piece = piece
	selected_rotation = rotation
	queue_redraw()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	custom_minimum_size = Vector2(620, 300)


func _gui_input(event: InputEvent) -> void:
	if packing_state == null:
		return
	if event is InputEventMouseMotion:
		queue_redraw()
	if event is InputEventMouseButton and event.pressed:
		var cell := _position_to_cell(event.position)
		if _is_cell_in_grid(cell):
			grid_cell_clicked.emit(cell, event.button_index)


func _draw() -> void:
	if grid_width <= 0 or grid_height <= 0:
		return

	_update_cell_size()
	if debug_draw_grid:
		_draw_debug_grid()
	if packing_state != null:
		_draw_placed_pieces()
		_draw_selected_piece_preview()


func _update_cell_size() -> void:
	if fixed_cell_size > 0.0:
		cell_size = fixed_cell_size
		return

	var grid_rect := _get_grid_rect()
	cell_size = floor(min(grid_rect.size.x / float(grid_height), grid_rect.size.y / float(grid_width)))
	cell_size = max(cell_size, 1.0)


func _draw_debug_grid() -> void:
	var grid_rect := _get_drawn_grid_rect()
	var line_color := Color(0.95, 0.55, 0.04, 0.75)
	draw_rect(grid_rect, Color(0.05, 0.07, 0.08, 0.25), true)
	draw_rect(grid_rect, line_color, false, 2.0)
	for x in range(grid_height + 1):
		var line_x := grid_rect.position.x + x * cell_size
		draw_line(Vector2(line_x, grid_rect.position.y), Vector2(line_x, grid_rect.position.y + grid_width * cell_size), line_color)
	for y in range(grid_width + 1):
		var line_y := grid_rect.position.y + y * cell_size
		draw_line(Vector2(grid_rect.position.x, line_y), Vector2(grid_rect.position.x + grid_height * cell_size, line_y), line_color)


func _draw_placed_pieces() -> void:
	for placed_piece: Dictionary in packing_state.get_placed_pieces():
		var material := String(placed_piece.get("material", ""))
		var color: Color = MATERIAL_COLORS.get(material, Color(0.50, 0.55, 0.60))
		var occupied_cells: Array = placed_piece.get("occupied_cells", [])
		for cell: Vector2i in occupied_cells:
			_draw_cell(cell, color, true)


func _draw_selected_piece_preview() -> void:
	if selected_piece == null:
		return
	var mouse_cell := _position_to_cell(get_local_mouse_position())
	if not _is_cell_in_grid(mouse_cell):
		return

	var can_place: bool = packing_state.grid.can_place_piece(selected_piece, mouse_cell, selected_rotation)
	var color := Color(0.88, 0.92, 0.95, 0.42) if can_place else Color(1.0, 0.18, 0.12, 0.38)
	var occupied_cells: Array[Vector2i] = packing_state.grid.get_occupied_cells(selected_piece.cells, mouse_cell, selected_rotation)
	for cell: Vector2i in occupied_cells:
		if _is_cell_in_grid(cell):
			_draw_cell(cell, color, true)


func _draw_cell(cell: Vector2i, color: Color, filled: bool) -> void:
	var display_cell := _data_cell_to_display_cell(cell)
	var origin := _get_drawn_grid_rect().position
	var rect := Rect2(origin + Vector2(display_cell) * cell_size + Vector2.ONE, Vector2.ONE * (cell_size - 2.0))
	draw_rect(rect, color, filled)
	draw_rect(rect, Color(0.03, 0.04, 0.05, 0.75), false, 1.0)


func _position_to_cell(position: Vector2) -> Vector2i:
	var local_position := position - _get_drawn_grid_rect().position
	var display_cell := Vector2i(floori(local_position.x / cell_size), floori(local_position.y / cell_size))
	return Vector2i(display_cell.y, display_cell.x)


func _data_cell_to_display_cell(cell: Vector2i) -> Vector2i:
	return Vector2i(cell.y, cell.x)


func _is_cell_in_grid(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < grid_width and cell.y < grid_height


func _get_grid_rect() -> Rect2:
	if use_manual_grid_rect:
		return Rect2(manual_grid_origin, manual_grid_size)
	return Rect2(Vector2.ZERO, size)


func _get_drawn_grid_rect() -> Rect2:
	var grid_rect := _get_grid_rect()
	var drawn_size := Vector2(grid_height, grid_width) * cell_size
	var origin := grid_rect.position + (grid_rect.size - drawn_size) * 0.5
	return Rect2(origin, drawn_size)

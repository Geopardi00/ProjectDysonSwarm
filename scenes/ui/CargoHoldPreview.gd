extends Control
class_name CargoHoldPreview

var grid_width := 0
var grid_height := 0
var vehicle_name := ""
var cell_size := 42.0


func set_grid(next_width: int, next_height: int, next_vehicle_name: String) -> void:
	grid_width = next_width
	grid_height = next_height
	vehicle_name = next_vehicle_name
	queue_redraw()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(420, 420)


func _draw() -> void:
	if grid_width <= 0 or grid_height <= 0:
		return

	_update_cell_size()
	var display_width := grid_height
	var display_height := grid_width
	var grid_size := Vector2(display_width, display_height) * cell_size
	var origin := (size - grid_size) * 0.5
	origin.x = max(origin.x, 0.0)
	origin.y = max(origin.y, 0.0)

	draw_rect(Rect2(origin, grid_size), Color(0.07, 0.09, 0.10), true)
	draw_rect(Rect2(origin, grid_size), Color(0.80, 0.50, 0.16, 0.95), false, 2.0)

	var line_color := Color(0.80, 0.50, 0.16, 0.62)
	for x in range(display_width + 1):
		var line_x := origin.x + x * cell_size
		draw_line(Vector2(line_x, origin.y), Vector2(line_x, origin.y + grid_size.y), line_color)
	for y in range(display_height + 1):
		var line_y := origin.y + y * cell_size
		draw_line(Vector2(origin.x, line_y), Vector2(origin.x + grid_size.x, line_y), line_color)


func _update_cell_size() -> void:
	cell_size = floor(min(size.x / float(grid_height), size.y / float(grid_width)))
	cell_size = clampf(cell_size, 18.0, 58.0)

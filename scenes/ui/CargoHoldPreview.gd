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
	custom_minimum_size = Vector2(620, 300)


func _draw() -> void:
	if grid_width <= 0 or grid_height <= 0:
		return
	# The cargo hold panel art supplies the visible grid in this visual pass.
	# This control remains as a data-driven placeholder for future overlays.


func _update_cell_size() -> void:
	cell_size = floor(min(size.x / float(grid_height), size.y / float(grid_width)))
	cell_size = clampf(cell_size, 18.0, 64.0)

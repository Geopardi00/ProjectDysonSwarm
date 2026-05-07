extends Control
class_name CargoHoldPanel

signal grid_cell_clicked(cell: Vector2i, mouse_button: int)

const BIG_ROCKET_PANEL := preload("res://assets/ui/panels/panel_cargo_hold.png")
const SHUTTLE_PANEL := preload("res://assets/ui/panels/panel_cargo_hold_shuttle.png")
const SPINLAUNCH_PANEL := preload("res://assets/ui/panels/panel_cargo_hold_spinlaunch.png")
const ART_CELL_SIZE := 62.0

@export var debug_draw_grid := false:
	set(value):
		debug_draw_grid = value
		if grid_overlay != null:
			grid_overlay.debug_draw_grid = value

@onready var panel_art: TextureRect = %PanelArt
@onready var grid_overlay: CargoGridView = %GridOverlay

var grid_width := 0
var grid_height := 0
var vehicle_name := ""
var vehicle_id := ""


func _ready() -> void:
	grid_overlay.grid_cell_clicked.connect(_on_grid_cell_clicked)
	grid_overlay.debug_draw_grid = debug_draw_grid
	grid_overlay.fixed_cell_size = ART_CELL_SIZE


func set_grid(next_width: int, next_height: int, next_vehicle_name: String = "", next_vehicle_id: String = "") -> void:
	grid_width = next_width
	grid_height = next_height
	vehicle_name = next_vehicle_name
	vehicle_id = _resolve_vehicle_id(next_vehicle_id)
	_apply_vehicle_art()
	grid_overlay.set_grid(next_width, next_height, next_vehicle_name)


func set_packing_state(next_packing_state) -> void:
	grid_overlay.set_packing_state(next_packing_state)
	if next_packing_state != null:
		grid_width = int(next_packing_state.vehicle.get("grid_width", 0))
		grid_height = int(next_packing_state.vehicle.get("grid_height", 0))
		vehicle_name = String(next_packing_state.vehicle.get("display_name", ""))
		vehicle_id = _resolve_vehicle_id(String(next_packing_state.vehicle.get("id", next_packing_state.vehicle_id)))
		_apply_vehicle_art()


func set_selected_piece(piece: CargoPiece, rotation: int) -> void:
	grid_overlay.set_selected_piece(piece, rotation)


func _on_grid_cell_clicked(cell: Vector2i, mouse_button: int) -> void:
	grid_cell_clicked.emit(cell, mouse_button)


func _resolve_vehicle_id(next_vehicle_id: String) -> String:
	if not next_vehicle_id.is_empty():
		return next_vehicle_id
	if grid_width == 4 and grid_height == 8:
		return "space_shuttle"
	if grid_width == 1 and grid_height == 2:
		return "spinlaunch"
	return "big_rocket"


func _apply_vehicle_art() -> void:
	if panel_art == null:
		return
	match vehicle_id:
		"space_shuttle":
			panel_art.texture = SHUTTLE_PANEL
		"spinlaunch":
			panel_art.texture = SPINLAUNCH_PANEL
		_:
			panel_art.texture = BIG_ROCKET_PANEL

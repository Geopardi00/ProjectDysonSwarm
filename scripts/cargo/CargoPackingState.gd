extends RefCounted
class_name CargoPackingState

const GameDataScript := preload("res://scripts/data/GameData.gd")
const CargoGridScript := preload("res://scripts/cargo/CargoGrid.gd")

var vehicle_id := ""
var vehicle: Dictionary = {}
var assigned_pieces: Dictionary = {}
var grid: CargoGrid


func setup(selected_vehicle_id: String, pieces_from_assignment: Array[CargoPiece]) -> void:
	vehicle_id = selected_vehicle_id
	vehicle = GameDataScript.get_vehicle(vehicle_id)
	assigned_pieces.clear()
	for piece: CargoPiece in pieces_from_assignment:
		assigned_pieces[piece.instance_id] = piece.duplicate_piece()

	grid = CargoGridScript.new()
	grid.setup(int(vehicle.get("grid_width", 0)), int(vehicle.get("grid_height", 0)))


func place_piece(instance_id: String, origin: Vector2i, rotation: int = 0) -> bool:
	var piece := get_assigned_piece(instance_id)
	if piece == null:
		return false
	return grid.place_piece(piece, origin, rotation)


func remove_piece(instance_id: String) -> bool:
	return grid.remove_piece(instance_id)


func clear_placements() -> void:
	grid.clear()


func get_manifest() -> Dictionary:
	return grid.get_manifest_from_placed_pieces()


func get_placed_payload() -> int:
	return grid.get_placed_payload()


func get_placed_fuel() -> int:
	return int(get_manifest().get(GameDataScript.MATERIAL_FUEL, 0))


func get_unplaced_pieces() -> Array[CargoPiece]:
	var unplaced: Array[CargoPiece] = []
	for piece: CargoPiece in assigned_pieces.values():
		if not grid.placed_pieces.has(piece.instance_id):
			unplaced.append(piece.duplicate_piece())
	return unplaced


func get_placed_pieces() -> Array[Dictionary]:
	var pieces: Array[Dictionary] = []
	for placed_piece: Dictionary in grid.placed_pieces.values():
		pieces.append(placed_piece.duplicate(true))
	return pieces


func get_placed_piece_at_cell(cell: Vector2i) -> Dictionary:
	for placed_piece: Dictionary in grid.placed_pieces.values():
		var occupied_cells: Array = placed_piece.get("occupied_cells", [])
		if occupied_cells.has(cell):
			return placed_piece.duplicate(true)
	return {}


func get_required_fuel() -> int:
	return int(vehicle.get("required_fuel", 0))


func get_max_payload() -> int:
	return int(vehicle.get("max_payload", 0))


func get_assigned_piece(instance_id: String) -> CargoPiece:
	return assigned_pieces.get(instance_id, null) as CargoPiece

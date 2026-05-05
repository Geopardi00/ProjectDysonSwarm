extends RefCounted
class_name CargoGrid

const GameDataScript := preload("res://scripts/data/GameData.gd")

var width := 0
var height := 0
var placed_pieces: Dictionary = {}


func setup(grid_width: int, grid_height: int) -> void:
	width = grid_width
	height = grid_height
	clear()


func can_place_piece(piece: CargoPiece, origin: Vector2i, rotation: int = 0) -> bool:
	if piece == null or not piece.has_material():
		return false

	var occupied_cells := get_occupied_cells(piece.cells, origin, rotation)
	for cell: Vector2i in occupied_cells:
		if not _is_in_bounds(cell):
			return false
		if _is_cell_occupied_by_other_piece(cell, piece.instance_id):
			return false
	return true


func place_piece(piece: CargoPiece, origin: Vector2i, rotation: int = 0) -> bool:
	if not can_place_piece(piece, origin, rotation):
		return false

	placed_pieces[piece.instance_id] = {
		"instance_id": piece.instance_id,
		"shape_id": piece.shape_id,
		"display_name": piece.display_name,
		"material": piece.material,
		"origin": origin,
		"rotation": _normalize_rotation(rotation),
		"cells": piece.cells.duplicate(),
		"occupied_cells": get_occupied_cells(piece.cells, origin, rotation),
		"payload_units": piece.get_payload_units(),
	}
	return true


func remove_piece(instance_id: String) -> bool:
	return placed_pieces.erase(instance_id)


func rotate_piece(cells: Array[Vector2i], rotation: int) -> Array[Vector2i]:
	return rotate_cells(cells, rotation)


func clear() -> void:
	placed_pieces.clear()


func get_manifest_from_placed_pieces() -> Dictionary:
	var manifest := _empty_manifest()
	for placed_piece: Dictionary in placed_pieces.values():
		var material := String(placed_piece.get("material", ""))
		if manifest.has(material):
			manifest[material] += int(placed_piece.get("payload_units", 0))
	return manifest


func get_placed_payload() -> int:
	var total := 0
	for placed_piece: Dictionary in placed_pieces.values():
		total += int(placed_piece.get("payload_units", 0))
	return total


func get_occupied_cells(cells: Array[Vector2i], origin: Vector2i, rotation: int = 0) -> Array[Vector2i]:
	var rotated_cells := rotate_cells(cells, rotation)
	var occupied_cells: Array[Vector2i] = []
	for cell: Vector2i in rotated_cells:
		occupied_cells.append(origin + cell)
	return occupied_cells


static func rotate_cells(cells: Array[Vector2i], rotation: int) -> Array[Vector2i]:
	var normalized_rotation := _normalize_rotation(rotation)
	var rotated: Array[Vector2i] = []
	for cell: Vector2i in cells:
		match normalized_rotation:
			0:
				rotated.append(cell)
			90:
				rotated.append(Vector2i(-cell.y, cell.x))
			180:
				rotated.append(Vector2i(-cell.x, -cell.y))
			270:
				rotated.append(Vector2i(cell.y, -cell.x))
	return _normalize_cells_to_origin(rotated)


static func _normalize_rotation(rotation: int) -> int:
	var normalized := rotation % 360
	if normalized < 0:
		normalized += 360
	if not [0, 90, 180, 270].has(normalized):
		normalized = 0
	return normalized


static func _normalize_cells_to_origin(cells: Array[Vector2i]) -> Array[Vector2i]:
	if cells.is_empty():
		var empty_cells: Array[Vector2i] = []
		return empty_cells

	var min_x := cells[0].x
	var min_y := cells[0].y
	for cell: Vector2i in cells:
		min_x = mini(min_x, cell.x)
		min_y = mini(min_y, cell.y)

	var normalized: Array[Vector2i] = []
	for cell: Vector2i in cells:
		normalized.append(Vector2i(cell.x - min_x, cell.y - min_y))
	return normalized


func _is_in_bounds(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < width and cell.y < height


func _is_cell_occupied_by_other_piece(cell: Vector2i, ignored_instance_id: String) -> bool:
	for placed_piece: Dictionary in placed_pieces.values():
		if String(placed_piece.get("instance_id", "")) == ignored_instance_id:
			continue
		var occupied_cells: Array = placed_piece.get("occupied_cells", [])
		if occupied_cells.has(cell):
			return true
	return false


func _empty_manifest() -> Dictionary:
	var manifest := {}
	for material: String in GameDataScript.MATERIALS:
		manifest[material] = 0
	return manifest

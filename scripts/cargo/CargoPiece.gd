extends RefCounted
class_name CargoPiece

const CELL_PAYLOAD_UNITS := 10

var instance_id := ""
var shape_id := ""
var display_name := ""
var cells: Array[Vector2i] = []
var material := ""


func setup(piece_instance_id: String, piece_shape_id: String, piece_display_name: String, piece_cells: Array, assigned_material: String = "") -> void:
	instance_id = piece_instance_id
	shape_id = piece_shape_id
	display_name = piece_display_name
	cells = _to_vector2i_array(piece_cells)
	material = assigned_material


func duplicate_piece() -> CargoPiece:
	var piece := CargoPiece.new()
	piece.setup(instance_id, shape_id, display_name, cells, material)
	return piece


func get_cell_count() -> int:
	return cells.size()


func get_payload_units() -> int:
	return get_cell_count() * CELL_PAYLOAD_UNITS


func has_material() -> bool:
	return material != ""


func get_preview_size() -> Vector2i:
	if cells.is_empty():
		return Vector2i.ZERO

	var max_x := cells[0].x
	var max_y := cells[0].y
	for cell: Vector2i in cells:
		max_x = maxi(max_x, cell.x)
		max_y = maxi(max_y, cell.y)
	return Vector2i(max_x + 1, max_y + 1)


func get_preview_rows(filled_cell: String = "#", empty_cell: String = ".") -> Array[String]:
	var size := get_preview_size()
	var rows: Array[String] = []
	for y in range(size.y):
		var row := ""
		for x in range(size.x):
			row += filled_cell if cells.has(Vector2i(x, y)) else empty_cell
		rows.append(row)
	return rows


func get_preview_text(filled_cell: String = "#", empty_cell: String = ".") -> String:
	return "\n".join(get_preview_rows(filled_cell, empty_cell))


func to_assignment_dict() -> Dictionary:
	return {
		"instance_id": instance_id,
		"shape_id": shape_id,
		"display_name": display_name,
		"material": material,
		"cell_count": get_cell_count(),
		"payload_units": get_payload_units(),
		"preview_rows": get_preview_rows(),
	}


static func from_shape_definition(instance_id: String, definition: Dictionary, assigned_material: String = "") -> CargoPiece:
	var piece := CargoPiece.new()
	piece.setup(
		instance_id,
		String(definition.get("id", "")),
		String(definition.get("display_name", definition.get("id", ""))),
		definition.get("cells", []),
		assigned_material
	)
	return piece


static func build_instances_for_vehicle(vehicle_id: String, piece_set: Array) -> Array[CargoPiece]:
	var pieces: Array[CargoPiece] = []
	for definition: Dictionary in piece_set:
		var copies := int(definition.get("copies", 1))
		for copy_index in range(copies):
			var instance_id := "%s_%s_%02d" % [
				vehicle_id,
				String(definition.get("id", "piece")),
				copy_index + 1,
			]
			pieces.append(from_shape_definition(instance_id, definition))
	return pieces


static func _to_vector2i_array(raw_cells: Array) -> Array[Vector2i]:
	var converted: Array[Vector2i] = []
	for cell in raw_cells:
		converted.append(Vector2i(cell))
	return converted

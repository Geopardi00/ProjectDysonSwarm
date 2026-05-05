extends RefCounted
class_name CargoAssignment

const GameDataScript := preload("res://scripts/data/GameData.gd")
const CargoPieceScript := preload("res://scripts/cargo/CargoPiece.gd")
const CargoPackingStateScript := preload("res://scripts/cargo/CargoPackingState.gd")

var vehicle_id := ""
var vehicle: Dictionary = {}
var available_pieces: Array[CargoPiece] = []
var assigned_pieces: Dictionary = {}
var locked := false


func setup(selected_vehicle_id: String) -> void:
	vehicle_id = selected_vehicle_id
	vehicle = GameDataScript.get_vehicle(vehicle_id)
	available_pieces = CargoPieceScript.build_instances_for_vehicle(vehicle_id, GameDataScript.get_piece_set(vehicle_id))
	assigned_pieces.clear()
	locked = false


func assign_material(instance_id: String, material: String) -> bool:
	if locked:
		return false
	if not GameDataScript.MATERIALS.has(material):
		return false

	var piece := _find_available_piece(instance_id)
	if piece == null:
		return false

	var previous_piece := assigned_pieces.get(instance_id, null) as CargoPiece
	var previous_payload := previous_piece.get_payload_units() if previous_piece != null else 0
	var next_payload := get_assigned_payload() - previous_payload + piece.get_payload_units()
	if next_payload > int(vehicle.get("max_payload", 0)):
		return false

	var assigned_copy: CargoPiece = piece.duplicate_piece()
	assigned_copy.material = material
	assigned_pieces[instance_id] = assigned_copy
	return true


func unassign_piece(instance_id: String) -> bool:
	if locked:
		return false
	return assigned_pieces.erase(instance_id)


func reset_assignments() -> bool:
	if locked:
		return false
	assigned_pieces.clear()
	return true


func confirm_assignments() -> Array[CargoPiece]:
	locked = true
	return get_assigned_pieces()


func create_packing_state() -> CargoPackingState:
	var packing_state: CargoPackingState = CargoPackingStateScript.new()
	packing_state.setup(vehicle_id, confirm_assignments())
	return packing_state


func get_available_pieces() -> Array[CargoPiece]:
	var pieces: Array[CargoPiece] = []
	for piece: CargoPiece in available_pieces:
		pieces.append(piece.duplicate_piece())
	return pieces


func get_assigned_pieces() -> Array[CargoPiece]:
	var pieces: Array[CargoPiece] = []
	for piece: CargoPiece in assigned_pieces.values():
		pieces.append(piece.duplicate_piece())
	return pieces


func get_assigned_piece(instance_id: String) -> CargoPiece:
	var piece := assigned_pieces.get(instance_id, null) as CargoPiece
	return piece.duplicate_piece() if piece != null else null


func get_assigned_payload() -> int:
	var total := 0
	for piece: CargoPiece in assigned_pieces.values():
		total += piece.get_payload_units()
	return total


func get_assigned_fuel() -> int:
	var total := 0
	for piece: CargoPiece in assigned_pieces.values():
		if piece.material == GameDataScript.MATERIAL_FUEL:
			total += piece.get_payload_units()
	return total


func get_assigned_amount_for_material(material: String) -> int:
	var total := 0
	for piece: CargoPiece in assigned_pieces.values():
		if piece.material == material:
			total += piece.get_payload_units()
	return total


func can_confirm() -> bool:
	return not locked and assigned_pieces.size() > 0


func _find_available_piece(instance_id: String) -> CargoPiece:
	for piece: CargoPiece in available_pieces:
		if piece.instance_id == instance_id:
			return piece
	return null

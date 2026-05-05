extends RefCounted
class_name GameData

const MATERIAL_FUEL := "fuel"

const MATERIALS := [
	"fuel",
	"carbon_metals",
	"silicon",
	"copper",
	"electronics",
	"rare_metals",
	"propellant",
]

const CONSTRUCTION_MATERIALS := [
	"carbon_metals",
	"silicon",
	"copper",
	"electronics",
	"rare_metals",
	"propellant",
]

const VEHICLES := {
	"big_rocket": {
		"id": "big_rocket",
		"display_name": "Big Rocket",
		"grid_width": 5,
		"grid_height": 10,
		"max_payload": 500,
		"required_fuel": 200,
		"launch_days": 30,
	},
	"space_shuttle": {
		"id": "space_shuttle",
		"display_name": "Space Shuttle",
		"grid_width": 4,
		"grid_height": 8,
		"max_payload": 320,
		"required_fuel": 120,
		"launch_days": 20,
	},
	"spinlaunch": {
		"id": "spinlaunch",
		"display_name": "SpinLaunch",
		"grid_width": 1,
		"grid_height": 2,
		"max_payload": 20,
		"required_fuel": 0,
		"launch_days": 5,
	},
}

const CARGO_PIECE_SETS := {
	"big_rocket": [
		{
			"id": "br_p_block_5",
			"display_name": "P Block Hook",
			"cells": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(0, 2)],
			"copies": 2,
		},
		{
			"id": "br_corner_block",
			"display_name": "Corner Block",
			"cells": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1)],
			"copies": 2,
		},
		{
			"id": "br_tall_hook_5",
			"display_name": "Tall Hook",
			"cells": [Vector2i(1, 0), Vector2i(1, 1), Vector2i(0, 2), Vector2i(1, 2), Vector2i(1, 3)],
			"copies": 2,
		},
		{
			"id": "br_square_4",
			"display_name": "Square Block",
			"cells": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)],
			"copies": 2,
		},
		{
			"id": "br_offset_cross",
			"display_name": "Offset Cross",
			"cells": [Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(1, 2), Vector2i(2, 2), Vector2i(1, 3)],
			"copies": 2,
		},
		{
			"id": "br_wide_hook",
			"display_name": "Wide Hook",
			"cells": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0), Vector2i(2, 1)],
			"copies": 2,
		},
		{
			"id": "br_double_hook",
			"display_name": "Double Hook",
			"cells": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1), Vector2i(0, 2), Vector2i(1, 2), Vector2i(1, 3)],
			"copies": 2,
		},
		{
			"id": "br_c_block",
			"display_name": "C Block",
			"cells": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(0, 2), Vector2i(1, 2)],
			"copies": 2,
		},
		{
			"id": "br_offset_step",
			"display_name": "Offset Step",
			"cells": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(2, 1), Vector2i(3, 1)],
			"copies": 2,
		},
		{
			"id": "br_t_block",
			"display_name": "T Block",
			"cells": [Vector2i(2, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1), Vector2i(3, 1), Vector2i(4, 1)],
			"copies": 2,
		},
	],
	"space_shuttle": [
		{
			"id": "ss_domino_2",
			"display_name": "Domino",
			"cells": [Vector2i(0, 0), Vector2i(1, 0)],
			"copies": 2,
		},
		{
			"id": "ss_corner_left_3",
			"display_name": "Left Corner",
			"cells": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1)],
			"copies": 2,
		},
		{
			"id": "ss_corner_right_3",
			"display_name": "Right Corner",
			"cells": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1)],
			"copies": 2,
		},
		{
			"id": "ss_c_frame_5",
			"display_name": "C Frame",
			"cells": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(0, 2), Vector2i(1, 2)],
			"copies": 2,
		},
		{
			"id": "ss_z_column_4",
			"display_name": "Z Column",
			"cells": [Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(0, 2)],
			"copies": 2,
		},
		{
			"id": "ss_square_4",
			"display_name": "Square Block",
			"cells": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)],
			"copies": 2,
		},
		{
			"id": "ss_s_step_4",
			"display_name": "S Step",
			"cells": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1), Vector2i(2, 1)],
			"copies": 2,
		},
		{
			"id": "ss_l_foot_4",
			"display_name": "L Foot",
			"cells": [Vector2i(0, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1)],
			"copies": 2,
		},
	],
	"spinlaunch": [
		{
			"id": "sl_capsule_2",
			"display_name": "Launch Capsule",
			"cells": [Vector2i(0, 0), Vector2i(0, 1)],
			"copies": 1,
		},
	],
}

const MOONBASE_REQUIREMENTS := {
	"carbon_metals": 320,
	"silicon": 220,
	"copper": 140,
	"electronics": 90,
	"rare_metals": 70,
	"propellant": 60,
}

const FACTIONS := {
	"USA": {
		"display_name": "USA",
		"speed_per_day": 0.85,
		"crash_chance": 0.12,
		"news_style": "powerful_but_risky",
	},
	"China": {
		"display_name": "China",
		"speed_per_day": 0.95,
		"crash_chance": 0.10,
		"news_style": "fast_aggressive",
	},
	"EU": {
		"display_name": "EU",
		"speed_per_day": 0.75,
		"crash_chance": 0.06,
		"news_style": "steady_careful",
	},
}

const TEST_MANIFESTS := {
	"big_rocket_success": {
		"fuel": 200,
		"carbon_metals": 120,
		"silicon": 80,
		"copper": 40,
		"electronics": 30,
		"rare_metals": 20,
		"propellant": 10,
	},
	"shuttle_success": {
		"fuel": 120,
		"carbon_metals": 70,
		"silicon": 50,
		"copper": 30,
		"electronics": 20,
		"rare_metals": 20,
		"propellant": 10,
	},
	"failed_rocket": {
		"fuel": 100,
		"carbon_metals": 160,
		"silicon": 90,
		"copper": 60,
		"electronics": 40,
		"rare_metals": 30,
		"propellant": 20,
	},
	"spinlaunch": {
		"fuel": 0,
		"carbon_metals": 0,
		"silicon": 0,
		"copper": 20,
		"electronics": 0,
		"rare_metals": 0,
		"propellant": 0,
	},
}

static func get_vehicle(vehicle_id: String) -> Dictionary:
	return VEHICLES.get(vehicle_id, {}).duplicate(true)


static func get_test_manifest(manifest_id: String) -> Dictionary:
	return TEST_MANIFESTS.get(manifest_id, {}).duplicate(true)


static func get_piece_set(vehicle_id: String) -> Array:
	return CARGO_PIECE_SETS.get(vehicle_id, []).duplicate(true)


static func get_piece_set_preview_data(vehicle_id: String, filled_cell: String = "#", empty_cell: String = ".") -> Array[Dictionary]:
	var previews: Array[Dictionary] = []
	for definition: Dictionary in get_piece_set(vehicle_id):
		var cells := _to_vector2i_array(definition.get("cells", []))
		var cell_count := cells.size()
		previews.append({
			"id": String(definition.get("id", "")),
			"display_name": String(definition.get("display_name", definition.get("id", ""))),
			"cells": cells,
			"copies": int(definition.get("copies", 1)),
			"cell_count": cell_count,
			"payload_units": cell_count * 10,
			"preview_rows": _get_preview_rows(cells, filled_cell, empty_cell),
		})
	return previews


static func get_cpu_faction_ids(player_faction: String) -> Array[String]:
	var cpu_ids: Array[String] = []
	for faction_id: String in FACTIONS.keys():
		if faction_id != player_faction:
			cpu_ids.append(faction_id)
	return cpu_ids


static func _get_preview_rows(cells: Array[Vector2i], filled_cell: String, empty_cell: String) -> Array[String]:
	var size := _get_preview_size(cells)
	var rows: Array[String] = []
	for y in range(size.y):
		var row := ""
		for x in range(size.x):
			row += filled_cell if cells.has(Vector2i(x, y)) else empty_cell
		rows.append(row)
	return rows


static func _get_preview_size(cells: Array[Vector2i]) -> Vector2i:
	if cells.is_empty():
		return Vector2i.ZERO

	var max_x := cells[0].x
	var max_y := cells[0].y
	for cell: Vector2i in cells:
		max_x = maxi(max_x, cell.x)
		max_y = maxi(max_y, cell.y)
	return Vector2i(max_x + 1, max_y + 1)


static func _to_vector2i_array(raw_cells: Array) -> Array[Vector2i]:
	var converted: Array[Vector2i] = []
	for cell in raw_cells:
		converted.append(Vector2i(cell))
	return converted

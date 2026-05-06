extends RefCounted
class_name UiAssets

const BACKGROUND := "res://assets/ui/backgrounds/ui_bg_space_loading_1920x1080.png"

const VEHICLE_ICONS := {
	"big_rocket": "res://assets/ui/vehicles/big_rocket_icon.png",
	"space_shuttle": "res://assets/ui/vehicles/space_shuttle_icon.png",
	"spinlaunch": "res://assets/ui/vehicles/spinlaunch_icon.png",
}

const FACTION_LOGOS := {
	"USA": "res://assets/ui/factions/usa_logo.png",
	"China": "res://assets/ui/factions/china_logo.png",
	"EU": "res://assets/ui/factions/eu_logo.png",
}

const MATERIAL_ICONS := {
	"fuel": "res://assets/ui/materials/fuel_icon.png",
	"carbon_metals": "res://assets/ui/materials/carbon_metals_icon.png",
	"silicon": "res://assets/ui/materials/silicon_icon.png",
	"copper": "res://assets/ui/materials/copper_icon.png",
	"electronics": "res://assets/ui/materials/electronics_icon.png",
	"rare_metals": "res://assets/ui/materials/rare_materials_icon.png",
	"propellant": "res://assets/ui/materials/propellant_icon.png",
}

const PANEL_FRAMES := {
	"vehicle_info": "res://assets/ui/panels/panel_vehicle_info_frame.png",
	"available_cargo": "res://assets/ui/panels/panel_available_cargo_frame.png",
	"cargo_hold": "res://assets/ui/panels/panel_cargo_hold.png",
}

const BIG_ROCKET_PIECES := {
	"br_p_block_5": "res://assets/ui/cargo_pieces/big_rocket/p_block_hook.png",
	"br_corner_block": "res://assets/ui/cargo_pieces/big_rocket/corner_block.png",
	"br_tall_hook_5": "res://assets/ui/cargo_pieces/big_rocket/tall_hook.png",
	"br_square_4": "res://assets/ui/cargo_pieces/big_rocket/square_block.png",
	"br_offset_cross": "res://assets/ui/cargo_pieces/big_rocket/offset_cross.png",
	"br_wide_hook": "res://assets/ui/cargo_pieces/big_rocket/wide_hook.png",
	"br_double_hook": "res://assets/ui/cargo_pieces/big_rocket/double_hook.png",
	"br_c_block": "res://assets/ui/cargo_pieces/big_rocket/c_block.png",
	"br_offset_step": "res://assets/ui/cargo_pieces/big_rocket/offset_step.png",
	"br_t_block": "res://assets/ui/cargo_pieces/big_rocket/t_block.png",
}

const SHUTTLE_PIECES := {
	"ss_c_block_5": "res://assets/ui/cargo_pieces/space_shuttle/c_block.png",
	"ss_i_block_3": "res://assets/ui/cargo_pieces/space_shuttle/i_block.png",
	"ss_t_block_4": "res://assets/ui/cargo_pieces/space_shuttle/little_t_block.png",
	"ss_square_block_4": "res://assets/ui/cargo_pieces/space_shuttle/square_block.png",
	"ss_p_block_5": "res://assets/ui/cargo_pieces/space_shuttle/p_block_hook.png",
	"ss_l_block_4": "res://assets/ui/cargo_pieces/space_shuttle/l_block_hook.png",
	"ss_step_block_4": "res://assets/ui/cargo_pieces/space_shuttle/step_block.png",
	"ss_corner_block_3": "res://assets/ui/cargo_pieces/space_shuttle/corner_block.png",
}

const SPINLAUNCH_PIECES := {
	"sl_capsule_2": "res://assets/ui/cargo_pieces/spinlaunch/spinlaunch_block.png",
}


static func get_texture(path: String) -> Texture2D:
	if path == "" or not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D


static func get_background() -> Texture2D:
	return get_texture(BACKGROUND)


static func get_vehicle_icon(vehicle_id: String) -> Texture2D:
	return get_texture(String(VEHICLE_ICONS.get(vehicle_id, "")))


static func get_faction_logo(faction_id: String) -> Texture2D:
	return get_texture(String(FACTION_LOGOS.get(faction_id, "")))


static func get_material_icon(material: String) -> Texture2D:
	return get_texture(String(MATERIAL_ICONS.get(material, "")))


static func get_panel_frame(frame_id: String) -> Texture2D:
	return get_texture(String(PANEL_FRAMES.get(frame_id, "")))


static func get_cargo_piece_texture(shape_id: String) -> Texture2D:
	if BIG_ROCKET_PIECES.has(shape_id):
		return get_texture(String(BIG_ROCKET_PIECES[shape_id]))
	if SHUTTLE_PIECES.has(shape_id):
		return get_texture(String(SHUTTLE_PIECES[shape_id]))
	if SPINLAUNCH_PIECES.has(shape_id):
		return get_texture(String(SPINLAUNCH_PIECES[shape_id]))
	return null


static func apply_text_outline(node: Node, outline_size: int = 4) -> void:
	if node is Label or node is Button:
		var control := node as Control
		control.add_theme_color_override("font_color", Color.WHITE)
		control.add_theme_color_override("font_outline_color", Color.BLACK)
		control.add_theme_constant_override("outline_size", outline_size)
	for child: Node in node.get_children():
		apply_text_outline(child, outline_size)

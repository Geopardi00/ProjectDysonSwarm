extends Control
class_name LogoAssemblyIntro

## Boot intro: the title logo is cut into cargo-style blocks that fly up from
## Earth, lock into place, and turn into the real logo art. The final frame is
## the opening screen itself, so the intro hands off without a cut.

signal finished

const SHINE_SHADER := preload("res://assets/shaders/title_shine.gdshader")
const LAND_SOUND := preload("res://audio/sfx/button_click.wav")
const LOCK_SOUND := preload("res://audio/sfx/explosion.wav")
const SFX_BUS_NAME := &"SFX"
# Steel tones taken from the logo lettering, with the logo's orange as an accent.
const BLOCK_COLORS: Array[Color] = [
	Color("#3A4F68"),
	Color("#4A6482"),
	Color("#2E405A"),
	Color("#5C7896"),
	Color("#3A4F68"),
	Color("#4A6482"),
	Color("#E07A2A"),
]

@export_category("Pieces")
@export_range(12, 80, 1, "suffix:px") var cell_texture_size := 30
@export_range(0.0, 0.5, 0.01) var min_cell_coverage := 0.06
@export_range(2, 8, 1) var min_piece_cells := 3
@export_range(2, 8, 1) var max_piece_cells := 5
@export var piece_seed := 1969

@export_category("Timing")
@export_range(0.0, 3.0, 0.05, "suffix:s") var fade_in_duration := 0.7
@export_range(0.0, 3.0, 0.05, "suffix:s") var assembly_start := 0.35
@export_range(0.1, 5.0, 0.05, "suffix:s") var assembly_spread := 2.0
@export_range(0.0, 1.0, 0.01, "suffix:s") var start_jitter := 0.15
@export_range(0.1, 2.0, 0.05, "suffix:s") var flight_duration := 0.6
@export_range(0.0, 1.0, 0.01, "suffix:s") var flash_duration := 0.12
@export_range(0.05, 2.0, 0.05, "suffix:s") var reveal_duration := 0.35
@export_range(0.1, 3.0, 0.05, "suffix:s") var shine_duration := 0.7
@export_range(0.0, 2.0, 0.05, "suffix:s") var menu_delay := 0.35
@export_range(0.05, 2.0, 0.05, "suffix:s") var menu_fade_duration := 0.5

@export_category("Motion")
@export_range(0.0, 1500.0, 10.0, "suffix:px") var launch_distance_min := 650.0
@export_range(0.0, 1500.0, 10.0, "suffix:px") var launch_distance_max := 900.0
@export_range(0.0, 800.0, 10.0, "suffix:px") var launch_spread := 260.0
@export_range(1.0, 1.2, 0.005) var lock_punch_scale := 1.035

@export_category("Sound")
@export_range(-40.0, 6.0, 0.5, "suffix:dB") var land_volume_db := -12.0
@export_range(0.0, 0.2, 0.005, "suffix:s") var land_sound_min_gap := 0.045
@export_range(-40.0, 6.0, 0.5, "suffix:dB") var lock_volume_db := -6.0
@export_range(0.1, 6.0, 0.1, "suffix:s") var lock_sound_length := 1.6

var _logo_texture: Texture2D
var _logo_rect := Rect2()
var _title_logo: TextureRect
var _menu: Control
var _backlight: Control
var _pieces: Array[IntroPiece] = []
var _elapsed := 0.0
var _playing := false
var _locked := false
var _lock_time := 0.0
var _menu_started := false
var _done := false
var _last_land_sound_time := -1.0
var _black: ColorRect
var _land_player: AudioStreamPlayer
var _lock_player: AudioStreamPlayer
var _shine_material: ShaderMaterial


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_black = ColorRect.new()
	_black.name = "FadeFromBlack"
	_black.color = Color.BLACK
	_black.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_black)
	_black.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	_land_player = AudioStreamPlayer.new()
	_land_player.stream = LAND_SOUND
	_land_player.bus = SFX_BUS_NAME
	_land_player.max_polyphony = 6
	_land_player.volume_db = land_volume_db
	add_child(_land_player)

	_lock_player = AudioStreamPlayer.new()
	_lock_player.stream = LOCK_SOUND
	_lock_player.bus = SFX_BUS_NAME
	_lock_player.volume_db = lock_volume_db
	add_child(_lock_player)


## Hides the title screen pieces this intro reveals. Call right after adding the
## intro so the menu never flashes before the first frame.
func hide_targets(title_logo: TextureRect, menu: Control, backlight: Control) -> void:
	_title_logo = title_logo
	_menu = menu
	_backlight = backlight
	if is_instance_valid(_title_logo):
		_title_logo.modulate.a = 0.0
	if is_instance_valid(_menu):
		_menu.modulate.a = 0.0
	if is_instance_valid(_backlight):
		_backlight.modulate.a = 0.0


## Starts the sequence once the title logo has its final layout.
func play() -> void:
	if not is_instance_valid(_title_logo) or _title_logo.texture == null:
		_finish()
		return
	_logo_texture = _title_logo.texture
	_logo_rect = _get_drawn_texture_rect(_title_logo)
	_build_pieces()
	_elapsed = 0.0
	_playing = true


func skip() -> void:
	if _done:
		return
	_playing = false
	for piece: IntroPiece in _pieces:
		piece.queue_free()
	_pieces.clear()
	_black.visible = false
	if _lock_player.playing:
		_lock_player.stop()
	_restore_targets()
	_finish()


func is_playing() -> bool:
	return _playing


func _input(event: InputEvent) -> void:
	if _done:
		return
	var wants_skip: bool = (
		(event is InputEventKey and event.pressed and not event.echo)
		or (event is InputEventMouseButton and event.pressed)
		or (event is InputEventJoypadButton and event.pressed)
	)
	if wants_skip:
		get_viewport().set_input_as_handled()
		skip()


func _process(delta: float) -> void:
	if not _playing:
		return
	_elapsed += delta
	_black.color.a = 1.0 - _smooth(_elapsed / maxf(fade_in_duration, 0.001))

	var all_revealed := true
	for piece: IntroPiece in _pieces:
		var landed_before := piece.landed
		piece.update_motion(_elapsed, flight_duration, flash_duration, reveal_duration)
		if piece.landed and not landed_before:
			_play_land_sound()
		if piece.reveal < 1.0:
			all_revealed = false

	if not _locked and all_revealed:
		_lock_logo()
	if _locked and not _menu_started and _elapsed >= _lock_time + menu_delay:
		_start_menu_fade()
	if _locked and _elapsed >= _lock_time + maxf(shine_duration, menu_delay + menu_fade_duration):
		_playing = false
		_restore_targets()
		_finish()


func _lock_logo() -> void:
	_locked = true
	_lock_time = _elapsed
	for piece: IntroPiece in _pieces:
		piece.queue_free()
	_pieces.clear()
	if not is_instance_valid(_title_logo):
		return
	_title_logo.modulate.a = 1.0
	_shine_material = ShaderMaterial.new()
	_shine_material.shader = SHINE_SHADER
	_shine_material.set_shader_parameter("progress", -0.3)
	_title_logo.material = _shine_material
	var tween := _title_logo.create_tween()
	tween.tween_method(_set_shine_progress, -0.3, 1.3, shine_duration)
	_title_logo.pivot_offset = _title_logo.size * 0.5
	_title_logo.scale = Vector2.ONE * lock_punch_scale
	var punch := _title_logo.create_tween()
	punch.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	punch.tween_property(_title_logo, "scale", Vector2.ONE, 0.45)
	if is_instance_valid(_backlight):
		var glow := _backlight.create_tween()
		glow.tween_property(_backlight, "modulate:a", 1.0, 0.6)
	_lock_player.volume_db = lock_volume_db
	_lock_player.play()
	var fade := _lock_player.create_tween()
	fade.tween_interval(lock_sound_length * 0.4)
	fade.tween_property(_lock_player, "volume_db", -60.0, lock_sound_length * 0.6)
	fade.tween_callback(_lock_player.stop)


func _set_shine_progress(value: float) -> void:
	if _shine_material != null:
		_shine_material.set_shader_parameter("progress", value)


func _start_menu_fade() -> void:
	_menu_started = true
	if not is_instance_valid(_menu):
		return
	var tween := _menu.create_tween()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(_menu, "modulate:a", 1.0, menu_fade_duration)


func _restore_targets() -> void:
	if is_instance_valid(_title_logo):
		_title_logo.modulate.a = 1.0
		_title_logo.scale = Vector2.ONE
		_title_logo.material = null
	if is_instance_valid(_menu):
		_menu.modulate.a = 1.0
	if is_instance_valid(_backlight):
		_backlight.modulate.a = 1.0
	_shine_material = null


func _finish() -> void:
	if _done:
		return
	_done = true
	finished.emit()
	queue_free()


func _play_land_sound() -> void:
	if _elapsed - _last_land_sound_time < land_sound_min_gap:
		return
	_last_land_sound_time = _elapsed
	_land_player.pitch_scale = randf_range(0.85, 1.2)
	_land_player.play()


func _get_drawn_texture_rect(texture_rect: TextureRect) -> Rect2:
	var rect := texture_rect.get_global_rect()
	var origin := rect.position - get_global_rect().position
	var texture_size := texture_rect.texture.get_size()
	var fit := minf(rect.size.x / texture_size.x, rect.size.y / texture_size.y)
	var drawn_size := texture_size * fit
	return Rect2(origin + (rect.size - drawn_size) * 0.5, drawn_size)


func _build_pieces() -> void:
	var image := _logo_texture.get_image()
	if image == null:
		return
	if image.is_compressed():
		image.decompress()
	var texture_size := Vector2i(image.get_width(), image.get_height())
	var cols := ceili(float(texture_size.x) / cell_texture_size)
	var rows := ceili(float(texture_size.y) / cell_texture_size)
	var occupied := {}
	for row: int in rows:
		for col: int in cols:
			if _cell_coverage(image, col, row) >= min_cell_coverage:
				occupied[Vector2i(col, row)] = true

	var rng := RandomNumberGenerator.new()
	rng.seed = piece_seed
	var groups := _partition_cells(occupied, rng)
	var screen_scale := _logo_rect.size.x / float(texture_size.x)
	var cell_screen_size := float(cell_texture_size) * screen_scale
	var min_x := _logo_rect.position.x
	var width := maxf(_logo_rect.size.x, 1.0)

	for cells: Array in groups:
		var piece := IntroPiece.new()
		piece.texture = _logo_texture
		piece.cell_texture_size = cell_texture_size
		piece.cell_screen_size = cell_screen_size
		piece.texture_size = Vector2(texture_size)
		piece.block_color = BLOCK_COLORS[rng.randi_range(0, BLOCK_COLORS.size() - 1)]
		piece.set_cells(cells, _logo_rect.position)
		var progress := clampf((piece.target_position.x - min_x) / width, 0.0, 1.0)
		piece.start_time = assembly_start + progress * assembly_spread + rng.randf() * start_jitter
		piece.start_position = piece.target_position + Vector2(
			rng.randf_range(-launch_spread, launch_spread),
			rng.randf_range(launch_distance_min, launch_distance_max)
		)
		piece.start_rotation = float(rng.randi_range(1, 3)) * PI * 0.5 * (1.0 if rng.randf() < 0.5 else -1.0)
		add_child(piece)
		_pieces.append(piece)
		piece.update_motion(0.0, flight_duration, flash_duration, reveal_duration)


func _cell_coverage(image: Image, col: int, row: int) -> float:
	const STEP := 3
	var x0 := col * cell_texture_size
	var y0 := row * cell_texture_size
	var x1 := mini(x0 + cell_texture_size, image.get_width())
	var y1 := mini(y0 + cell_texture_size, image.get_height())
	var samples := 0
	var covered := 0
	for y: int in range(y0, y1, STEP):
		for x: int in range(x0, x1, STEP):
			samples += 1
			if image.get_pixel(x, y).a > 0.35:
				covered += 1
	return 0.0 if samples == 0 else float(covered) / float(samples)


## Splits the occupied cells into connected polyomino groups, sweeping left to
## right like cargo being packed.
func _partition_cells(occupied: Dictionary, rng: RandomNumberGenerator) -> Array:
	var cells: Array = occupied.keys()
	cells.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return a.x < b.x or (a.x == b.x and a.y < b.y))
	var owner := {}
	var groups: Array = []
	for seed_cell: Vector2i in cells:
		if owner.has(seed_cell):
			continue
		var group: Array = [seed_cell]
		owner[seed_cell] = groups.size()
		var target := rng.randi_range(min_piece_cells, maxi(min_piece_cells, max_piece_cells))
		while group.size() < target:
			var candidates: Array = []
			for cell: Vector2i in group:
				for neighbor: Vector2i in _neighbors(cell):
					if occupied.has(neighbor) and not owner.has(neighbor) and not candidates.has(neighbor):
						candidates.append(neighbor)
			if candidates.is_empty():
				break
			var chosen: Vector2i = candidates[rng.randi_range(0, candidates.size() - 1)]
			owner[chosen] = groups.size()
			group.append(chosen)
		groups.append(group)

	# Fold tiny leftovers into a neighbouring piece so no single specks fly in.
	for index: int in groups.size():
		var group: Array = groups[index]
		if group.is_empty() or group.size() >= 2:
			continue
		for neighbor: Vector2i in _neighbors(group[0]):
			if owner.has(neighbor) and owner[neighbor] != index:
				var into: int = owner[neighbor]
				groups[into].append(group[0])
				owner[group[0]] = into
				group.clear()
				break
	return groups.filter(func(group: Array) -> bool: return not group.is_empty())


func _neighbors(cell: Vector2i) -> Array[Vector2i]:
	return [cell + Vector2i.LEFT, cell + Vector2i.RIGHT, cell + Vector2i.UP, cell + Vector2i.DOWN]


static func _smooth(t: float) -> float:
	var x := clampf(t, 0.0, 1.0)
	return x * x * (3.0 - 2.0 * x)


class IntroPiece:
	extends Control

	var texture: Texture2D
	var texture_size := Vector2.ZERO
	var cell_texture_size := 30
	var cell_screen_size := 20.0
	var block_color := Color.GRAY
	var cells: Array = []
	var target_position := Vector2.ZERO
	var start_position := Vector2.ZERO
	var start_rotation := 0.0
	var start_time := 0.0
	var flash := 0.0
	var reveal := 0.0
	var landed := false
	var _local_offsets: Array[Vector2] = []

	func set_cells(piece_cells: Array, logo_origin: Vector2) -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		cells = piece_cells
		var center := Vector2.ZERO
		for cell: Vector2i in cells:
			center += (Vector2(cell) + Vector2(0.5, 0.5)) * cell_screen_size
		center /= float(cells.size())
		target_position = logo_origin + center
		_local_offsets.clear()
		for cell: Vector2i in cells:
			_local_offsets.append(Vector2(cell) * cell_screen_size - center)

	func update_motion(elapsed: float, flight: float, flash_time: float, reveal_time: float) -> void:
		var t := (elapsed - start_time) / flight
		if t <= 0.0:
			visible = false
			return
		visible = true
		var eased := 1.0 - pow(1.0 - clampf(t, 0.0, 1.0), 4.0)
		position = start_position.lerp(target_position, eased)
		rotation = start_rotation * (1.0 - _ease_out_back(clampf(t, 0.0, 1.0)))
		modulate.a = clampf(t * 5.0, 0.0, 1.0)
		var since_land := elapsed - (start_time + flight)
		landed = since_land >= 0.0
		if landed:
			position = target_position
			rotation = 0.0
			flash = 1.0 - clampf(since_land / maxf(flash_time, 0.001), 0.0, 1.0)
			reveal = clampf((since_land - flash_time * 0.5) / reveal_time, 0.0, 1.0)
		queue_redraw()

	func _draw() -> void:
		var block := block_color.lerp(Color.WHITE, flash * 0.85)
		block.a = 1.0 - reveal
		var edge := block_color.lightened(0.45)
		edge.a = (1.0 - reveal) * 0.9
		for index: int in cells.size():
			var cell: Vector2i = cells[index]
			var rect := Rect2(_local_offsets[index], Vector2.ONE * cell_screen_size)
			var source := Rect2(Vector2(cell) * cell_texture_size, Vector2.ONE * cell_texture_size)
			source = source.intersection(Rect2(Vector2.ZERO, texture_size))
			if source.size.x <= 0.0 or source.size.y <= 0.0:
				continue
			var drawn := Rect2(rect.position, source.size * (cell_screen_size / cell_texture_size))
			if reveal > 0.0:
				draw_texture_rect_region(texture, drawn, source, Color(1.0, 1.0, 1.0, reveal))
			if reveal < 1.0:
				draw_rect(rect.grow(-1.0), block)
				draw_rect(rect.grow(-1.0), edge, false, 1.5)

	static func _ease_out_back(x: float) -> float:
		const C1 := 1.70158
		const C3 := C1 + 1.0
		return 1.0 + C3 * pow(x - 1.0, 3.0) + C1 * pow(x - 1.0, 2.0)

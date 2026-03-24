extends Control
## Сцена реставрации предмета.
## Управляет отображением предмета, слоями повреждений,
## рисованием маски при перетаскивании инструмента и определением завершения.

const DAMAGE_SHADER := preload("res://shaders/damage_reveal.gdshader")

# Размер текстуры предмета (и масок) — 128x128 для пиксель-арта
const ITEM_SIZE := Vector2i(128, 128)

# Размер отображения — фиксированный, совпадает с контейнером в workshop.tscn
const DISPLAY_SIZE := 526.0
var display_scale := Vector2(DISPLAY_SIZE / 128.0, DISPLAY_SIZE / 128.0)

# Текущий предмет
var item_data: ItemData = null

# Текущий выбранный инструмент
var current_tool: ToolData = null

# Маски и текстуры для каждого слоя повреждения
var mask_images: Dictionary = {}      # damage_type_id -> Image
var mask_textures: Dictionary = {}    # damage_type_id -> ImageTexture
var damage_sprites: Dictionary = {}   # damage_type_id -> Sprite2D
var damage_remaining: Dictionary = {} # damage_type_id -> float (0.0 - 1.0)

# Форма предмета (альфа-канал чистой текстуры) — для проверки где рисовать
var item_shape: Image = null

# Рисование
var last_drag_pos: Vector2 = Vector2.ZERO
var brush_stamp: Image = null

# Нода для отображения
@onready var clean_sprite: Sprite2D = $CleanSprite
@onready var damage_layer_container: Node2D = $DamageLayerContainer
@onready var progress_bar: ProgressBar = $ProgressBar
@onready var brush_preview: Node2D = $BrushPreview
@onready var item_area: Control = $ItemArea


func _ready() -> void:
	_create_brush_stamp(32)
	Events.tool_selected.connect(_on_tool_selected)
	# Auto-select the single tool if available
	if GameManager.all_tools.size() > 0:
		current_tool = GameManager.all_tools[0]


func setup_item(data: ItemData) -> void:
	item_data = data
	# Ensure tool is selected
	if current_tool == null and GameManager.all_tools.size() > 0:
		current_tool = GameManager.all_tools[0]


	# Очищаем предыдущие слои
	for child in damage_layer_container.get_children():
		child.queue_free()
	mask_images.clear()
	mask_textures.clear()
	damage_sprites.clear()
	damage_remaining.clear()

	# Создаём текстуру чистого предмета
	if data.clean_texture:
		clean_sprite.texture = data.clean_texture
	else:
		clean_sprite.texture = _generate_placeholder_clean_texture(data)

	# Извлекаем форму предмета (альфа-канал) для определения где рисовать
	item_shape = clean_sprite.texture.get_image()
	if item_shape.get_size() != Vector2i(ITEM_SIZE):
		item_shape.resize(ITEM_SIZE.x, ITEM_SIZE.y)

	# Центрируем и масштабируем предмет чтобы заполнить весь контейнер
	var center := Vector2(DISPLAY_SIZE, DISPLAY_SIZE) / 2.0
	clean_sprite.position = center
	clean_sprite.scale = display_scale

	# Создаём слои повреждений
	for layer: DamageLayer in data.damage_layers:
		_setup_damage_layer(layer)

	# Обновляем прогресс
	_update_progress()




func _setup_damage_layer(layer: DamageLayer) -> void:
	var damage_type := GameManager.get_damage_type(layer.damage_type_id)
	if damage_type == null:
		return

	# Создаём маску (белая = повреждено)
	var mask := Image.create(ITEM_SIZE.x, ITEM_SIZE.y, false, Image.FORMAT_L8)
	mask.fill(Color.WHITE)
	mask_images[layer.damage_type_id] = mask

	var mask_tex := ImageTexture.create_from_image(mask)
	mask_textures[layer.damage_type_id] = mask_tex

	# Создаём спрайт наложения повреждения
	var sprite := Sprite2D.new()
	var center := Vector2(DISPLAY_SIZE, DISPLAY_SIZE) / 2.0
	sprite.position = center
	sprite.scale = display_scale

	# Создаём текстуру повреждения (заглушка или из ресурса)
	if damage_type.overlay_texture:
		sprite.texture = damage_type.overlay_texture
	else:
		sprite.texture = _generate_placeholder_damage_texture(damage_type, layer.intensity)

	# Настраиваем шейдер
	var mat := ShaderMaterial.new()
	mat.shader = DAMAGE_SHADER
	mat.set_shader_parameter("mask_texture", mask_tex)
	mat.set_shader_parameter("item_shape_texture", clean_sprite.texture)
	mat.set_shader_parameter("intensity", layer.intensity)
	mat.set_shader_parameter("tint_color", damage_type.color)
	sprite.material = mat

	damage_layer_container.add_child(sprite)
	damage_sprites[layer.damage_type_id] = sprite
	damage_remaining[layer.damage_type_id] = 1.0


func _on_tool_selected(tool_data: ToolData) -> void:
	current_tool = tool_data
	_update_brush_preview()


var _mouse_inside: bool = false


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		brush_preview.position = event.position
		brush_preview.visible = current_tool != null

		if current_tool != null:
			if not _mouse_inside:
				# Первое движение после входа — запоминаем позицию, не рисуем
				_mouse_inside = true
				last_drag_pos = event.position
			else:
				var points := _interpolate_points(last_drag_pos, event.position)
				for point in points:
					_paint_at(point)
				last_drag_pos = event.position
			accept_event()


func _paint_at(pos: Vector2) -> void:
	if current_tool == null:
		return

	var radius := GameManager.get_tool_radius(current_tool)
	var strength := GameManager.get_tool_effectiveness(current_tool)

	# Масштабируем радиус кисти к координатам маски (экран -> маска)
	var mask_radius := maxi(int(float(radius) / display_scale.x), 2)
	_create_brush_stamp(mask_radius)

	# Конвертируем позицию экрана в координаты маски
	var mask_pos := Vector2i(Vector2(pos) / display_scale)

	# Пропускаем если курсор на прозрачной части (вне предмета)
	if item_shape:
		var cx := clampi(mask_pos.x, 0, ITEM_SIZE.x - 1)
		var cy := clampi(mask_pos.y, 0, ITEM_SIZE.y - 1)
		if item_shape.get_pixel(cx, cy).a < 0.1:
			return

	for damage_type_id: String in current_tool.effective_against:
		if damage_type_id not in mask_images:
			continue
		if damage_remaining.get(damage_type_id, 0.0) <= 0.0:
			continue

		var damage_type := GameManager.get_damage_type(damage_type_id)
		var resistance: float = damage_type.resistance if damage_type else 1.0

		# Получаем силу воздействия (с учётом сопротивления)
		var removal_power: float = strength / resistance
		if current_tool.ineffective_against.has(damage_type_id):
			removal_power *= 0.3

		var config := GameManager.economy_config as EconomyConfig
		var base_rate: float = config.base_removal_rate if config else 0.15

		_paint_mask(damage_type_id, mask_pos, mask_radius, removal_power * base_rate)

	_update_progress()
	_check_completion()


func _paint_mask(damage_type_id: String, center: Vector2i, radius: int, removal_rate: float) -> void:
	var mask: Image = mask_images[damage_type_id]
	var stamp_size := brush_stamp.get_size()
	var dst := center - Vector2i(stamp_size) / 2

	for x in range(stamp_size.x):
		for y in range(stamp_size.y):
			var mx := dst.x + x
			var my := dst.y + y
			if mx < 0 or my < 0 or mx >= mask.get_width() or my >= mask.get_height():
				continue
			# Пропускаем прозрачные пиксели (вне формы предмета)
			if item_shape and item_shape.get_pixel(mx, my).a < 0.1:
				continue
			var current_val := mask.get_pixel(mx, my).r
			var brush_val := brush_stamp.get_pixel(x, y).r
			var new_val := maxf(current_val - brush_val * removal_rate, 0.0)
			mask.set_pixel(mx, my, Color(new_val, new_val, new_val, 1.0))

	mask_textures[damage_type_id].update(mask)


func _create_brush_stamp(radius: int) -> void:
	var size := radius * 2
	if brush_stamp and brush_stamp.get_width() == size:
		return
	brush_stamp = Image.create(size, size, false, Image.FORMAT_L8)
	for x in range(size):
		for y in range(size):
			var dist := Vector2(x - radius, y - radius).length()
			var value := clampf(1.0 - (dist / float(radius)), 0.0, 1.0)
			# Плавный спад (smoothstep)
			value = value * value * (3.0 - 2.0 * value)
			brush_stamp.set_pixel(x, y, Color(value, value, value, 1.0))


func _interpolate_points(from: Vector2, to: Vector2) -> Array[Vector2]:
	var points: Array[Vector2] = []
	var dist := from.distance_to(to)
	if dist < 1.0:
		points.append(to)
		return points
	var radius := 16.0
	if current_tool:
		radius = float(GameManager.get_tool_radius(current_tool))
	var spacing := maxf(radius * 0.4, 2.0)
	var steps := ceili(dist / spacing)
	for i in range(1, steps + 1):
		points.append(from.lerp(to, float(i) / float(steps)))
	return points


func _update_progress() -> void:
	if damage_remaining.is_empty():
		progress_bar.value = 0.0
		return

	var total := 0.0
	var count := 0
	for damage_type_id: String in mask_images:
		damage_remaining[damage_type_id] = _calculate_remaining(damage_type_id)
		total += damage_remaining[damage_type_id]
		count += 1

	var avg_remaining := total / float(count) if count > 0 else 0.0
	progress_bar.value = (1.0 - avg_remaining) * 100.0


func _calculate_remaining(damage_type_id: String) -> float:
	var mask: Image = mask_images[damage_type_id]
	var total := 0.0
	var sampled := 0
	# Выборка каждого 4-го пикселя, только на непрозрачных частях предмета
	for x in range(0, mask.get_width(), 4):
		for y in range(0, mask.get_height(), 4):
			if item_shape and item_shape.get_pixel(x, y).a < 0.1:
				continue
			total += mask.get_pixel(x, y).r
			sampled += 1
	return total / float(sampled) if sampled > 0 else 0.0


func _check_completion() -> void:
	var config := GameManager.economy_config as EconomyConfig
	var threshold: float = config.completion_threshold if config else 0.05

	for damage_type_id: String in damage_remaining:
		if damage_remaining[damage_type_id] > threshold:
			return

	# Предмет восстановлен!
	_on_item_completed()


func _on_item_completed() -> void:
	if item_data == null:
		return

	var reward := GameManager.calculate_item_reward(item_data, true)
	var is_masterwork := GameManager.roll_masters_touch()

	if is_masterwork:
		var config := GameManager.economy_config as EconomyConfig
		reward *= config.masters_touch_multiplier if config else 2.0

	GameManager.add_money(reward, "manual_restore")
	GameManager.items_restored += 1
	Events.item_restored.emit(item_data, reward, is_masterwork)

	item_data = null


func _update_brush_preview() -> void:
	if current_tool == null:
		brush_preview.visible = false
		return
	brush_preview.visible = true
	var radius := float(GameManager.get_tool_radius(current_tool))
	# BrushPreview будет обновлять свой размер через _draw()
	brush_preview.set_meta("radius", radius)
	brush_preview.queue_redraw()


func _mouse_exited() -> void:
	brush_preview.visible = false
	_mouse_inside = false


# --- Генерация заглушек текстур ---

func _generate_placeholder_clean_texture(_data: ItemData) -> ImageTexture:
	var img := Image.create(ITEM_SIZE.x, ITEM_SIZE.y, false, Image.FORMAT_RGBA8)
	# Bright clean item background — easy to see damage on top
	var base_color := Color(0.92, 0.88, 0.78, 1.0)
	img.fill(base_color)
	# Checkerboard pattern to give it some texture
	for x in range(ITEM_SIZE.x):
		for y in range(ITEM_SIZE.y):
			if (x + y) % 8 < 2:
				img.set_pixel(x, y, base_color.darkened(0.05))
	return ImageTexture.create_from_image(img)


func _generate_placeholder_damage_texture(damage_type: DamageTypeData, _intensity: float) -> ImageTexture:
	var img := Image.create(ITEM_SIZE.x, ITEM_SIZE.y, false, Image.FORMAT_RGBA8)
	var color := damage_type.color
	# Full opacity — the shader handles intensity via the mask
	color.a = 1.0
	img.fill(color)
	# Add noise for texture variety
	for x in range(ITEM_SIZE.x):
		for y in range(ITEM_SIZE.y):
			var noise_val := randf_range(-0.1, 0.1)
			var c := Color(
				clampf(color.r + noise_val, 0.0, 1.0),
				clampf(color.g + noise_val, 0.0, 1.0),
				clampf(color.b + noise_val, 0.0, 1.0),
				1.0
			)
			img.set_pixel(x, y, c)
	return ImageTexture.create_from_image(img)


# --- Сериализация масок для сохранения ---

func serialize_masks() -> PackedByteArray:
	var result := PackedByteArray()
	for damage_type_id: String in mask_images:
		var img: Image = mask_images[damage_type_id]
		var png_data: PackedByteArray = img.save_png_to_buffer()
		var id_bytes: PackedByteArray = damage_type_id.to_utf8_buffer()
		# [длина id (4 байта)] [id строка] [длина png (4 байта)] [png данные]
		result.append_array(_int_to_bytes(id_bytes.size()))
		result.append_array(id_bytes)
		result.append_array(_int_to_bytes(png_data.size()))
		result.append_array(png_data)
	return result


func deserialize_masks(data: PackedByteArray) -> void:
	var offset := 0
	while offset < data.size() - 8:
		var id_len := _bytes_to_int(data, offset)
		offset += 4
		var id_bytes_slice: PackedByteArray = data.slice(offset, offset + id_len)
		var id_str: String = id_bytes_slice.get_string_from_utf8()
		offset += id_len
		var png_len: int = _bytes_to_int(data, offset)
		offset += 4
		var png_data: PackedByteArray = data.slice(offset, offset + png_len)
		offset += png_len

		var img := Image.new()
		img.load_png_from_buffer(png_data)
		if id_str in mask_images:
			mask_images[id_str] = img
			mask_textures[id_str].update(img)
			damage_remaining[id_str] = _calculate_remaining(id_str)

	_update_progress()


func _int_to_bytes(value: int) -> PackedByteArray:
	var bytes := PackedByteArray()
	bytes.resize(4)
	bytes.encode_s32(0, value)
	return bytes


func _bytes_to_int(data: PackedByteArray, offset: int) -> int:
	return data.decode_s32(offset)

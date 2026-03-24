extends Node
## Корневая сцена игры. Управляет запуском и связывает подсистемы.

@onready var workshop = $Workshop
@onready var hud = $UILayer/HUD


func _ready() -> void:
	# Связываем кнопку "Следующий предмет" из попапа с мастерской
	var popup = hud.get_node("ItemCompletePopup")
	if popup:
		popup.next_item_requested.connect(_on_next_item_requested)

	# На вебе показываем экран "Нажмите чтобы начать" для разрешения аудио
	if OS.has_feature("web"):
		_show_click_to_play()
	else:
		_start_game()


func _start_game() -> void:
	SaveManager.load_game()


func _on_next_item_requested() -> void:
	workshop.request_next_item()


func _show_click_to_play() -> void:
	# TODO: добавить оверлей "Click to Play" для веба
	_start_game()


func _input(event: InputEvent) -> void:
	# F11 — переключение полноэкранного режима
	if event is InputEventKey and event.pressed and event.keycode == KEY_F11:
		if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

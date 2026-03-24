extends PanelContainer
## Settings popup — UI scale slider.

@onready var scale_slider: HSlider = $VBox/ScaleSlider
@onready var scale_label: Label = $VBox/ScaleLabel
@onready var close_button: Button = $VBox/CloseButton

const SAVE_KEY := "ui_scale"
var _hud: Control = null


func _ready() -> void:
	visible = false
	close_button.pressed.connect(func() -> void: visible = false)
	scale_slider.min_value = 0.7
	scale_slider.max_value = 1.25
	scale_slider.step = 0.05
	scale_slider.value = _load_scale()
	scale_slider.value_changed.connect(_on_scale_changed)
	_update_label()


func setup(hud: Control) -> void:
	_hud = hud
	_apply_scale(scale_slider.value)


func _on_scale_changed(value: float) -> void:
	_apply_scale(value)
	_update_label()
	_save_scale(value)


func _apply_scale(value: float) -> void:
	if _hud and _hud.get_tree():
		# Масштабируем размер шрифта темы
		var base_size := int(22.0 * value)
		var btn_size := int(20.0 * value)
		var tab_size := int(20.0 * value)
		if _hud.theme:
			_hud.theme.set_default_font_size(base_size)
			_hud.theme.set_font_size("font_size", "Label", base_size)
			_hud.theme.set_font_size("font_size", "Button", btn_size)
			_hud.theme.set_font_size("font_size", "TabContainer", tab_size)


func _update_label() -> void:
	scale_label.text = "UI Scale: %d%%" % int(scale_slider.value * 100)


func _save_scale(value: float) -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("settings", SAVE_KEY, value)
	cfg.save("user://settings.cfg")


func _load_scale() -> float:
	var cfg := ConfigFile.new()
	if cfg.load("user://settings.cfg") == OK:
		return cfg.get_value("settings", SAVE_KEY, 1.0)
	return 1.0

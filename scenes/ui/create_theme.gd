@tool
extends EditorScript
## Создаёт тему оформления для игры и сохраняет в assets/themes/game_theme.tres
## Запускать: Script -> Run (Ctrl+Shift+X)


func _run() -> void:
	var theme := Theme.new()

	# Размер шрифта по умолчанию — крупный, хорошо читаемый
	theme.set_default_font_size(22)

	# --- Label ---
	theme.set_font_size("font_size", "Label", 22)
	theme.set_color("font_color", "Label", Color(0.95, 0.92, 0.85))
	theme.set_color("font_shadow_color", "Label", Color(0, 0, 0, 0.5))
	theme.set_constant("shadow_offset_x", "Label", 1)
	theme.set_constant("shadow_offset_y", "Label", 1)

	# --- Button ---
	theme.set_font_size("font_size", "Button", 20)
	theme.set_color("font_color", "Button", Color(0.95, 0.92, 0.85))
	theme.set_color("font_hover_color", "Button", Color(1, 1, 0.9))
	theme.set_color("font_pressed_color", "Button", Color(0.8, 0.75, 0.6))
	theme.set_color("font_disabled_color", "Button", Color(0.5, 0.48, 0.42))

	var btn_normal := StyleBoxFlat.new()
	btn_normal.bg_color = Color(0.35, 0.28, 0.18)
	btn_normal.border_color = Color(0.6, 0.5, 0.3)
	btn_normal.set_border_width_all(2)
	btn_normal.set_corner_radius_all(4)
	btn_normal.set_content_margin_all(8)
	theme.set_stylebox("normal", "Button", btn_normal)

	var btn_hover := btn_normal.duplicate()
	btn_hover.bg_color = Color(0.45, 0.36, 0.22)
	btn_hover.border_color = Color(0.8, 0.7, 0.4)
	theme.set_stylebox("hover", "Button", btn_hover)

	var btn_pressed := btn_normal.duplicate()
	btn_pressed.bg_color = Color(0.25, 0.2, 0.12)
	theme.set_stylebox("pressed", "Button", btn_pressed)

	var btn_disabled := btn_normal.duplicate()
	btn_disabled.bg_color = Color(0.22, 0.2, 0.17)
	btn_disabled.border_color = Color(0.35, 0.32, 0.28)
	theme.set_stylebox("disabled", "Button", btn_disabled)

	# --- Panel ---
	var panel_bg := StyleBoxFlat.new()
	panel_bg.bg_color = Color(0.12, 0.1, 0.08, 0.9)
	panel_bg.border_color = Color(0.4, 0.35, 0.25)
	panel_bg.set_border_width_all(2)
	panel_bg.set_corner_radius_all(4)
	panel_bg.set_content_margin_all(8)
	theme.set_stylebox("panel", "Panel", panel_bg)
	theme.set_stylebox("panel", "PanelContainer", panel_bg)

	# --- TabContainer ---
	theme.set_font_size("font_size", "TabContainer", 20)
	theme.set_color("font_selected_color", "TabContainer", Color(1, 0.95, 0.8))
	theme.set_color("font_unselected_color", "TabContainer", Color(0.6, 0.55, 0.45))

	var tab_panel := StyleBoxFlat.new()
	tab_panel.bg_color = Color(0.15, 0.12, 0.1, 0.95)
	tab_panel.border_color = Color(0.4, 0.35, 0.25)
	tab_panel.set_border_width_all(2)
	tab_panel.set_corner_radius_all(4)
	tab_panel.set_content_margin_all(10)
	theme.set_stylebox("panel", "TabContainer", tab_panel)

	var tab_selected := StyleBoxFlat.new()
	tab_selected.bg_color = Color(0.25, 0.2, 0.15)
	tab_selected.border_color = Color(0.6, 0.5, 0.3)
	tab_selected.set_border_width_all(2)
	tab_selected.border_width_bottom = 0
	tab_selected.set_corner_radius_all(4)
	tab_selected.corner_radius_bottom_left = 0
	tab_selected.corner_radius_bottom_right = 0
	tab_selected.set_content_margin_all(8)
	theme.set_stylebox("tab_selected", "TabContainer", tab_selected)

	var tab_unselected := StyleBoxFlat.new()
	tab_unselected.bg_color = Color(0.12, 0.1, 0.08)
	tab_unselected.border_color = Color(0.3, 0.25, 0.18)
	tab_unselected.set_border_width_all(1)
	tab_unselected.set_corner_radius_all(4)
	tab_unselected.corner_radius_bottom_left = 0
	tab_unselected.corner_radius_bottom_right = 0
	tab_unselected.set_content_margin_all(6)
	theme.set_stylebox("tab_unselected", "TabContainer", tab_unselected)

	# --- ProgressBar ---
	var bar_bg := StyleBoxFlat.new()
	bar_bg.bg_color = Color(0.15, 0.12, 0.1)
	bar_bg.border_color = Color(0.4, 0.35, 0.25)
	bar_bg.set_border_width_all(2)
	bar_bg.set_corner_radius_all(3)
	theme.set_stylebox("background", "ProgressBar", bar_bg)

	var bar_fill := StyleBoxFlat.new()
	bar_fill.bg_color = Color(0.4, 0.7, 0.3)
	bar_fill.set_corner_radius_all(2)
	theme.set_stylebox("fill", "ProgressBar", bar_fill)

	theme.set_font_size("font_size", "ProgressBar", 16)
	theme.set_color("font_color", "ProgressBar", Color(1, 1, 1))

	# --- HBoxContainer / VBoxContainer ---
	theme.set_constant("separation", "HBoxContainer", 10)
	theme.set_constant("separation", "VBoxContainer", 6)

	# Сохраняем
	var err := ResourceSaver.save(theme, "res://assets/themes/game_theme.tres")
	if err == OK:
		print("Тема сохранена: assets/themes/game_theme.tres")
	else:
		print("ОШИБКА сохранения темы: %d" % err)

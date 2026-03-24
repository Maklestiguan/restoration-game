class_name DamageTypeData
extends Resource
## Тип повреждения (ржавчина, пыль, трещины, грязь).
## Определяет внешний вид повреждения и какие инструменты эффективны против него.

## Уникальный идентификатор типа повреждения (например "rust", "dust")
@export var id: String = ""

## Отображаемое название типа повреждения
@export var display_name: String = ""

## Цвет оттенка для наложения повреждения
@export var color: Color = Color.WHITE

## Тайлящаяся текстура наложения повреждения
@export var overlay_texture: Texture2D

## Идентификаторы инструментов, эффективных против этого типа
@export var effective_tool_ids: Array[String] = []

## Сопротивление: чем выше, тем сложнее убрать (множитель)
@export var resistance: float = 1.0

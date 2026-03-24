class_name ToolData
extends Resource
## Данные инструмента реставрации.
## Каждый инструмент можно улучшать — растёт сила и радиус.

## Уникальный идентификатор инструмента (например "brush", "chisel")
@export var id: String = ""

## Отображаемое название
@export var display_name: String = ""

## Иконка инструмента для интерфейса
@export var icon: Texture2D

## Текстура курсора при перетаскивании
@export var cursor_texture: Texture2D

## Базовая сила удаления повреждения (за одно касание)
@export var base_strength: float = 1.0

## Базовый радиус действия в пикселях
@export var base_radius: int = 32

## Типы повреждений, против которых инструмент эффективен
@export var effective_against: Array[String] = []

## Типы повреждений, против которых инструмент малоэффективен
@export var ineffective_against: Array[String] = []

## Базовая стоимость улучшения (уровень 1 → 2)
@export var upgrade_cost_base: float = 50.0

## Множитель роста стоимости: cost = base * (scaling ^ (level - 1))
@export var upgrade_cost_scaling: float = 1.5

## Прибавка к силе за каждый уровень (множитель, 0.2 = +20%)
@export var strength_per_level: float = 0.2

## Прибавка к радиусу за каждый уровень (в пикселях)
@export var radius_per_level: int = 4

## Максимальный уровень улучшения
@export var max_level: int = 20

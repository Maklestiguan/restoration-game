class_name DamageLayer
extends Resource
## Слой повреждения на конкретном предмете.
## Один предмет может иметь несколько слоёв разных типов повреждений.

## Идентификатор типа повреждения (ссылка на DamageTypeData.id)
@export var damage_type_id: String = ""

## Интенсивность покрытия (0.0-1.0), насколько сильно повреждение
@export var intensity: float = 1.0

## Смещение UV-координат текстуры наложения для разнообразия
@export var overlay_offset: Vector2 = Vector2.ZERO

## Масштаб текстуры наложения
@export var overlay_scale: float = 1.0

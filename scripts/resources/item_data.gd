class_name ItemData
extends Resource
## Данные предмета для реставрации.
## Определяет внешний вид, редкость, награду и слои повреждений.

enum Rarity { COMMON, UNCOMMON, RARE, EPIC, LEGENDARY }

## Уникальный идентификатор предмета
@export var id: String = ""

## Отображаемое название предмета
@export var display_name: String = ""

## Описание предмета (для карточки завершения)
@export var description: String = ""

## Редкость — влияет на награду и время реставрации
@export var rarity: Rarity = Rarity.COMMON

## Категория предмета ("antique", "everyday", "art")
@export var category: String = "antique"

## Текстура чистого (восстановленного) предмета
@export var clean_texture: Texture2D

## Базовая награда в деньгах за реставрацию
@export var base_reward: float = 100.0

## Слои повреждений на этом предмете
@export var damage_layers: Array[DamageLayer] = []

## Требуемый тир для появления этого предмета
@export var required_tier: int = 1

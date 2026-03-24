class_name WorkerData
extends Resource
## Данные работника (студент, специалист и т.д.).
## Работники автоматически реставрируют предметы в фоне.

## Уникальный идентификатор работника
@export var id: String = ""

## Отображаемое имя работника
@export var display_name: String = ""

## Портрет работника для интерфейса
@export var portrait: Texture2D

## Стоимость найма
@export var hire_cost: float = 500.0

## Скорость реставрации (предметов в минуту, дробное число)
@export var restore_speed: float = 0.1

## Типы повреждений, с которыми работник может справиться
@export var skill_types: Array[String] = []

## Требуемый тир для найма
@export var tier_required: int = 2

## Описание / история работника
@export var flavor_text: String = ""

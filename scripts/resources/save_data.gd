class_name SaveData
extends Resource
## Данные сохранения игры. Все поля сериализуются в .tres файл.

## Версия формата сохранения (для миграции между версиями)
@export var save_version: int = 1

## Метка времени сохранения (Unix, для расчёта оффлайн-дохода)
@export var timestamp_unix: float = 0.0

# --- Экономика ---
## Текущее количество денег
@export var money: float = 0.0

## Общее количество заработанных денег за всё время
@export var total_money_earned: float = 0.0

## Количество восстановленных предметов
@export var items_restored: int = 0

# --- Инструменты ---
## Уровни инструментов (ключ = tool_id, значение = уровень)
@export var tool_levels: Dictionary = {}

# --- Работники ---
## Идентификаторы нанятых работников
@export var hired_worker_ids: Array[String] = []

# --- Текущий предмет ---
## ID текущего предмета в процессе реставрации (пусто = нет предмета)
@export var current_item_id: String = ""

## Оставшееся повреждение по типам (ключ = damage_type_id, значение = 0.0-1.0)
@export var current_damage_remaining: Dictionary = {}

## Сериализованные маски повреждений (PNG байты)
@export var current_mask_data: PackedByteArray = PackedByteArray()

# --- Прогрессия ---
## Текущий тир прогрессии
@export var current_tier: int = 1

## Разблокированные категории предметов
@export var unlocked_categories: Array[String] = []

# --- Кот ---
## Есть ли кот
@export var has_cat: bool = false
## Уровень кота
@export var cat_level: int = 0

# --- Статистика ---
## Общее время игры в секундах
@export var total_play_time_seconds: float = 0.0

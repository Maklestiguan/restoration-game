class_name EconomyConfig
extends Resource
## Глобальная конфигурация экономики игры.
## ВСЕ числовые константы баланса собраны здесь.
## Изменяйте значения в .tres файле через инспектор Godot.

# --- Множители наград по редкости ---
## Множитель награды для обычных предметов
@export var reward_mult_common: float = 1.0
## Множитель награды для необычных предметов
@export var reward_mult_uncommon: float = 2.5
## Множитель награды для редких предметов
@export var reward_mult_rare: float = 6.0
## Множитель награды для эпических предметов
@export var reward_mult_epic: float = 15.0
## Множитель награды для легендарных предметов
@export var reward_mult_legendary: float = 40.0

# --- Прогрессия тиров ---
## Множитель дохода за каждый тир прогрессии (0.3 = +30% за тир)
@export var tier_reward_scaling: float = 0.3

## Стоимость разблокировки каждого тира (индекс = тир, 0-й и 1-й бесплатны)
@export var tier_unlock_costs: Array[float] = [0, 0, 5000, 25000, 100000, 500000, 2000000, 10000000]

# --- Рука мастера (Master's Touch) ---
## Шанс срабатывания "Рука мастера" при ручной реставрации (0.15 = 15%)
@export var masters_touch_chance: float = 0.15

## Множитель награды при срабатывании "Рука мастера" (2.0 = двойная награда)
@export var masters_touch_multiplier: float = 2.0

# --- Сложность предметов ---
## Бонус награды за уровень сложности (★ to ★★★★★).
## Индекс 0 = ★ (1.0x), индекс 4 = ★★★★★ (1.8x)
@export var difficulty_bonus: Array[float] = [1.0, 1.15, 1.3, 1.5, 1.8]

# --- Оффлайн-прогресс ---
## Эффективность работников в оффлайне (0.5 = 50% от онлайн-скорости)
@export var offline_efficiency: float = 0.5

## Максимальное время оффлайна для расчёта дохода (в секундах, 86400 = 24 часа)
@export var max_offline_seconds: float = 86400.0

# --- Глобальные множители для быстрой настройки баланса ---
## Глобальный множитель всего дохода (1.0 = без изменений)
@export var global_income_multiplier: float = 1.0

## Глобальный множитель всех цен (1.0 = без изменений)
@export var global_cost_multiplier: float = 1.0

## Глобальный множитель скорости работников (1.0 = без изменений)
@export var worker_speed_multiplier: float = 1.0

## Фиксированный доход одного работника в минуту ($)
@export var worker_income_per_min: float = 50.0

# --- Реставрация ---
## Порог завершения: предмет считается восстановленным когда все слои ниже этого значения
## (0.02 = 2% оставшегося повреждения, т.е. нужно очистить 98%)
@export var completion_threshold: float = 0.02

## Сила удаления повреждения за одно касание кистью (базовое значение).
## При значении 0.5 центр кисти убирает ~50% повреждения за касание.
@export var base_removal_rate: float = 0.5

# --- Кот-компаньон ---
## Базовая стоимость покупки кота
@export var cat_base_cost: float = 1000.0

## Стоимость улучшения кота: base * (scaling ^ level). Дорого — кот того стоит!
@export var cat_upgrade_cost_base: float = 2000.0
@export var cat_upgrade_cost_scaling: float = 1.5

## Бонус "Рука мастера" за уровень кота (+1% шанс за уровень)
@export var cat_masters_touch_per_level: float = 0.01

## Бонус дохода работников за уровень кота (+5% за уровень)
@export var cat_worker_bonus_per_level: float = 0.05

# --- Стартовые деньги ---
## Количество денег в начале новой игры
@export var starting_money: float = 0.0

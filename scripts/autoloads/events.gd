extends Node
## Шина событий — содержит только сигналы для связи между системами.
## Ни одна система не зависит от другой напрямую, все общаются через Events.

# --- Экономика ---
signal money_changed(new_amount: float)
signal money_earned(amount: float, source: String)
signal money_spent(amount: float, purpose: String)

# --- Реставрация ---
signal item_generated(item_data: Resource)
signal restoration_started(item_data: Resource)
signal restoration_progress_changed(percent: float)
signal damage_layer_cleared(damage_type_id: String)
signal item_restored(item_data: Resource, reward: float, is_masterwork: bool)

# --- Инструменты ---
signal tool_selected(tool_data: Resource)
signal tool_upgraded(tool_data: Resource, new_level: int)

# --- Работники ---
signal worker_hired(worker_data: Resource)
signal worker_completed_item(worker_data: Resource, reward: float)

# --- Прогрессия ---
signal tier_unlocked(tier: int)

# --- Сохранение ---
signal game_saved()
signal game_loaded()
signal offline_earnings_calculated(amount: float, time_seconds: float)

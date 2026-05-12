extends Node

signal minute_changed(current_minute: int)
signal hour_changed(current_hour: int)
signal day_changed(current_day: int)
signal month_changed(current_month: int)
signal year_changed(current_year: int)

const REAL_SECONDS_PER_GAME_DAY: float = 600.0
const GAME_SECONDS_PER_DAY: int = 86400
const GAME_DAYS_PER_YEAR: int = 365
const GAME_SECONDS_PER_REAL_SECOND: float = float(GAME_SECONDS_PER_DAY) / REAL_SECONDS_PER_GAME_DAY

# ============================================================
# DEBUG DE HORÁRIO
# true = força horário inicial para testar luz
# false = usa o save normal do jogo
# ============================================================

const DEBUG_FORCE_TIME: bool = false

# Horários úteis:
# 36000.0 = 10h
# 43200.0 = 12h
# 50400.0 = 14h
# 57600.0 = 16h
# 61200.0 = 17h
# 64800.0 = 18h
# 72000.0 = 20h
const DEBUG_START_SECONDS: float = 61200.0 # 17h

var total_game_seconds: float = 21600.0
var current_minute: int = 0
var current_hour: int = 6
var current_day: int = 1
var current_month: int = 1
var current_year: int = 1

var is_time_paused: bool = false


func _ready() -> void:
	if DEBUG_FORCE_TIME:
		total_game_seconds = DEBUG_START_SECONDS
	else:
		load_time()
		_apply_offline_time()

	_update_time_values()
	save_time()

	print("TimeManager carregado: ", get_full_time_text())


func _process(delta: float) -> void:
	if is_time_paused:
		return

	var old_minute: int = current_minute
	var old_hour: int = current_hour
	var old_day: int = current_day
	var old_month: int = current_month
	var old_year: int = current_year

	total_game_seconds += delta * GAME_SECONDS_PER_REAL_SECOND

	_update_time_values()

	if current_minute != old_minute:
		minute_changed.emit(current_minute)

	if current_hour != old_hour:
		hour_changed.emit(current_hour)

	if current_day != old_day:
		day_changed.emit(current_day)
		save_time()

	if current_month != old_month:
		month_changed.emit(current_month)

	if current_year != old_year:
		year_changed.emit(current_year)
		save_time()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED:
		save_time()


func _apply_offline_time() -> void:
	var last_real_timestamp: int = int(SaveManager.load_value("time", "last_real_timestamp", Time.get_unix_time_from_system()))
	var current_real_timestamp: int = Time.get_unix_time_from_system()
	var elapsed_real_seconds: int = max(current_real_timestamp - last_real_timestamp, 0)

	if elapsed_real_seconds <= 0:
		return

	total_game_seconds += float(elapsed_real_seconds) * GAME_SECONDS_PER_REAL_SECOND


func _update_time_values() -> void:
	var total_seconds_int: int = int(total_game_seconds)

	var total_days_passed: int = total_seconds_int / GAME_SECONDS_PER_DAY
	var seconds_today: int = total_seconds_int % GAME_SECONDS_PER_DAY

	current_year = (total_days_passed / GAME_DAYS_PER_YEAR) + 1

	var day_of_year: int = (total_days_passed % GAME_DAYS_PER_YEAR) + 1

	current_month = _get_month_from_day_of_year(day_of_year)
	current_day = _get_day_in_month(day_of_year)

	current_hour = seconds_today / 3600
	current_minute = (seconds_today % 3600) / 60


func _get_month_from_day_of_year(day_of_year: int) -> int:
	var days_per_month: Array[int] = _get_days_per_month()
	var accumulated: int = 0

	for i in range(days_per_month.size()):
		accumulated += days_per_month[i]

		if day_of_year <= accumulated:
			return i + 1

	return 12


func _get_day_in_month(day_of_year: int) -> int:
	var days_per_month: Array[int] = _get_days_per_month()
	var accumulated: int = 0

	for days in days_per_month:
		if day_of_year <= accumulated + days:
			return day_of_year - accumulated

		accumulated += days

	return 31


func _get_days_per_month() -> Array[int]:
	return [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]


func get_total_days_passed() -> int:
	return int(total_game_seconds) / GAME_SECONDS_PER_DAY


func get_current_day_absolute() -> int:
	return get_total_days_passed() + 1


func get_current_day() -> int:
	return current_day


func get_date_text() -> String:
	return "%02d/%02d/Ano %d" % [current_day, current_month, current_year]


func get_time_text() -> String:
	return "%02d:%02d" % [current_hour, current_minute]


func get_full_time_text() -> String:
	return get_date_text() + " - " + get_time_text()


func pause_time() -> void:
	is_time_paused = true


func resume_time() -> void:
	is_time_paused = false


func save_time() -> void:
	if DEBUG_FORCE_TIME:
		return

	SaveManager.save_value("time", "total_game_seconds", total_game_seconds)
	SaveManager.save_value("time", "last_real_timestamp", Time.get_unix_time_from_system())


func load_time() -> void:
	total_game_seconds = float(SaveManager.load_value("time", "total_game_seconds", 21600.0))

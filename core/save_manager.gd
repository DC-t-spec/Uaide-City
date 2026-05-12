extends Node

const SAVE_PATH := "user://uaide_city_save.cfg"


func save_value(section: String, key: String, value: Variant) -> void:
	var config := ConfigFile.new()
	config.load(SAVE_PATH)

	config.set_value(section, key, value)

	var error := config.save(SAVE_PATH)

	if error != OK:
		push_error("Erro ao salvar %s/%s: %s" % [section, key, error])


func load_value(section: String, key: String, default_value: Variant) -> Variant:
	var config := ConfigFile.new()
	var error := config.load(SAVE_PATH)

	if error != OK:
		return default_value

	return config.get_value(section, key, default_value)


# ============================================================
# PLAYER / MONEY
# ============================================================

func save_player_money(amount: int) -> void:
	save_value("player", "money", amount)


func load_player_money(default_money: int = 100) -> int:
	return int(load_value("player", "money", default_money))


# ============================================================
# JOBS
# ============================================================

func save_job_data(job_data: Dictionary) -> void:
	save_value("jobs", "current_job", job_data)


func load_job_data() -> Dictionary:
	var data = load_value("jobs", "current_job", {})

	if typeof(data) == TYPE_DICTIONARY:
		return data

	return {}


# ============================================================
# FINANCE
# ============================================================

func save_finance_data(finance_data: Dictionary) -> void:
	save_value("finance", "data", finance_data)


func load_finance_data() -> Dictionary:
	var data = load_value("finance", "data", {})

	if typeof(data) == TYPE_DICTIONARY:
		return data

	return {}

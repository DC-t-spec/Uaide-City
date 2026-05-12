extends Label

# ============================================================
# UAIDE CITY - REPUTATION LABEL PRO
# Mostra reputação com progresso por nível
# ============================================================

func _ready() -> void:
	update_reputation_text()

	var rep = get_node_or_null("/root/ReputationManager")

	if rep != null:
		if rep.has_signal("reputation_changed"):
			rep.reputation_changed.connect(_on_reputation_changed)

		if rep.has_signal("reputation_level_changed"):
			rep.reputation_level_changed.connect(_on_reputation_level_changed)


# ============================================================
# UPDATE
# ============================================================

func update_reputation_text() -> void:
	var rep = get_node_or_null("/root/ReputationManager")

	if rep == null:
		text = "Rep: 0/50 | Desconhecido"
		return

	var value: int = rep.get_reputation()
	var level: String = rep.get_reputation_level()

	var range_data: Dictionary = _get_level_range(value)

	var min_value: int = range_data["min"]
	var max_value: int = range_data["max"]

	var current_progress: int = value - min_value
	var max_progress: int = max_value - min_value

	# segurança
	if current_progress < 0:
		current_progress = 0

	text = "Rep: " + str(current_progress) + "/" + str(max_progress) + " | " + level


# ============================================================
# NÍVEIS
# ============================================================

func _get_level_range(value: int) -> Dictionary:

	if value < 0:
		return {"min": -100, "max": 0}

	elif value < 50:
		return {"min": 0, "max": 50}

	elif value < 150:
		return {"min": 50, "max": 150}

	elif value < 300:
		return {"min": 150, "max": 300}

	elif value < 600:
		return {"min": 300, "max": 600}

	else:
		return {"min": 600, "max": 1000}  # pode crescer depois


# ============================================================
# SIGNALS
# ============================================================

func _on_reputation_changed(_v: int) -> void:
	update_reputation_text()


func _on_reputation_level_changed(_l: String) -> void:
	update_reputation_text()

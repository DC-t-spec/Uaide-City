extends Node

# ============================================================
# UAIDE CITY - REPUTATION MANAGER
# Sistema global de reputação do jogador
# Compatível com SaveManager real do projeto
# ============================================================

signal reputation_changed(new_value: int)
signal reputation_level_changed(new_level: String)

const SAVE_SECTION: String = "reputation"
const SAVE_KEY_VALUE: String = "value"
const SAVE_KEY_LEVEL: String = "level"

var reputation: int = 0
var reputation_level: String = "Desconhecido"


func _ready() -> void:
	load_reputation()
	update_reputation_level()
	print("ReputationManager carregado. Reputação:", reputation, " Nível:", reputation_level)


# ============================================================
# CONSULTAS
# ============================================================

func get_reputation() -> int:
	return reputation


func get_reputation_level() -> String:
	return reputation_level


# ============================================================
# ALTERAR REPUTAÇÃO
# ============================================================

func add_reputation(amount: int) -> void:
	if amount <= 0:
		return

	reputation += amount
	update_reputation_level()
	save_reputation()
	reputation_changed.emit(reputation)


func remove_reputation(amount: int) -> void:
	if amount <= 0:
		return

	reputation -= amount

	if reputation < -100:
		reputation = -100

	update_reputation_level()
	save_reputation()
	reputation_changed.emit(reputation)


func set_reputation(value: int) -> void:
	reputation = value

	if reputation < -100:
		reputation = -100

	update_reputation_level()
	save_reputation()
	reputation_changed.emit(reputation)


# ============================================================
# NÍVEL
# ============================================================

func update_reputation_level() -> void:
	var old_level: String = reputation_level

	if reputation < 0:
		reputation_level = "Suspeito"
	elif reputation < 50:
		reputation_level = "Desconhecido"
	elif reputation < 150:
		reputation_level = "Conhecido"
	elif reputation < 300:
		reputation_level = "Respeitado"
	elif reputation < 600:
		reputation_level = "Influente"
	else:
		reputation_level = "Elite da Cidade"

	if old_level != reputation_level:
		reputation_level_changed.emit(reputation_level)


# ============================================================
# SAVE / LOAD
# ============================================================

func save_reputation() -> void:
	var save_manager = get_node_or_null("/root/SaveManager")

	if save_manager == null:
		print("SaveManager não encontrado. Reputação não foi salva.")
		return

	save_manager.save_value(SAVE_SECTION, SAVE_KEY_VALUE, reputation)
	save_manager.save_value(SAVE_SECTION, SAVE_KEY_LEVEL, reputation_level)


func load_reputation() -> void:
	var save_manager = get_node_or_null("/root/SaveManager")

	if save_manager == null:
		reputation = 0
		reputation_level = "Desconhecido"
		return

	reputation = int(save_manager.load_value(SAVE_SECTION, SAVE_KEY_VALUE, 0))
	reputation_level = str(save_manager.load_value(SAVE_SECTION, SAVE_KEY_LEVEL, "Desconhecido"))

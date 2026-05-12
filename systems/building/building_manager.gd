extends Node

# ============================================================
# UAIDE CITY - BUILDING MANAGER
# Controla construção de casas
# Integra reputação para desbloqueio de tipos de casa
# ============================================================

signal build_menu_requested(property_id: String)
signal house_built(property_id: String, house_type: String)

const SAVE_SECTION: String = "buildings"
const SAVE_KEY: String = "data"

var buildings_data: Dictionary = {}


# ============================================================
# INIT
# ============================================================

func _ready() -> void:
	load_data()
	print("BuildingManager carregado:", buildings_data)


# ============================================================
# UI
# ============================================================

func open_build_menu(property_id: String) -> void:
	build_menu_requested.emit(property_id)


# ============================================================
# CONSTRUÇÃO
# ============================================================

func build_house(property_id: String, house_type: String) -> bool:
	if property_id.strip_edges() == "":
		print("Erro: property_id vazio.")
		return false

	if buildings_data.has(property_id):
		print("Este lote já tem construção.")
		return false

	if not BuildingData.has_house_type(house_type):
		print("Tipo de casa inválido:", house_type)
		return false

	if not _has_required_reputation_for_house(house_type):
		var required_level: String = _get_required_reputation_for_house(house_type)
		_show_message("Reputação insuficiente. Necessário: " + required_level + ".")
		print("Reputação insuficiente para construir:", house_type, " Necessário:", required_level)
		return false

	var price: int = BuildingData.get_house_price(house_type)

	if not EconomyManager.has_money(price):
		_show_message("Dinheiro insuficiente para construir esta casa.")
		print("Dinheiro insuficiente")
		return false

	EconomyManager.remove_money(price)

	buildings_data[property_id] = {
		"built": true,
		"house_type": house_type
	}

	save_data()

	print("Casa construída:", property_id, house_type)
	_show_message("Casa construída com sucesso.")

	house_built.emit(property_id, house_type)

	return true


# ============================================================
# REPUTAÇÃO - DESBLOQUEIO DE CASAS
# ============================================================

func _get_reputation_manager() -> Node:
	return get_node_or_null("/root/ReputationManager")


func _get_player_reputation_level() -> String:
	var rep = _get_reputation_manager()

	if rep == null:
		return "Desconhecido"

	if rep.has_method("get_reputation_level"):
		return str(rep.get_reputation_level())

	return "Desconhecido"


func _get_required_reputation_for_house(house_type: String) -> String:
	match house_type:
		"house_simple":
			return "Desconhecido"
		"house_family":
			return "Conhecido"
		"house_modern":
			return "Respeitado"
		"house_luxury":
			return "Influente"
		_:
			return "Desconhecido"


func _has_required_reputation_for_house(house_type: String) -> bool:
	var player_level: String = _get_player_reputation_level()
	var required_level: String = _get_required_reputation_for_house(house_type)

	var levels: Array[String] = [
		"Suspeito",
		"Desconhecido",
		"Conhecido",
		"Respeitado",
		"Influente",
		"Elite da Cidade"
	]

	var player_index: int = levels.find(player_level)
	var required_index: int = levels.find(required_level)

	if player_index == -1 or required_index == -1:
		return true

	return player_index >= required_index


# ============================================================
# CONSULTAS
# ============================================================

func has_building(property_id: String) -> bool:
	return buildings_data.has(property_id)


func get_building_data(property_id: String) -> Dictionary:
	if not buildings_data.has(property_id):
		return {}

	return buildings_data[property_id]


func get_house_type(property_id: String) -> String:
	var data: Dictionary = get_building_data(property_id)

	if data.is_empty():
		return ""

	return str(data.get("house_type", ""))


# ============================================================
# FEEDBACK
# ============================================================

func _show_message(message: String) -> void:
	var ui := get_tree().get_first_node_in_group("ui")

	if ui != null and ui.has_method("show_system_message"):
		ui.show_system_message(message)
	else:
		print(message)


# ============================================================
# SAVE / LOAD
# ============================================================

func save_data() -> void:
	SaveManager.save_value(SAVE_SECTION, SAVE_KEY, buildings_data)


func load_data() -> void:
	var data = SaveManager.load_value(SAVE_SECTION, SAVE_KEY, {})

	if typeof(data) == TYPE_DICTIONARY:
		buildings_data = data
	else:
		buildings_data = {}

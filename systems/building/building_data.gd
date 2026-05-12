extends Node
class_name BuildingData
# ============================================================
# UAIDE CITY - BUILDING DATA
# Base oficial dos tipos de construção
# ============================================================

const HOUSE_SIMPLE: String = "house_simple"
const HOUSE_FAMILY: String = "house_family"
const HOUSE_MODERN: String = "house_modern"
const HOUSE_LUXURY: String = "house_luxury"


const HOUSE_TYPES: Dictionary = {
	HOUSE_SIMPLE: {
		"name": "Casa Simples",
		"description": "Uma casa pequena e funcional para início de vida.",
		"price": 1500,
		"scene_path": "res://properties/houses/house_simple.tscn",
		"energy_restore": 35,
		"rent_value": 250
	},

	HOUSE_FAMILY: {
		"name": "Casa Familiar",
		"description": "Casa maior, adequada para uma vida mais estável.",
		"price": 3500,
		"scene_path": "res://properties/houses/house_family.tscn",
		"energy_restore": 55,
		"rent_value": 500
	},

	HOUSE_MODERN: {
		"name": "Casa Moderna",
		"description": "Casa moderna com melhor conforto e maior valor social.",
		"price": 7500,
		"scene_path": "res://properties/houses/house_modern.tscn",
		"energy_restore": 75,
		"rent_value": 900
	},

	HOUSE_LUXURY: {
		"name": "Casa de Luxo",
		"description": "Propriedade premium com alto conforto e grande potencial de renda.",
		"price": 15000,
		"scene_path": "res://properties/houses/house_luxury.tscn",
		"energy_restore": 100,
		"rent_value": 1800
	}
}


static func get_all_house_types() -> Dictionary:
	return HOUSE_TYPES


static func has_house_type(house_type: String) -> bool:
	return HOUSE_TYPES.has(house_type)


static func get_house_data(house_type: String) -> Dictionary:
	if not HOUSE_TYPES.has(house_type):
		return {}

	return HOUSE_TYPES[house_type]


static func get_house_name(house_type: String) -> String:
	var data: Dictionary = get_house_data(house_type)

	if data.is_empty():
		return "Casa desconhecida"

	return str(data.get("name", "Casa"))


static func get_house_price(house_type: String) -> int:
	var data: Dictionary = get_house_data(house_type)

	if data.is_empty():
		return 0

	return int(data.get("price", 0))


static func get_house_scene_path(house_type: String) -> String:
	var data: Dictionary = get_house_data(house_type)

	if data.is_empty():
		return ""

	return str(data.get("scene_path", ""))


static func get_house_energy_restore(house_type: String) -> int:
	var data: Dictionary = get_house_data(house_type)

	if data.is_empty():
		return 25

	return int(data.get("energy_restore", 25))


static func get_house_rent_value(house_type: String) -> int:
	var data: Dictionary = get_house_data(house_type)

	if data.is_empty():
		return 0

	return int(data.get("rent_value", 0))

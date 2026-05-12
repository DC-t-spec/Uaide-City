extends Node

signal property_updated(property_id: String)

const PLAYER_ID := "player"
const DEFAULT_RENT_DAYS := 7

var properties: Dictionary = {}
var last_monthly_charge_key: String = ""


func _ready() -> void:
	load_properties()
	load_monthly_charge_state()

	if not TimeManager.day_changed.is_connected(_on_day_changed):
		TimeManager.day_changed.connect(_on_day_changed)

	_check_rent_expiration()
	_check_monthly_property_expenses(true)

	print("PropertyManager carregado com sucesso.")


func register_property(property_id: String, property_data: Dictionary) -> void:
	if property_id == "":
		push_error("PropertyManager: property_id vazio.")
		return

	if properties.has(property_id):
		var existing: Dictionary = properties[property_id]

		existing["name"] = property_data.get("name", existing.get("name", "Propriedade"))
		existing["type"] = property_data.get("type", existing.get("type", "house"))
		existing["price"] = int(property_data.get("price", existing.get("price", 0)))
		existing["rent_price"] = int(property_data.get("rent_price", existing.get("rent_price", 0)))

		properties[property_id] = existing
		save_properties()
		return

	properties[property_id] = {
		"id": property_id,
		"name": property_data.get("name", "Propriedade"),
		"type": property_data.get("type", "house"),
		"price": int(property_data.get("price", 0)),
		"rent_price": int(property_data.get("rent_price", 0)),
		"owner_id": "",
		"status": "available",
		"rent_start_day": 0,
		"rent_end_day": 0
	}

	ExpenseManager.register_property(property_id)
	save_properties()


func get_property(property_id: String) -> Dictionary:
	return properties.get(property_id, {})


func get_all_properties() -> Dictionary:
	return properties


func is_owner(property_id: String) -> bool:
	var data := get_property(property_id)

	if data.is_empty():
		return false

	return data.get("owner_id", "") == PLAYER_ID


func has_property(property_id: String) -> bool:
	return is_owner(property_id)


func buy_property(property_id: String) -> Dictionary:
	var data := get_property(property_id)

	if data.is_empty():
		return {"success": false, "message": "Propriedade não encontrada."}

	if data["status"] != "available":
		return {"success": false, "message": "Esta propriedade já não está disponível."}

	# ============================================================
	# BLOQUEIO POR REPUTAÇÃO
	# ============================================================

	if not _has_required_reputation(data):
		var required_level: String = _get_required_reputation(data)

		return {
			"success": false,
			"message": "Reputação insuficiente. Necessário: " + required_level + "."
		}

	var base_price: int = int(data["price"])
	var purchase_tax: int = TaxManager.calculate_property_purchase_tax(base_price)
	var total_price: int = base_price + purchase_tax

	if EconomyManager.get_money() < total_price:
		return {
			"success": false,
			"message": "Dinheiro insuficiente. Total necessário: %s MZN." % total_price
		}

	if not EconomyManager.spend_money(total_price):
		return {"success": false, "message": "Erro ao fazer pagamento."}

	FinanceManager.register_expense(
		"property_purchase",
		base_price,
		"Compra da propriedade: %s" % data.get("name", property_id),
		"property",
		property_id
	)

	TaxManager.register_property_purchase_tax(purchase_tax, property_id)

	data["owner_id"] = PLAYER_ID
	data["status"] = "sold"
	data["rent_start_day"] = 0
	data["rent_end_day"] = 0

	properties[property_id] = data

	ExpenseManager.register_property(property_id)
	save_properties()

	property_updated.emit(property_id)

	return {
		"success": true,
		"message": "Lote comprado com sucesso. Preço: %s MZN | Imposto: %s MZN | Total: %s MZN." % [
			base_price,
			purchase_tax,
			total_price
		]
	}


func rent_property(property_id: String, rent_days: int = DEFAULT_RENT_DAYS) -> Dictionary:
	var data := get_property(property_id)

	if data.is_empty():
		return {"success": false, "message": "Propriedade não encontrada."}

	if data["status"] != "available":
		return {"success": false, "message": "Esta propriedade já não está disponível para aluguer."}

	var rent_price: int = int(data["rent_price"])

	if EconomyManager.get_money() < rent_price:
		return {"success": false, "message": "Dinheiro insuficiente para alugar."}

	if not EconomyManager.spend_money(rent_price):
		return {"success": false, "message": "Erro ao pagar aluguer."}

	FinanceManager.register_expense(
		"property_rent",
		rent_price,
		"Aluguer da propriedade: %s" % data.get("name", property_id),
		"property",
		property_id
	)

	var start_day: int = TimeManager.get_current_day_absolute()
	var end_day: int = start_day + rent_days

	data["owner_id"] = PLAYER_ID
	data["status"] = "rented"
	data["rent_start_day"] = start_day
	data["rent_end_day"] = end_day

	properties[property_id] = data

	ExpenseManager.register_property(property_id)
	save_properties()

	property_updated.emit(property_id)

	return {
		"success": true,
		"message": "Propriedade alugada por " + str(rent_days) + " dias."
	}


func expire_rent(property_id: String) -> void:
	var data := get_property(property_id)

	if data.is_empty():
		return

	data["owner_id"] = ""
	data["status"] = "available"
	data["rent_start_day"] = 0
	data["rent_end_day"] = 0

	properties[property_id] = data
	save_properties()

	property_updated.emit(property_id)

	print("Aluguer expirou: ", property_id)


func _on_day_changed(_current_day: int) -> void:
	_check_rent_expiration()
	_check_monthly_property_expenses(false)


func _check_rent_expiration() -> void:
	var today: int = TimeManager.get_current_day_absolute()

	for property_id in properties.keys():
		var data: Dictionary = properties[property_id]

		if data.get("status", "") == "rented":
			var rent_end_day: int = int(data.get("rent_end_day", 0))

			if rent_end_day > 0 and today >= rent_end_day:
				expire_rent(property_id)


func _check_monthly_property_expenses(force_if_missing_this_month: bool = false) -> void:
	var charge_key: String = "%s_%s" % [
		str(TimeManager.current_year),
		str(TimeManager.current_month)
	]

	if last_monthly_charge_key == charge_key:
		return

	if TimeManager.current_day != 1 and not force_if_missing_this_month:
		return

	var charged_any: bool = false

	for property_id in properties.keys():
		var data: Dictionary = properties[property_id]

		if data.get("owner_id", "") == PLAYER_ID:
			ExpenseManager.charge_monthly_property_expenses(data)

			if data.get("status", "") == "sold":
				TaxManager.charge_monthly_property_tax(data)

			charged_any = true

	if charged_any:
		last_monthly_charge_key = charge_key
		save_monthly_charge_state()
		print("Cobranças mensais processadas:", charge_key)


# ============================================================
# REPUTAÇÃO - REQUISITOS DE PROPRIEDADE
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


func _get_required_reputation(property_data: Dictionary) -> String:
	var property_type: String = str(property_data.get("type", ""))

	match property_type:
		"simple":
			return "Desconhecido"
		"house_simple":
			return "Desconhecido"
		"residential_lot":
			return "Desconhecido"
		"commercial_lot":
			return "Conhecido"
		"family":
			return "Conhecido"
		"house_family":
			return "Conhecido"
		"modern":
			return "Respeitado"
		"house_modern":
			return "Respeitado"
		"luxury":
			return "Influente"
		"house_luxury":
			return "Influente"
		_:
			return "Desconhecido"


func _has_required_reputation(property_data: Dictionary) -> bool:
	var player_level: String = _get_player_reputation_level()
	var required_level: String = _get_required_reputation(property_data)

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
# SAVE / LOAD
# ============================================================

func save_properties() -> void:
	SaveManager.save_value("properties", "list", properties)


func load_properties() -> void:
	var loaded_properties = SaveManager.load_value("properties", "list", {})

	if typeof(loaded_properties) == TYPE_DICTIONARY:
		properties = loaded_properties
	else:
		properties = {}


func save_monthly_charge_state() -> void:
	SaveManager.save_value("properties", "last_monthly_charge_key", last_monthly_charge_key)


func load_monthly_charge_state() -> void:
	last_monthly_charge_key = str(
		SaveManager.load_value("properties", "last_monthly_charge_key", "")
	)

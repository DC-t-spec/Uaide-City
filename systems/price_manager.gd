extends Node

# ============================================================
# UAIDE CITY - PRICE MANAGER
# Tabela central de preços de produtos e serviços
# Integra FASE 6: comida recupera fome
# ============================================================

signal price_updated(item_id: String, new_price: int)

var prices: Dictionary = {}


func _ready() -> void:
	_register_default_prices()
	load_price_data()
	print("PriceManager carregado com sucesso.")


func _register_default_prices() -> void:
	prices = {
		"food_basic": {
			"id": "food_basic",
			"name": "Comida básica",
			"category": "food",
			"base_price": 10,
			"taxable": true,
			"hunger_restore": 25.0
		},
		"food_meal": {
			"id": "food_meal",
			"name": "Refeição completa",
			"category": "food",
			"base_price": 25,
			"taxable": true,
			"hunger_restore": 55.0
		},
		"drink_basic": {
			"id": "drink_basic",
			"name": "Bebida básica",
			"category": "food",
			"base_price": 6,
			"taxable": true,
			"hunger_restore": 10.0
		},
		"transport_basic": {
			"id": "transport_basic",
			"name": "Transporte básico",
			"category": "transport",
			"base_price": 8,
			"taxable": true
		},
		"water_bill": {
			"id": "water_bill",
			"name": "Conta de água",
			"category": "property",
			"base_price": 15,
			"taxable": false
		},
		"energy_bill": {
			"id": "energy_bill",
			"name": "Conta de energia",
			"category": "property",
			"base_price": 20,
			"taxable": false
		},
		"property_maintenance": {
			"id": "property_maintenance",
			"name": "Manutenção da casa",
			"category": "property",
			"base_price": 25,
			"taxable": false
		},
		"repair_light": {
			"id": "repair_light",
			"name": "Reparação leve",
			"category": "property",
			"base_price": 35,
			"taxable": true
		},
		"repair_heavy": {
			"id": "repair_heavy",
			"name": "Reparação pesada",
			"category": "property",
			"base_price": 80,
			"taxable": true
		}
	}


func has_item(item_id: String) -> bool:
	return prices.has(item_id)


func get_item(item_id: String) -> Dictionary:
	if not has_item(item_id):
		return {}

	return prices[item_id]


func get_base_price(item_id: String) -> int:
	if not has_item(item_id):
		return 0

	return int(prices[item_id].get("base_price", 0))


func is_taxable(item_id: String) -> bool:
	if not has_item(item_id):
		return false

	return bool(prices[item_id].get("taxable", false))


func get_tax_amount(item_id: String) -> int:
	var base_price: int = get_base_price(item_id)

	if base_price <= 0:
		return 0

	if not is_taxable(item_id):
		return 0

	return TaxManager.calculate_vat(base_price)


func get_total_price(item_id: String) -> int:
	var base_price: int = get_base_price(item_id)

	if base_price <= 0:
		return 0

	return base_price + get_tax_amount(item_id)


func get_item_name(item_id: String) -> String:
	if not has_item(item_id):
		return item_id

	return str(prices[item_id].get("name", item_id))


func get_category(item_id: String) -> String:
	if not has_item(item_id):
		return ""

	return str(prices[item_id].get("category", ""))


func get_hunger_restore(item_id: String) -> float:
	if not has_item(item_id):
		return 0.0

	return float(prices[item_id].get("hunger_restore", 0.0))


func get_all_prices() -> Dictionary:
	return prices


func get_prices_by_category(category: String) -> Dictionary:
	var result: Dictionary = {}

	for item_id in prices.keys():
		var item: Dictionary = prices[item_id]

		if str(item.get("category", "")) == category:
			result[item_id] = item

	return result


func set_price(item_id: String, new_price: int) -> bool:
	if item_id.strip_edges() == "":
		return false

	if new_price < 0:
		return false

	if not prices.has(item_id):
		prices[item_id] = {
			"id": item_id,
			"name": item_id,
			"category": "custom",
			"base_price": new_price,
			"taxable": true
		}
	else:
		prices[item_id]["base_price"] = new_price

	save_price_data()

	price_updated.emit(item_id, new_price)

	print("Preço atualizado:", item_id, "=", new_price)

	return true


func set_taxable(item_id: String, taxable: bool) -> bool:
	if not prices.has(item_id):
		return false

	prices[item_id]["taxable"] = taxable
	save_price_data()

	return true


func buy_item(item_id: String, quantity: int = 1, source: String = "shop") -> Dictionary:
	if not has_item(item_id):
		return {
			"success": false,
			"message": "Produto ou serviço não encontrado."
		}

	if quantity <= 0:
		return {
			"success": false,
			"message": "Quantidade inválida."
		}

	var item: Dictionary = get_item(item_id)
	var category: String = str(item.get("category", ""))

	var base_unit_price: int = get_base_price(item_id)
	var tax_unit_amount: int = get_tax_amount(item_id)

	var base_total: int = base_unit_price * quantity
	var tax_total: int = tax_unit_amount * quantity
	var final_total: int = base_total + tax_total

	if EconomyManager.get_money() < final_total:
		return {
			"success": false,
			"message": "Dinheiro insuficiente. Total necessário: %s MZN." % final_total,
			"item_id": item_id,
			"item_name": item.get("name", item_id),
			"total_price": final_total
		}

	if not EconomyManager.spend_money(final_total):
		return {
			"success": false,
			"message": "Erro ao efetuar pagamento.",
			"item_id": item_id,
			"item_name": item.get("name", item_id),
			"total_price": final_total
		}

	FinanceManager.register_expense(
		category,
		base_total,
		"Compra: %sx %s" % [quantity, item.get("name", item_id)],
		source,
		item_id
	)

	if tax_total > 0:
		TaxManager.register_vat(tax_total, item_id)

	var hunger_restored: float = 0.0

	if category == "food":
		hunger_restored = get_hunger_restore(item_id) * float(quantity)

		var life_manager: Node = get_node_or_null("/root/LifeManager")

		if life_manager != null and life_manager.has_method("eat"):
			life_manager.eat(hunger_restored)

	return {
		"success": true,
		"message": "Compra realizada com sucesso.",
		"item_id": item_id,
		"item_name": item.get("name", item_id),
		"name": item.get("name", item_id),
		"quantity": quantity,
		"base_total": base_total,
		"tax_total": tax_total,
		"final_total": final_total,
		"total_price": final_total,
		"hunger_restored": hunger_restored
	}


func save_price_data() -> void:
	SaveManager.save_value("prices", "list", prices)


func load_price_data() -> void:
	var loaded_prices = SaveManager.load_value("prices", "list", {})

	if typeof(loaded_prices) != TYPE_DICTIONARY:
		return

	for item_id in loaded_prices.keys():
		prices[item_id] = loaded_prices[item_id]


func reset_prices() -> void:
	_register_default_prices()
	save_price_data()

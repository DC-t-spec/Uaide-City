extends Node

# ============================================================
# UAIDE CITY - EXPENSE MANAGER
# Despesas gerais, contas de casa, manutenção e reparações
# Compatível com EconomyManager.spend_money()
# ============================================================

signal expense_charged(expense_data: Dictionary)
signal expense_pending(expense_data: Dictionary)
signal property_condition_changed(property_id: String, new_condition: int)

const BILL_STATUS_PAID := "paid"
const BILL_STATUS_PENDING := "pending"

var property_conditions: Dictionary = {}
var pending_bills: Array = []


func _ready() -> void:
	load_expense_data()
	print("ExpenseManager carregado com sucesso.")


# ============================================================
# PREÇOS
# ============================================================

func _get_price(item_id: String, fallback_price: int) -> int:
	var price_manager = get_node_or_null("/root/PriceManager")

	if price_manager == null:
		return fallback_price

	if not price_manager.has_method("get_total_price"):
		return fallback_price

	return int(price_manager.get_total_price(item_id))


func get_water_cost(_property_data: Dictionary) -> int:
	return _get_price("water_bill", 15)


func get_energy_cost(_property_data: Dictionary) -> int:
	return _get_price("energy_bill", 20)


func get_monthly_maintenance_cost(_property_data: Dictionary) -> int:
	return _get_price("property_maintenance", 25)


func get_light_repair_cost(_property_data: Dictionary) -> int:
	return _get_price("repair_light", 35)


func get_heavy_repair_cost(_property_data: Dictionary) -> int:
	return _get_price("repair_heavy", 80)


# ============================================================
# COBRANÇA MENSAL DE PROPRIEDADE
# ============================================================

func charge_monthly_property_expenses(property_data: Dictionary) -> void:
	if property_data.is_empty():
		return

	var property_id: String = str(property_data.get("id", ""))
	var property_name: String = str(property_data.get("name", "Propriedade"))
	var status: String = str(property_data.get("status", ""))

	if property_id == "":
		return

	if status != "sold" and status != "rented":
		return

	register_property(property_id)

	charge_expense(
		"property_water",
		get_water_cost(property_data),
		"Conta mensal de água - %s" % property_name,
		"property",
		property_id
	)

	charge_expense(
		"property_energy",
		get_energy_cost(property_data),
		"Conta mensal de energia - %s" % property_name,
		"property",
		property_id
	)

	if status == "sold":
		charge_expense(
			"property_maintenance",
			get_monthly_maintenance_cost(property_data),
			"Manutenção mensal da propriedade - %s" % property_name,
			"property",
			property_id
		)

		damage_property(property_id, 3)


# ============================================================
# REPARAÇÕES
# ============================================================

func repair_property(property_id: String, property_name: String = "", heavy_repair: bool = false) -> bool:
	register_property(property_id)

	var amount: int = get_heavy_repair_cost({}) if heavy_repair else get_light_repair_cost({})
	var label: String = "Reparação pesada" if heavy_repair else "Reparação leve"

	var paid: bool = charge_expense(
		"property_repair",
		amount,
		"%s - %s" % [label, _get_property_label(property_id, property_name)],
		"property",
		property_id
	)

	if paid:
		var improvement: int = 35 if heavy_repair else 15
		improve_property_condition(property_id, improvement)

	return paid


# ============================================================
# COBRANÇA CENTRAL
# ============================================================

func charge_expense(
	category: String = "",
	amount: int = 0,
	description: String = "",
	source: String = "",
	reference_id: String = ""
) -> bool:
	category = str(category)
	description = str(description)
	source = str(source)
	reference_id = str(reference_id)
	amount = int(amount)

	if category.strip_edges() == "":
		category = "general_expense"

	if description.strip_edges() == "":
		description = category

	if amount <= 0:
		push_warning("Despesa inválida: %s MZN | %s" % [amount, description])
		return false

	var cash_available: int = EconomyManager.get_money()
	var bank_available: int = BankManager.get_balance()
	var total_available: int = cash_available + bank_available

	if total_available < amount:
		_create_pending_bill(category, amount, description, source, reference_id)
		return false

	var remaining: int = amount
	var used_cash: int = 0
	var used_bank: int = 0

	if cash_available > 0:
		used_cash = min(cash_available, remaining)

		if not EconomyManager.spend_money(used_cash):
			push_error("ExpenseManager: falha ao descontar dinheiro físico.")
			return false

		remaining -= used_cash

	if remaining > 0:
		used_bank = BankManager.withdraw_for_payment(remaining)
		remaining -= used_bank

	if remaining > 0:
		push_error("ExpenseManager: pagamento incompleto inesperado.")
		return false

	var expense_data := {
		"id": _generate_expense_id(),
		"category": category,
		"amount": amount,
		"description": description,
		"source": source,
		"reference_id": reference_id,
		"day": TimeManager.get_current_day_absolute(),
		"status": BILL_STATUS_PAID,
		"used_cash": used_cash,
		"used_bank": used_bank
	}

	FinanceManager.register_expense(
		category,
		amount,
		description,
		source,
		reference_id
	)

	expense_charged.emit(expense_data)

	print("Despesa paga:", description, "| Total:", amount, "| Físico:", used_cash, "| Banco:", used_bank)

	return true


# ============================================================
# CONTAS PENDENTES
# ============================================================

func _create_pending_bill(
	category: String,
	amount: int,
	description: String,
	source: String,
	reference_id: String
) -> void:
	var bill := {
		"id": _generate_expense_id(),
		"category": category,
		"amount": amount,
		"description": description,
		"source": source,
		"reference_id": reference_id,
		"day": TimeManager.get_current_day_absolute(),
		"status": BILL_STATUS_PENDING
	}

	pending_bills.append(bill)
	save_expense_data()

	expense_pending.emit(bill)

	print("Conta pendente criada:", description, "-", amount, "MZN")


func pay_pending_bill(bill_id: String) -> bool:
	for i in range(pending_bills.size()):
		var bill: Dictionary = pending_bills[i]

		if str(bill.get("id", "")) != bill_id:
			continue

		var paid: bool = charge_expense(
			str(bill.get("category", "")),
			int(bill.get("amount", 0)),
			str(bill.get("description", "")),
			str(bill.get("source", "")),
			str(bill.get("reference_id", ""))
		)

		if not paid:
			return false

		pending_bills.remove_at(i)
		save_expense_data()

		bill["status"] = BILL_STATUS_PAID
		expense_charged.emit(bill)

		print("Conta pendente paga:", bill_id)

		return true

	return false


func pay_first_pending_bill() -> bool:
	if pending_bills.is_empty():
		return false

	var bill: Dictionary = pending_bills[0]
	return pay_pending_bill(str(bill.get("id", "")))


func get_pending_bills() -> Array:
	return pending_bills


func get_pending_bills_by_property(property_id: String) -> Array:
	var result: Array = []

	for bill in pending_bills:
		if str(bill.get("reference_id", "")) == property_id:
			result.append(bill)

	return result


# ============================================================
# ESTADO DA PROPRIEDADE
# ============================================================

func register_property(property_id: String, default_condition: int = 100) -> void:
	if property_id.strip_edges() == "":
		return

	if not property_conditions.has(property_id):
		property_conditions[property_id] = int(clamp(default_condition, 0, 100))
		save_expense_data()


func get_property_condition(property_id: String) -> int:
	return int(property_conditions.get(property_id, 100))


func damage_property(property_id: String, amount: int = 10) -> void:
	register_property(property_id)

	var new_value: int = int(clamp(get_property_condition(property_id) - amount, 0, 100))
	property_conditions[property_id] = new_value

	save_expense_data()
	property_condition_changed.emit(property_id, new_value)

	print("Estado da propriedade reduzido:", property_id, "=", new_value)


func improve_property_condition(property_id: String, amount: int) -> void:
	register_property(property_id)

	var new_value: int = int(clamp(get_property_condition(property_id) + amount, 0, 100))
	property_conditions[property_id] = new_value

	save_expense_data()
	property_condition_changed.emit(property_id, new_value)

	print("Estado da propriedade melhorado:", property_id, "=", new_value)


# ============================================================
# SAVE / LOAD
# ============================================================

func save_expense_data() -> void:
	SaveManager.save_value("expenses", "property_conditions", property_conditions)
	SaveManager.save_value("expenses", "pending_bills", pending_bills)


func load_expense_data() -> void:
	var loaded_conditions = SaveManager.load_value("expenses", "property_conditions", {})
	var loaded_bills = SaveManager.load_value("expenses", "pending_bills", [])

	if typeof(loaded_conditions) == TYPE_DICTIONARY:
		property_conditions = loaded_conditions
	else:
		property_conditions = {}

	if typeof(loaded_bills) == TYPE_ARRAY:
		pending_bills = loaded_bills
	else:
		pending_bills = []


# ============================================================
# UTIL
# ============================================================

func _generate_expense_id() -> String:
	return "expense_%s_%s" % [
		str(Time.get_unix_time_from_system()),
		str(randi())
	]


func _get_property_label(property_id: String, property_name: String = "") -> String:
	if property_name.strip_edges() != "":
		return "%s (%s)" % [property_name, property_id]

	return property_id


func reset_expenses() -> void:
	property_conditions.clear()
	pending_bills.clear()
	save_expense_data()

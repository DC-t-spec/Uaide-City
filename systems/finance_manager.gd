extends Node

# ============================================================
# UAIDE CITY - FINANCE MANAGER
# Histórico financeiro central
# ============================================================

signal transaction_added(transaction: Dictionary)

var transactions: Array = []


func _ready() -> void:
	load_finance_data()
	print("FinanceManager carregado com sucesso.")


# ============================================================
# REGISTAR ENTRADAS
# ============================================================

func register_income(
	category: String,
	amount: int,
	description: String = "",
	source: String = "",
	reference_id: String = ""
) -> void:
	_add_transaction("income", category, amount, description, source, reference_id)


# ============================================================
# REGISTAR SAÍDAS
# ============================================================

func register_expense(
	category: String,
	amount: int,
	description: String = "",
	source: String = "",
	reference_id: String = ""
) -> void:
	_add_transaction("expense", category, amount, description, source, reference_id)


# ============================================================
# TRANSAÇÃO CENTRAL
# ============================================================

func _add_transaction(
	transaction_type: String,
	category: String,
	amount: int,
	description: String,
	source: String,
	reference_id: String
) -> void:
	if amount <= 0:
		push_warning("FinanceManager: valor inválido.")
		return

	var transaction := {
		"id": _generate_transaction_id(),
		"type": transaction_type,
		"category": category,
		"amount": amount,
		"description": description,
		"source": source,
		"reference_id": reference_id,
		"day": TimeManager.get_current_day(),
		"timestamp": Time.get_unix_time_from_system()
	}

	transactions.append(transaction)
	save_finance_data()

	transaction_added.emit(transaction)

	print("Transação financeira registada:", transaction)


# ============================================================
# CONSULTAS
# ============================================================

func get_all_transactions() -> Array:
	return transactions


func get_recent_transactions(limit: int = 10) -> Array:
	var result: Array = []

	var start_index: int = max(transactions.size() - limit, 0)

	for i in range(start_index, transactions.size()):
		result.append(transactions[i])

	result.reverse()

	return result


func get_total_income() -> int:
	var total := 0

	for transaction in transactions:
		if transaction.get("type", "") == "income":
			total += int(transaction.get("amount", 0))

	return total


func get_total_expenses() -> int:
	var total := 0

	for transaction in transactions:
		if transaction.get("type", "") == "expense":
			total += int(transaction.get("amount", 0))

	return total


func get_financial_result() -> int:
	return get_total_income() - get_total_expenses()


func get_transactions_by_category(category: String) -> Array:
	var result: Array = []

	for transaction in transactions:
		if transaction.get("category", "") == category:
			result.append(transaction)

	return result


# ============================================================
# SAVE / LOAD
# ============================================================

func save_finance_data() -> void:
	SaveManager.save_finance_data({
		"transactions": transactions
	})


func load_finance_data() -> void:
	var data: Dictionary = SaveManager.load_finance_data()

	transactions.clear()

	if data.has("transactions") and typeof(data["transactions"]) == TYPE_ARRAY:
		for transaction in data["transactions"]:
			transactions.append(transaction)


# ============================================================
# UTIL
# ============================================================

func _generate_transaction_id() -> String:
	return "txn_%s_%s" % [
		str(Time.get_unix_time_from_system()),
		str(transactions.size() + 1)
	]


func reset_finance_history() -> void:
	transactions.clear()
	save_finance_data()

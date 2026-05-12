extends Node

# ============================================================
# UAIDE CITY - BANK MANAGER
# Sistema bancário básico
# ============================================================

signal bank_balance_changed(new_balance: int)

const SAVE_KEY: String = "bank"

var bank_balance: int = 0


func _ready() -> void:
	load_bank_data()
	print("BankManager carregado. Saldo:", bank_balance)


# ============================================================
# CONSULTAS
# ============================================================

func get_balance() -> int:
	return bank_balance


func can_withdraw(amount: int) -> bool:
	if amount <= 0:
		return false

	return bank_balance >= amount


# ============================================================
# DEPÓSITO
# ============================================================

func deposit(amount: int) -> bool:
	if amount <= 0:
		print("Erro: valor inválido para depósito.")
		return false

	if EconomyManager.get_money() < amount:
		print("Erro: dinheiro insuficiente para depositar.")
		return false

	EconomyManager.remove_money(amount)

	bank_balance += amount

	save_bank_data()

	FinanceManager.register_expense(
		"bank_deposit",
		amount,
		"Depósito bancário",
		"bank",
		"deposit"
	)

	bank_balance_changed.emit(bank_balance)

	print("Depósito realizado:", amount, "| Novo saldo bancário:", bank_balance)

	return true


# ============================================================
# LEVANTAMENTO
# ============================================================

func withdraw(amount: int) -> bool:
	if amount <= 0:
		print("Erro: valor inválido para levantamento.")
		return false

	if bank_balance < amount:
		print("Erro: saldo bancário insuficiente.")
		return false

	bank_balance -= amount

	EconomyManager.add_money(amount)

	save_bank_data()

	FinanceManager.register_income(
		"bank_withdraw",
		amount,
		"Levantamento bancário",
		"bank",
		"withdraw"
	)

	bank_balance_changed.emit(bank_balance)

	print("Levantamento realizado:", amount, "| Novo saldo bancário:", bank_balance)

	return true


# ============================================================
# LEVANTAMENTO INTERNO PARA PAGAMENTOS
# Não regista como rendimento, porque é usado para pagar contas.
# ============================================================

func withdraw_for_payment(amount: int) -> int:
	if amount <= 0:
		return 0

	var taken: int = min(bank_balance, amount)

	if taken <= 0:
		return 0

	bank_balance -= taken

	save_bank_data()
	bank_balance_changed.emit(bank_balance)

	print("Banco usado para pagamento:", taken, "| Saldo bancário:", bank_balance)

	return taken


# ============================================================
# SAVE / LOAD
# ============================================================

func save_bank_data() -> void:
	SaveManager.save_value("bank", "balance", bank_balance)


func load_bank_data() -> void:
	bank_balance = int(SaveManager.load_value("bank", "balance", 0))


# ============================================================
# RESET CONTROLADO
# ============================================================

func reset_bank() -> void:
	bank_balance = 0
	save_bank_data()
	bank_balance_changed.emit(bank_balance)

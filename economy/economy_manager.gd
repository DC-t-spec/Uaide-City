extends Node

# ============================================================
# UAIDE CITY - ECONOMY MANAGER
# Controla dinheiro físico do jogador
# ============================================================

signal money_changed(new_amount: int)

var money: int = 100


func _ready() -> void:
	money = SaveManager.load_player_money(100)
	money_changed.emit(money)

	print("EconomyManager carregado. Dinheiro:", money)


# ============================================================
# CONSULTAS
# ============================================================

func get_money() -> int:
	return money


func has_money(amount: int) -> bool:
	if amount <= 0:
		return false

	return money >= amount


# ============================================================
# ENTRADA DE DINHEIRO
# ============================================================

func add_money(amount: int) -> void:
	if amount <= 0:
		return

	money += amount
	_save_and_emit()


# ============================================================
# SAÍDA DE DINHEIRO
# ============================================================

func spend_money(amount: int) -> bool:
	if amount <= 0:
		return false

	if money < amount:
		print("Dinheiro insuficiente.")
		return false

	money -= amount
	_save_and_emit()

	return true


# Compatibilidade profissional:
# Alguns managers usam remove_money para despesas.
# Internamente usa spend_money para manter uma lógica única.
func remove_money(amount: int) -> bool:
	return spend_money(amount)


# ============================================================
# DEFINIR / RESETAR
# ============================================================

func set_money(amount: int) -> void:
	money = max(amount, 0)
	_save_and_emit()


func reset_money(start_amount: int = 100) -> void:
	money = max(start_amount, 0)
	_save_and_emit()


# ============================================================
# SAVE
# ============================================================

func _save_and_emit() -> void:
	SaveManager.save_player_money(money)
	money_changed.emit(money)

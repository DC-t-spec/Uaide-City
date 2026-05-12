extends Control

# ============================================================
# UAIDE CITY - BANK PANEL
# UI funcional do banco
# ============================================================

@onready var cash_label: Label = $Panel/VBoxContainer/CashLabel
@onready var bank_label: Label = $Panel/VBoxContainer/BankLabel
@onready var amount_input: LineEdit = $Panel/VBoxContainer/AmountInput
@onready var deposit_button: Button = $Panel/VBoxContainer/DepositButton
@onready var withdraw_button: Button = $Panel/VBoxContainer/WithdrawButton
@onready var close_button: Button = $Panel/VBoxContainer/CloseButton


func _ready() -> void:
	visible = false

	deposit_button.text = "Depositar"
	withdraw_button.text = "Levantar"
	close_button.text = "Fechar"
	amount_input.placeholder_text = "Valor"

	if not deposit_button.pressed.is_connected(_on_deposit_pressed):
		deposit_button.pressed.connect(_on_deposit_pressed)

	if not withdraw_button.pressed.is_connected(_on_withdraw_pressed):
		withdraw_button.pressed.connect(_on_withdraw_pressed)

	if not close_button.pressed.is_connected(_on_close_pressed):
		close_button.pressed.connect(_on_close_pressed)

	refresh()


func open_panel() -> void:
	visible = true
	refresh()


func close_panel() -> void:
	visible = false


func refresh() -> void:
	if EconomyManager:
		cash_label.text = "Dinheiro na mão: " + str(EconomyManager.get_money()) + " MT"

	if BankManager:
		bank_label.text = "Saldo no banco: " + str(BankManager.get_balance()) + " MT"


func get_amount() -> int:
	var text_value: String = amount_input.text.strip_edges()

	if text_value == "":
		return 0

	if not text_value.is_valid_int():
		return 0

	return int(text_value)


func _on_deposit_pressed() -> void:
	var amount: int = get_amount()

	if amount <= 0:
		print("Valor inválido para depósito.")
		return

	var success: bool = BankManager.deposit(amount)

	if success:
		amount_input.text = ""
		refresh()


func _on_withdraw_pressed() -> void:
	var amount: int = get_amount()

	if amount <= 0:
		print("Valor inválido para levantamento.")
		return

	var success: bool = BankManager.withdraw(amount)

	if success:
		amount_input.text = ""
		refresh()


func _on_close_pressed() -> void:
	close_panel()

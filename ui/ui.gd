extends CanvasLayer

# ============================================================
# UAIDE CITY - MAIN UI PRO MAX
# HUD + propriedades + empregos + finanças + vida + construção + missões
# Banco + Hospital + Reputação na Construção
# Correção: Build Menu com mouse visível + clique manual seguro
# ============================================================

@onready var money_label: Label = get_node_or_null("LeftHUD/VBoxContainer/MoneyLabel")
@onready var time_label: Label = get_node_or_null("TopHUD/TimeLabel")
@onready var hunger_label: Label = get_node_or_null("LeftHUD/VBoxContainer/HungerLabel")
@onready var energy_label: Label = get_node_or_null("LeftHUD/VBoxContainer/EnergyLabel")
@onready var mission_label: Label = get_node_or_null("LeftHUD/VBoxContainer/MissionLabel")

@onready var property_panel: Panel = get_node_or_null("PropertyPanel")
@onready var property_title_label: Label = get_node_or_null("PropertyPanel/VBoxContainer/PropertyTitleLabel")
@onready var property_status_label: Label = get_node_or_null("PropertyPanel/VBoxContainer/PropertyStatusLabel")
@onready var property_price_label: Label = get_node_or_null("PropertyPanel/VBoxContainer/PropertyPriceLabel")
@onready var property_rent_label: Label = get_node_or_null("PropertyPanel/VBoxContainer/PropertyRentLabel")
@onready var property_owner_label: Label = get_node_or_null("PropertyPanel/VBoxContainer/PropertyOwnerLabel")
@onready var property_action_label: Label = get_node_or_null("PropertyPanel/VBoxContainer/PropertyActionLabel")

@onready var job_panel: Panel = get_node_or_null("JobPanel")
@onready var job_title_label: Label = get_node_or_null("JobPanel/VBoxContainer/JobTitleLabel")
@onready var job_status_label: Label = get_node_or_null("JobPanel/VBoxContainer/JobStatusLabel")
@onready var job_progress_label: Label = get_node_or_null("JobPanel/VBoxContainer/JobProgressLabel")
@onready var job_reward_label: Label = get_node_or_null("JobPanel/VBoxContainer/JobRewardLabel")
@onready var job_action_label: Label = get_node_or_null("JobPanel/VBoxContainer/JobActionLabel")

@onready var finance_panel: Panel = get_node_or_null("FinancePanel")
@onready var finance_title_label: Label = get_node_or_null("FinancePanel/VBoxContainer/FinanceTitleLabel")
@onready var bank_label: Label = get_node_or_null("FinancePanel/VBoxContainer/BankLabel")
@onready var result_label: Label = get_node_or_null("FinancePanel/VBoxContainer/ResultLabel")
@onready var pending_label: Label = get_node_or_null("FinancePanel/VBoxContainer/PendingLabel")
@onready var transactions_label: Label = get_node_or_null("FinancePanel/VBoxContainer/TransactionsLabel")
@onready var finance_message_label: Label = get_node_or_null("FinancePanel/VBoxContainer/FinanceMessageLabel")
@onready var pay_bill_button: Button = get_node_or_null("FinancePanel/VBoxContainer/PayBillButton")

@onready var build_menu_panel: Panel = get_node_or_null("BuildMenuPanel")
@onready var build_title_label: Label = get_node_or_null("BuildMenuPanel/VBoxContainer/TitleLabel")
@onready var btn_simple: Button = get_node_or_null("BuildMenuPanel/VBoxContainer/BtnSimple")
@onready var btn_family: Button = get_node_or_null("BuildMenuPanel/VBoxContainer/BtnFamily")
@onready var btn_modern: Button = get_node_or_null("BuildMenuPanel/VBoxContainer/BtnModern")
@onready var btn_luxury: Button = get_node_or_null("BuildMenuPanel/VBoxContainer/BtnLuxury")

@onready var bank_panel: Control = get_node_or_null("BankPanel")
@onready var hospital_panel: Control = get_node_or_null("HospitalPanel")

var finance_open: bool = false
var current_build_property_id: String = ""


func _ready() -> void:
	add_to_group("ui")

	_setup_panels()
	_setup_labels()
	_connect_signals()
	_setup_build_buttons()

	_on_money_changed(EconomyManager.get_money())
	_on_time_changed(TimeManager.current_minute)
	_refresh_life_hud()
	update_finance_ui()
	_on_mission_updated(MissionManager.get_current_mission_text())

	show_feedback("Sistema carregado com sucesso.", "success")
	print("UI PRO MAX carregada com sucesso.")


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("finance_ui"):
		toggle_finance()

	if event.is_action_pressed("pay_bill"):
		_try_pay_first_pending_bill()

	if event.is_action_pressed("ui_cancel"):
		hide_build_menu()
		close_bank_panel()
		close_hospital_panel()

	if build_menu_panel != null and build_menu_panel.visible:
		_handle_build_menu_mouse_click(event)


func _handle_build_menu_mouse_click(event: InputEvent) -> void:
	if not event is InputEventMouseButton:
		return

	var mouse_event := event as InputEventMouseButton

	if not mouse_event.pressed:
		return

	if mouse_event.button_index != MOUSE_BUTTON_LEFT:
		return

	if _is_mouse_over_button(btn_simple, mouse_event.position):
		_on_build_simple_pressed()
		return

	if _is_mouse_over_button(btn_family, mouse_event.position):
		_on_build_family_pressed()
		return

	if _is_mouse_over_button(btn_modern, mouse_event.position):
		_on_build_modern_pressed()
		return

	if _is_mouse_over_button(btn_luxury, mouse_event.position):
		_on_build_luxury_pressed()
		return


func _is_mouse_over_button(button: Button, mouse_position: Vector2) -> bool:
	if button == null:
		return false

	if not button.visible:
		return false

	if button.disabled:
		return false

	return button.get_global_rect().has_point(mouse_position)


# ============================================================
# SETUP
# ============================================================

func _setup_panels() -> void:
	if property_panel != null:
		property_panel.visible = false

	if job_panel != null:
		job_panel.visible = false

	if finance_panel != null:
		finance_panel.visible = false

	if build_menu_panel != null:
		build_menu_panel.visible = false
		build_menu_panel.mouse_filter = Control.MOUSE_FILTER_STOP

	if bank_panel != null:
		bank_panel.visible = false

	if hospital_panel != null:
		hospital_panel.visible = false


func _setup_labels() -> void:
	if finance_title_label != null:
		finance_title_label.text = "FINANÇAS"

	if finance_message_label != null:
		finance_message_label.text = ""

	if hunger_label != null:
		hunger_label.text = "Fome: --%"

	if energy_label != null:
		energy_label.text = "Energia: --%"

	if build_title_label != null:
		build_title_label.text = "Escolhe o tipo de casa"

	if mission_label != null:
		mission_label.text = "Missão: ..."

	if pay_bill_button != null:
		pay_bill_button.text = "Pagar primeira conta"

		if not pay_bill_button.pressed.is_connected(_on_pay_bill_button_pressed):
			pay_bill_button.pressed.connect(_on_pay_bill_button_pressed)


func _connect_signals() -> void:
	if not EconomyManager.money_changed.is_connected(_on_money_changed):
		EconomyManager.money_changed.connect(_on_money_changed)

	if not TimeManager.minute_changed.is_connected(_on_time_changed):
		TimeManager.minute_changed.connect(_on_time_changed)

	if not JobManager.job_started.is_connected(_on_job_started):
		JobManager.job_started.connect(_on_job_started)

	if not JobManager.job_progress_updated.is_connected(_on_job_progress_updated):
		JobManager.job_progress_updated.connect(_on_job_progress_updated)

	if not JobManager.job_completed.is_connected(_on_job_completed):
		JobManager.job_completed.connect(_on_job_completed)

	if not JobManager.job_cooldown_started.is_connected(_on_job_cooldown_started):
		JobManager.job_cooldown_started.connect(_on_job_cooldown_started)

	if not FinanceManager.transaction_added.is_connected(_on_finance_changed):
		FinanceManager.transaction_added.connect(_on_finance_changed)

	if not BankManager.bank_balance_changed.is_connected(_on_bank_changed):
		BankManager.bank_balance_changed.connect(_on_bank_changed)

	if not ExpenseManager.expense_pending.is_connected(_on_expense_changed):
		ExpenseManager.expense_pending.connect(_on_expense_changed)

	if not ExpenseManager.expense_charged.is_connected(_on_expense_changed):
		ExpenseManager.expense_charged.connect(_on_expense_changed)

	if not BuildingManager.build_menu_requested.is_connected(_on_build_menu_requested):
		BuildingManager.build_menu_requested.connect(_on_build_menu_requested)

	if not MissionManager.mission_updated.is_connected(_on_mission_updated):
		MissionManager.mission_updated.connect(_on_mission_updated)

	_connect_life_signals()


func _connect_life_signals() -> void:
	var life_manager: Node = get_node_or_null("/root/LifeManager")

	if life_manager == null:
		print("LifeManager ainda não existe. HUD de vida ficará em espera.")
		return

	if life_manager.has_signal("hunger_changed"):
		if not life_manager.hunger_changed.is_connected(_on_hunger_changed):
			life_manager.hunger_changed.connect(_on_hunger_changed)

	if life_manager.has_signal("energy_changed"):
		if not life_manager.energy_changed.is_connected(_on_energy_changed):
			life_manager.energy_changed.connect(_on_energy_changed)


# ============================================================
# HUD BASE
# ============================================================

func _on_mission_updated(mission_text: String) -> void:
	if mission_label != null:
		mission_label.text = mission_text


func _on_money_changed(new_amount: int) -> void:
	if money_label != null:
		money_label.text = "Dinheiro: %s MZN" % new_amount

	update_finance_ui()


func _on_time_changed(_current_minute: int) -> void:
	if time_label != null:
		time_label.text = TimeManager.get_full_time_text()


func _refresh_life_hud() -> void:
	var life_manager: Node = get_node_or_null("/root/LifeManager")

	if life_manager == null:
		return

	var hunger_value: float = 100.0
	var energy_value: float = 100.0

	if "hunger" in life_manager:
		hunger_value = float(life_manager.hunger)

	if "energy" in life_manager:
		energy_value = float(life_manager.energy)

	_on_hunger_changed(hunger_value)
	_on_energy_changed(energy_value)


func _on_hunger_changed(value: float) -> void:
	if hunger_label != null:
		hunger_label.text = "Fome: %d%%" % int(round(value))


func _on_energy_changed(value: float) -> void:
	if energy_label != null:
		energy_label.text = "Energia: %d%%" % int(round(value))


# ============================================================
# FEEDBACK
# ============================================================

func show_feedback(message: String, feedback_type: String = "info") -> void:
	var prefix := ""

	if feedback_type == "success":
		prefix = "✓ "
	elif feedback_type == "error":
		prefix = "✕ "
	elif feedback_type == "warning":
		prefix = "⚠ "
	else:
		prefix = "• "

	if finance_message_label != null:
		finance_message_label.text = prefix + message

	print(prefix + message)
	_clear_feedback_after_delay()


func show_purchase_feedback(result: Dictionary) -> void:
	var success: bool = bool(result.get("success", false))
	var message: String = str(result.get("message", ""))
	var item_name: String = str(result.get("item_name", result.get("item_id", "Item")))
	var total_price: int = int(result.get("total_price", 0))

	if success:
		show_feedback("Compra realizada: %s (-%s MZN)" % [item_name, total_price], "success")
	else:
		if message == "":
			message = "Compra falhou."
		show_feedback(message, "error")

	update_finance_ui()


func show_system_message(message: String) -> void:
	show_feedback(message, "info")


func show_error_message(message: String) -> void:
	show_feedback(message, "error")


func _clear_feedback_after_delay() -> void:
	await get_tree().create_timer(4.0).timeout

	if finance_message_label != null:
		finance_message_label.text = ""


# ============================================================
# BANCO / HOSPITAL
# ============================================================

func open_bank_panel() -> void:
	if bank_panel != null:
		if bank_panel.has_method("open_panel"):
			bank_panel.open_panel()
		else:
			bank_panel.visible = true
	else:
		show_error_message("Erro: BankPanel não existe na UI.")


func close_bank_panel() -> void:
	if bank_panel != null:
		if bank_panel.has_method("close_panel"):
			bank_panel.close_panel()
		else:
			bank_panel.visible = false


func open_hospital_panel() -> void:
	if hospital_panel != null:
		if hospital_panel.has_method("open_panel"):
			hospital_panel.open_panel()
		else:
			hospital_panel.visible = true
	else:
		show_error_message("Erro: HospitalPanel não existe na UI.")


func close_hospital_panel() -> void:
	if hospital_panel != null:
		if hospital_panel.has_method("close_panel"):
			hospital_panel.close_panel()
		else:
			hospital_panel.visible = false


# ============================================================
# BUILD MENU
# ============================================================

func _setup_build_buttons() -> void:
	_setup_single_build_button(btn_simple, BuildingData.HOUSE_SIMPLE, _on_build_simple_pressed)
	_setup_single_build_button(btn_family, BuildingData.HOUSE_FAMILY, _on_build_family_pressed)
	_setup_single_build_button(btn_modern, BuildingData.HOUSE_MODERN, _on_build_modern_pressed)
	_setup_single_build_button(btn_luxury, BuildingData.HOUSE_LUXURY, _on_build_luxury_pressed)


func _setup_single_build_button(button: Button, house_type: String, callback: Callable) -> void:
	if button == null:
		return

	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.focus_mode = Control.FOCUS_ALL

	var house_name: String = BuildingData.get_house_name(house_type)
	var price: int = BuildingData.get_house_price(house_type)
	var rent_value: int = BuildingData.get_house_rent_value(house_type)

	var required_level: String = _get_required_reputation_for_house(house_type)
	var player_level: String = _get_player_reputation_level()
	var unlocked: bool = _has_required_reputation(player_level, required_level)

	if unlocked:
		button.disabled = false
		button.text = "%s - %s MZN | Renda: %s MZN" % [
			house_name,
			price,
			rent_value
		]
	else:
		button.disabled = true
		button.text = "%s 🔒 Requer: %s" % [
			house_name,
			required_level
		]

	if not button.pressed.is_connected(callback):
		button.pressed.connect(callback)


func _on_build_menu_requested(property_id: String) -> void:
	current_build_property_id = property_id
	show_build_menu()


func show_build_menu() -> void:
	if build_menu_panel == null:
		show_feedback("Erro: BuildMenuPanel não existe na cena UI.", "error")
		return

	build_menu_panel.visible = true
	build_menu_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	build_menu_panel.z_index = 999
	build_menu_panel.move_to_front()

	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	if build_title_label != null:
		build_title_label.text = "Escolhe o tipo de casa"

	_setup_build_buttons()

	if btn_simple != null and not btn_simple.disabled:
		btn_simple.grab_focus()

	show_feedback("Escolhe uma casa para construir.", "info")


func hide_build_menu() -> void:
	if build_menu_panel != null:
		build_menu_panel.visible = false

	current_build_property_id = ""

	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _on_build_simple_pressed() -> void:
	_try_build_house(BuildingData.HOUSE_SIMPLE)


func _on_build_family_pressed() -> void:
	_try_build_house(BuildingData.HOUSE_FAMILY)


func _on_build_modern_pressed() -> void:
	_try_build_house(BuildingData.HOUSE_MODERN)


func _on_build_luxury_pressed() -> void:
	_try_build_house(BuildingData.HOUSE_LUXURY)


func _try_build_house(house_type: String) -> void:
	if current_build_property_id == "":
		show_feedback("Nenhum lote selecionado para construção.", "error")
		return

	var house_name: String = BuildingData.get_house_name(house_type)
	var price: int = BuildingData.get_house_price(house_type)

	var required_level: String = _get_required_reputation_for_house(house_type)
	var player_level: String = _get_player_reputation_level()

	if not _has_required_reputation(player_level, required_level):
		show_feedback("Reputação insuficiente para construir %s. Necessário: %s." % [
			house_name,
			required_level
		], "warning")
		_setup_build_buttons()
		return

	if not EconomyManager.has_money(price):
		show_feedback("Dinheiro insuficiente para construir %s." % house_name, "error")
		return

	var success: bool = BuildingManager.build_house(current_build_property_id, house_type)

	if success:
		show_feedback("%s construída com sucesso!" % house_name, "success")
		hide_build_menu()
		update_finance_ui()
	else:
		show_feedback("Erro ao construir %s." % house_name, "error")
		_setup_build_buttons()


# ============================================================
# REPUTAÇÃO - UI BUILD MENU
# ============================================================

func _get_player_reputation_level() -> String:
	var rep = get_node_or_null("/root/ReputationManager")

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


func _has_required_reputation(player_level: String, required_level: String) -> bool:
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
# FINANÇAS
# ============================================================

func toggle_finance() -> void:
	finance_open = not finance_open

	if finance_panel != null:
		finance_panel.visible = finance_open

	if finance_open:
		update_finance_ui()


func show_finance_panel() -> void:
	finance_open = true

	if finance_panel != null:
		finance_panel.visible = true

	update_finance_ui()


func hide_finance_panel() -> void:
	finance_open = false

	if finance_panel != null:
		finance_panel.visible = false


func update_finance_ui() -> void:
	var cash: int = EconomyManager.get_money()
	var bank: int = BankManager.get_balance()
	var total_available: int = cash + bank
	var income: int = FinanceManager.get_total_income()
	var expenses: int = FinanceManager.get_total_expenses()
	var result: int = FinanceManager.get_financial_result()

	if bank_label != null:
		bank_label.text = "Bolso: %s MZN | Banco: %s MZN | Total: %s MZN" % [
			cash,
			bank,
			total_available
		]

	if result_label != null:
		result_label.text = "Entradas: %s MZN\nSaídas: %s MZN\nResultado: %s MZN" % [
			income,
			expenses,
			result
		]

	_update_pending()
	_update_transactions()
	_update_pay_button_state()


func _update_pending() -> void:
	if pending_label == null:
		return

	var bills: Array = ExpenseManager.get_pending_bills()

	if bills.is_empty():
		pending_label.text = "Contas pendentes: nenhuma"
		return

	var text := "Contas pendentes:\n"
	var count := 0

	for bill in bills:
		if count >= 3:
			text += "...mais contas pendentes"
			break

		var description: String = str(bill.get("description", "Conta"))

		if description.length() > 30:
			description = description.substr(0, 30) + "..."

		text += "- %s: %s MZN\n" % [
			description,
			bill.get("amount", 0)
		]

		count += 1

	pending_label.text = text.strip_edges()


func _update_transactions() -> void:
	if transactions_label == null:
		return

	var transactions: Array = FinanceManager.get_recent_transactions(3)

	if transactions.is_empty():
		transactions_label.text = "Últimas transações: nenhuma"
		return

	var text := "Últimas transações:\n"

	for transaction in transactions:
		var transaction_type: String = str(transaction.get("type", ""))
		var symbol := "+" if transaction_type == "income" else "-"
		var description: String = str(transaction.get("description", ""))

		if description.length() > 30:
			description = description.substr(0, 30) + "..."

		text += "%s %s MZN | %s\n" % [
			symbol,
			transaction.get("amount", 0),
			description
		]

	transactions_label.text = text.strip_edges()


func _update_pay_button_state() -> void:
	if pay_bill_button == null:
		return

	var bills: Array = ExpenseManager.get_pending_bills()

	if bills.is_empty():
		pay_bill_button.disabled = true
		pay_bill_button.text = "Sem contas para pagar"
		return

	var first_bill: Dictionary = bills[0]
	var amount: int = int(first_bill.get("amount", 0))
	var total_available: int = EconomyManager.get_money() + BankManager.get_balance()

	pay_bill_button.disabled = false

	if total_available < amount:
		pay_bill_button.text = "Saldo insuficiente (%s MZN)" % amount
	else:
		pay_bill_button.text = "Pagar 1ª conta (%s MZN)" % amount


func _on_pay_bill_button_pressed() -> void:
	_try_pay_first_pending_bill()


func _try_pay_first_pending_bill() -> void:
	if not finance_open:
		show_finance_panel()

	var bills: Array = ExpenseManager.get_pending_bills()

	if bills.is_empty():
		show_feedback("Não há contas pendentes.", "info")
		update_finance_ui()
		return

	var first_bill: Dictionary = bills[0]
	var amount: int = int(first_bill.get("amount", 0))
	var total_available: int = EconomyManager.get_money() + BankManager.get_balance()

	if total_available < amount:
		show_feedback("Saldo insuficiente para pagar a conta.", "error")
		update_finance_ui()
		return

	var success: bool = ExpenseManager.pay_first_pending_bill()

	if success:
		show_feedback("Conta paga automaticamente.", "success")
	else:
		show_feedback("Não foi possível pagar a conta.", "error")

	update_finance_ui()


func _on_finance_changed(_transaction: Dictionary) -> void:
	update_finance_ui()


func _on_bank_changed(_new_balance: int) -> void:
	update_finance_ui()


func _on_expense_changed(_expense_data: Dictionary) -> void:
	update_finance_ui()


# ============================================================
# PROPRIEDADES / LOTES / CASAS
# ============================================================

func show_property_panel(data: Dictionary) -> void:
	if property_panel == null:
		print_property_fallback(data)
		return

	property_panel.visible = true

	var status: String = str(data.get("status", "available"))
	var owner_id: String = str(data.get("owner_id", ""))
	var property_type: String = str(data.get("type", ""))
	var building_status: String = str(data.get("building_status", ""))
	var house_name: String = str(data.get("house_name", ""))

	var owner_text := "Sem dono"

	if owner_id == "player":
		owner_text = "Tu"
	elif owner_id != "":
		owner_text = owner_id

	if property_title_label != null:
		property_title_label.text = str(data.get("name", "Propriedade"))

	if property_status_label != null:
		if building_status == "built" and house_name != "":
			property_status_label.text = "Estado: " + _get_status_text(status) + " | " + house_name
		else:
			property_status_label.text = "Estado: " + _get_status_text(status)

	if property_price_label != null:
		var base_price: int = int(data.get("price", 0))
		var tax: int = TaxManager.calculate_property_purchase_tax(base_price)
		var total: int = base_price + tax

		if _is_lot_type(property_type):
			if status == "sold" and owner_id == "player" and building_status != "built":
				property_price_label.text = "Lote comprado. Escolhe uma casa no menu de construção."
			elif building_status == "built":
				property_price_label.text = "Construção: " + house_name
			else:
				property_price_label.text = "Comprar lote: %s MZN + Imposto %s MZN = %s MZN" % [
					base_price,
					tax,
					total
				]
		else:
			property_price_label.text = "Comprar: %s MZN + Imposto %s MZN = %s MZN" % [
				base_price,
				tax,
				total
			]

	if property_rent_label != null:
		if property_type == "house":
			property_rent_label.text = _get_rent_text(data)
		elif building_status == "built":
			property_rent_label.text = "Aluguer futuro: disponível na próxima fase"
		else:
			property_rent_label.text = "Aluguer: não disponível para lote urbano"

	if property_owner_label != null:
		property_owner_label.text = "Dono: " + owner_text

	if property_action_label != null:
		property_action_label.text = _get_property_action_text(data)


func hide_property_panel() -> void:
	if property_panel != null:
		property_panel.visible = false

	hide_build_menu()


func _is_lot_type(property_type: String) -> bool:
	return property_type == "residential_lot" or property_type == "commercial_lot" or property_type == "urban_lot"


func _get_status_text(status: String) -> String:
	if status == "available":
		return "Disponível"

	if status == "sold":
		return "Comprada"

	if status == "rented":
		return "Alugada"

	return status


func _get_rent_text(data: Dictionary) -> String:
	var status: String = str(data.get("status", "available"))
	var rent_price: int = int(data.get("rent_price", 0))

	if status == "available":
		return "Alugar: " + str(rent_price) + " MZN / 7 dias"

	if status == "rented":
		var rent_end_day: int = int(data.get("rent_end_day", 0))
		var today: int = TimeManager.get_current_day_absolute()
		var days_left: int = max(rent_end_day - today, 0)

		if days_left <= 0:
			return "Aluguer expirado."

		if days_left == 1:
			return "Aluguer: termina amanhã."

		return "Aluguer: faltam %s dias." % days_left

	return "Aluguer: indisponível"


func _get_property_action_text(data: Dictionary) -> String:
	var status: String = str(data.get("status", "available"))
	var owner_id: String = str(data.get("owner_id", ""))
	var property_type: String = str(data.get("type", ""))
	var building_status: String = str(data.get("building_status", ""))

	if _is_lot_type(property_type):
		if status == "available":
			return "E = Comprar lote"

		if status == "sold" and owner_id == "player":
			if building_status == "built":
				return "Casa construída neste lote"
			return "E = Abrir menu de construção"

		if status == "sold":
			return "Lote já pertence a outro jogador"

		if status == "rented":
			return "Lote alugado"

	if property_type == "farm_lot":
		if status == "available":
			return "E = Comprar | R = Alugar terreno agrícola"

		if status == "sold" and owner_id == "player":
			return "Terreno agrícola é teu"

		if status == "rented" and owner_id == "player":
			return "Terreno agrícola alugado por ti"

		if status == "rented":
			return "Terreno agrícola alugado"

	if property_type == "house":
		if status == "available":
			return "E = Comprar | R = Alugar"

		if status == "sold" and owner_id == "player":
			return "Casa é tua | T = Descansar"

		if status == "sold":
			return "Casa pertence a outro jogador"

		if status == "rented" and owner_id == "player":
			return "Casa alugada por ti"

		if status == "rented":
			return "Casa alugada"

	return _get_action_text(data)


func _get_action_text(data: Dictionary) -> String:
	var status: String = str(data.get("status", "available"))
	var owner_id: String = str(data.get("owner_id", ""))

	if status == "available":
		return "E = Comprar | R = Alugar"

	if status == "sold" and owner_id == "player":
		return "Esta propriedade é tua"

	if status == "sold":
		return "Esta propriedade já foi comprada"

	if status == "rented" and owner_id == "player":
		return "Esta propriedade está alugada por ti"

	if status == "rented":
		return "Esta propriedade está alugada"

	return "Pressiona E para interagir"


func print_property_fallback(data: Dictionary) -> void:
	print("")
	print("========== PROPRIEDADE ==========")
	print("Nome: ", data.get("name", "Propriedade"))
	print("Tipo: ", data.get("type", ""))
	print("Comprar: ", data.get("price", 0), " MZN")
	print("Alugar: ", data.get("rent_price", 0), " MZN / 7 dias")
	print("Estado: ", _get_status_text(str(data.get("status", "available"))))
	print("Dono: ", data.get("owner_id", "Sem dono"))
	print(_get_rent_text(data))
	print(_get_property_action_text(data))
	print("=================================")
	print("")


# ============================================================
# EMPREGOS
# ============================================================

func show_job_info(job_data: Dictionary, action_text: String = "") -> void:
	if job_panel == null:
		print_job_fallback(job_data, action_text)
		return

	if job_data.is_empty():
		job_panel.visible = false
		return

	job_panel.visible = true

	var status: String = str(job_data.get("status", "available"))

	if job_title_label != null:
		job_title_label.text = "Emprego: " + str(job_data.get("job_name", "Emprego"))

	if job_status_label != null:
		job_status_label.text = "Estado: " + _get_job_status_text(status)

	if job_progress_label != null:
		var completed: int = int(job_data.get("completed_tasks", 0))
		var required: int = int(job_data.get("required_tasks", 0))
		var percent: int = 0

		if required > 0:
			percent = int(round((float(completed) / float(required)) * 100.0))

		job_progress_label.text = "Progresso: %s / %s (%s%%)" % [
			completed,
			required,
			percent
		]

	if job_reward_label != null:
		var gross_reward: int = int(job_data.get("reward", 0))
		var tax: int = TaxManager.calculate_salary_tax(gross_reward)
		var net: int = gross_reward - tax

		job_reward_label.text = "Pagamento: %s MZN | Imposto: %s | Líquido: %s MZN" % [
			gross_reward,
			tax,
			net
		]

	if job_action_label != null:
		if status == "cooldown":
			job_action_label.text = _get_job_cooldown_text(job_data)
		else:
			job_action_label.text = action_text


func hide_job_info() -> void:
	if job_panel != null:
		job_panel.visible = false


func _on_job_started(job_data: Dictionary) -> void:
	show_job_info(job_data, "Vai recolher os sacos de lixo.")
	show_feedback("Emprego iniciado: " + str(job_data.get("job_name", "Emprego")), "info")


func _on_job_progress_updated(job_data: Dictionary) -> void:
	show_job_info(job_data, "Continua o trabalho.")


func _on_job_completed(job_data: Dictionary) -> void:
	show_job_info(job_data, "Trabalho concluído. Pagamento líquido recebido.")
	show_feedback("Trabalho concluído. Pagamento recebido.", "success")


func _on_job_cooldown_started(job_data: Dictionary) -> void:
	var text: String = _get_job_cooldown_text(job_data)

	show_job_info(job_data, text)
	show_feedback(text, "warning")


func _get_job_status_text(status: String) -> String:
	if status == "available":
		return "Disponível"

	if status == "active":
		return "Em andamento"

	if status == "completed":
		return "Concluído"

	if status == "cooldown":
		return "Em descanso"

	return status


func _get_job_cooldown_text(job_data: Dictionary) -> String:
	var today: int = TimeManager.get_current_day_absolute()
	var cooldown_end_day: int = int(job_data.get("cooldown_end_day", today))
	var days_left: int = max(cooldown_end_day - today, 0)

	if days_left <= 0:
		return "Trabalho disponível novamente."

	if days_left == 1:
		return "Trabalho em descanso até amanhã."

	return "Trabalho em descanso. Faltam %s dias." % days_left


func print_job_fallback(job_data: Dictionary, action_text: String = "") -> void:
	print("")
	print("========== EMPREGO ==========")
	print("Nome: ", job_data.get("job_name", "Emprego"))
	print("Estado: ", _get_job_status_text(str(job_data.get("status", "available"))))
	print("Progresso: ", job_data.get("completed_tasks", 0), " / ", job_data.get("required_tasks", 0))
	print("Pagamento: ", job_data.get("reward", 0), " MZN")
	print("Ação: ", action_text)
	print("=============================")
	print("")

extends Control

# ============================================================
# UAIDE CITY - HOSPITAL PANEL PRO
# UI funcional do hospital com impacto da reputação
# ============================================================

@export var treatment_cost: int = 50

@onready var title_label: Label = get_node_or_null("Panel/VBoxContainer/TitleLabel")
@onready var status_label: Label = get_node_or_null("Panel/VBoxContainer/StatusLabel")
@onready var cost_label: Label = get_node_or_null("Panel/VBoxContainer/CostLabel")
@onready var treat_button: Button = get_node_or_null("Panel/VBoxContainer/TreatButton")
@onready var close_button: Button = get_node_or_null("Panel/VBoxContainer/CloseButton")


func _ready() -> void:
	visible = false

	if title_label != null:
		title_label.text = "Hospital"

	if treat_button != null:
		treat_button.text = "Receber atendimento"
		if not treat_button.pressed.is_connected(_on_treat_pressed):
			treat_button.pressed.connect(_on_treat_pressed)

	if close_button != null:
		close_button.text = "Fechar"
		if not close_button.pressed.is_connected(_on_close_pressed):
			close_button.pressed.connect(_on_close_pressed)

	refresh()


func open_panel() -> void:
	visible = true
	refresh()


func close_panel() -> void:
	visible = false


# ============================================================
# PREÇO DINÂMICO POR REPUTAÇÃO
# ============================================================

func get_reputation_level() -> String:
	var reputation_manager = get_node_or_null("/root/ReputationManager")

	if reputation_manager == null:
		return "Desconhecido"

	if reputation_manager.has_method("get_reputation_level"):
		return str(reputation_manager.get_reputation_level())

	return "Desconhecido"


func get_reputation_multiplier() -> float:
	var level: String = get_reputation_level()

	match level:
		"Suspeito":
			return 1.50
		"Conhecido":
			return 0.95
		"Respeitado":
			return 0.90
		"Influente":
			return 0.85
		"Elite da Cidade":
			return 0.75
		_:
			return 1.00


func get_final_treatment_cost() -> int:
	var final_cost: int = int(round(float(treatment_cost) * get_reputation_multiplier()))

	if final_cost < 1:
		final_cost = 1

	return final_cost


func get_reputation_price_text() -> String:
	var level: String = get_reputation_level()

	match level:
		"Suspeito":
			return "Reputação: Suspeito (+50%)"
		"Conhecido":
			return "Reputação: Conhecido (-5%)"
		"Respeitado":
			return "Reputação: Respeitado (-10%)"
		"Influente":
			return "Reputação: Influente (-15%)"
		"Elite da Cidade":
			return "Reputação: Elite da Cidade (-25%)"
		_:
			return "Reputação: Desconhecido (preço normal)"


# ============================================================
# REFRESH UI
# ============================================================

func refresh() -> void:
	var life = get_node_or_null("/root/LifeManager")

	if life == null:
		if status_label != null:
			status_label.text = "Erro: sistema de vida não encontrado."

		if cost_label != null:
			cost_label.text = "Custo: indisponível"

		if treat_button != null:
			treat_button.disabled = true

		return

	var energy_value: float = 100.0
	var hunger_value: float = 100.0

	if "energy" in life:
		energy_value = float(life.energy)

	if "hunger" in life:
		hunger_value = float(life.hunger)

	if status_label != null:
		status_label.text = "Energia: %d%%\nFome: %d%%" % [
			int(round(energy_value)),
			int(round(hunger_value))
		]

	var final_cost: int = get_final_treatment_cost()

	if cost_label != null:
		cost_label.text = "Custo: %s MZN\n%s" % [
			final_cost,
			get_reputation_price_text()
		]

	if treat_button != null:
		if EconomyManager.get_money() < final_cost:
			treat_button.disabled = true
			treat_button.text = "Dinheiro insuficiente"
		else:
			treat_button.disabled = false
			treat_button.text = "Receber atendimento"


# ============================================================
# AÇÃO DO BOTÃO
# ============================================================

func _on_treat_pressed() -> void:
	var final_cost: int = get_final_treatment_cost()

	if not EconomyManager.has_money(final_cost):
		refresh()
		return

	var life = get_node_or_null("/root/LifeManager")

	if life == null:
		refresh()
		return

	var paid: bool = EconomyManager.spend_money(final_cost)

	if not paid:
		refresh()
		return

	if "energy" in life:
		life.energy = 100.0

	if "hunger" in life:
		life.hunger = 100.0

	if life.has_signal("energy_changed"):
		life.energy_changed.emit(float(life.energy))

	if life.has_signal("hunger_changed"):
		life.hunger_changed.emit(float(life.hunger))

	var ui = get_tree().get_first_node_in_group("ui")

	if ui != null and ui.has_method("show_system_message"):
		ui.show_system_message("Atendimento concluído por %s MZN." % final_cost)

	refresh()


func _on_close_pressed() -> void:
	close_panel()

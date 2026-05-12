extends Control

@onready var delivery_panel: Panel = $MarginContainer/DeliveryPanel
@onready var title_label: Label = $MarginContainer/DeliveryPanel/VBoxContainer/TitleLabel
@onready var destination_label: Label = $MarginContainer/DeliveryPanel/VBoxContainer/DestinationLabel
@onready var distance_label: Label = $MarginContainer/DeliveryPanel/VBoxContainer/DistanceLabel
@onready var time_label: Label = $MarginContainer/DeliveryPanel/VBoxContainer/TimeLabel
@onready var reward_label: Label = $MarginContainer/DeliveryPanel/VBoxContainer/RewardLabel
@onready var hint_label: Label = $MarginContainer/DeliveryPanel/VBoxContainer/HintLabel


func _ready() -> void:
	visible = true
	delivery_panel.visible = false

	if not DeliveryManager.delivery_started.is_connected(_on_delivery_started):
		DeliveryManager.delivery_started.connect(_on_delivery_started)

	if not DeliveryManager.delivery_updated.is_connected(_on_delivery_updated):
		DeliveryManager.delivery_updated.connect(_on_delivery_updated)

	if not DeliveryManager.delivery_completed.is_connected(_on_delivery_completed):
		DeliveryManager.delivery_completed.connect(_on_delivery_completed)

	if not DeliveryManager.delivery_failed.is_connected(_on_delivery_failed):
		DeliveryManager.delivery_failed.connect(_on_delivery_failed)

	if not DeliveryManager.delivery_cancelled.is_connected(_on_delivery_cancelled):
		DeliveryManager.delivery_cancelled.connect(_on_delivery_cancelled)

	_clear_ui()


func _process(_delta: float) -> void:
	if not DeliveryManager.has_active_delivery():
		return

	var player: Node3D = get_tree().get_first_node_in_group("player") as Node3D

	if player != null:
		DeliveryManager.update_delivery_distance(player.global_position)

	if Input.is_action_just_pressed("cancel_delivery"):
		DeliveryManager.cancel_delivery()


func _on_delivery_started(destination_name: String, reward_money: int, reward_reputation: int, time_limit: int) -> void:
	delivery_panel.visible = true
	title_label.text = "ENTREGA ATIVA"
	destination_label.text = "Destino: " + destination_name
	distance_label.text = "Distância: calculando..."
	time_label.text = "Tempo: " + str(time_limit) + "s"
	reward_label.text = "Recompensa: " + str(reward_money) + " MZN | +" + str(reward_reputation) + " REP"
	hint_label.text = "Cancelar: Q"


func _on_delivery_updated(destination_name: String, distance: float, reward_money: int, time_left: int) -> void:
	if not delivery_panel.visible:
		return

	destination_label.text = "Destino: " + destination_name
	distance_label.text = "Distância: " + str(int(distance)) + "m"

	if time_left <= 10:
		time_label.text = "Tempo: " + str(time_left) + "s ⚠"
	else:
		time_label.text = "Tempo: " + str(time_left) + "s"

	reward_label.text = "Recompensa: " + str(reward_money) + " MZN"


func _on_delivery_completed(destination_name: String, reward_money: int, reward_reputation: int, bonus_money: int, bonus_reputation: int) -> void:
	if bonus_money > 0 or bonus_reputation > 0:
		print("Entrega concluída com bónus rápido:", bonus_money, "MZN +", bonus_reputation, "REP")
	else:
		print("Entrega concluída:", destination_name)

	delivery_panel.visible = false
	_clear_ui()


func _on_delivery_failed(destination_name: String) -> void:
	print("Entrega falhou:", destination_name)
	delivery_panel.visible = false
	_clear_ui()


func _on_delivery_cancelled() -> void:
	print("Entrega cancelada.")
	delivery_panel.visible = false
	_clear_ui()


func _clear_ui() -> void:
	title_label.text = "ENTREGA"
	destination_label.text = ""
	distance_label.text = ""
	time_label.text = ""
	reward_label.text = ""
	hint_label.text = ""

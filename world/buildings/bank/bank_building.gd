extends Node3D

# ============================================================
# UAIDE CITY - BANK BUILDING
# Prédio físico do banco
# ============================================================

@onready var bank_area: Area3D = $BankArea

var player_inside: bool = false


func _ready() -> void:
	if not bank_area.body_entered.is_connected(_on_body_entered):
		bank_area.body_entered.connect(_on_body_entered)

	if not bank_area.body_exited.is_connected(_on_body_exited):
		bank_area.body_exited.connect(_on_body_exited)


func _process(_delta: float) -> void:
	if player_inside and Input.is_action_just_pressed("interact"):
		open_bank()


func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		player_inside = true
		print("Entraste no banco. Pressiona E para abrir.")


func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		player_inside = false
		print("Saíste do banco.")


func open_bank() -> void:
	var ui: Node = get_tree().get_first_node_in_group("ui")

	if ui == null:
		push_warning("BankBuilding: UI não encontrada no grupo 'ui'.")
		return

	if ui.has_method("open_bank_panel"):
		ui.open_bank_panel()
	else:
		push_warning("BankBuilding: ui.gd não tem método open_bank_panel().")

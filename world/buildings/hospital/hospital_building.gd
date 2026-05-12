extends Node3D

# ============================================================
# UAIDE CITY - HOSPITAL BUILDING
# Abre UI do hospital ao pressionar E
# ============================================================

@onready var hospital_area: Area3D = $HospitalArea

var player_inside: bool = false


func _ready() -> void:
	if not hospital_area.body_entered.is_connected(_on_body_entered):
		hospital_area.body_entered.connect(_on_body_entered)

	if not hospital_area.body_exited.is_connected(_on_body_exited):
		hospital_area.body_exited.connect(_on_body_exited)


func _process(_delta: float) -> void:
	if player_inside and Input.is_action_just_pressed("interact"):
		open_hospital()


func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		player_inside = true
		print("Entraste no hospital. Pressiona E para abrir.")


func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		player_inside = false
		print("Saíste do hospital.")


func open_hospital() -> void:
	var ui: Node = get_tree().get_first_node_in_group("ui")

	if ui == null:
		push_warning("UI não encontrada.")
		return

	if ui.has_method("open_hospital_panel"):
		ui.open_hospital_panel()
	else:
		push_warning("Função open_hospital_panel não existe.")

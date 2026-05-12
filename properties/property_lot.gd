extends Node3D

@export var property_id: String = "lot_01"
@export var property_name: String = "Lote Residencial"
@export var property_price: int = 500
@export var property_type: String = "residential_lot"

@export var house_scene: PackedScene

@export var available_color: Color = Color("#7A9E4B")
@export var owned_empty_color: Color = Color("#D4A017")
@export var built_color: Color = Color("#8B5E3C")
@export var rented_color: Color = Color("#2F80ED")

@onready var area: Area3D = $LotArea
@onready var delivery_marker: Node3D = get_node_or_null("DeliveryMarker")

var player_inside: bool = false
var house_instance: Node3D = null
var is_delivery_target: bool = false


func _ready() -> void:
	register_lot_if_needed()

	if not is_in_group("delivery_points"):
		add_to_group("delivery_points")

	if delivery_marker != null:
		delivery_marker.visible = false

	if not area.body_entered.is_connected(_on_body_entered):
		area.body_entered.connect(_on_body_entered)

	if not area.body_exited.is_connected(_on_body_exited):
		area.body_exited.connect(_on_body_exited)

	if not PropertyManager.property_updated.is_connected(_on_property_updated):
		PropertyManager.property_updated.connect(_on_property_updated)

	if not BuildingManager.house_built.is_connected(_on_house_built):
		BuildingManager.house_built.connect(_on_house_built)

	load_existing_building()
	update_visual_state()


func _process(_delta: float) -> void:
	if player_inside and Input.is_action_just_pressed("interact"):
		interact()


# ============================================================
# REGISTO DO LOTE
# ============================================================

func register_lot_if_needed() -> void:
	PropertyManager.register_property(property_id, {
		"name": property_name,
		"type": property_type,
		"price": property_price,
		"rent_price": 0,
		"construction_price": 0
	})


# ============================================================
# ENTRADA / SAÍDA DO PLAYER
# ============================================================

func _on_body_entered(body: Node) -> void:
	if body.name == "Player" or body.is_in_group("player"):
		player_inside = true
		complete_delivery_if_possible(body)
		show_lot_ui()


func _on_body_exited(body: Node) -> void:
	if body.name == "Player" or body.is_in_group("player"):
		player_inside = false
		hide_lot_ui()


# ============================================================
# INTERAÇÃO
# ============================================================

func interact() -> void:
	if not PropertyManager.has_property(property_id):
		buy_lot()
		return

	if BuildingManager.has_building(property_id):
		show_message("Este lote já tem uma casa construída.")
		return

	BuildingManager.open_build_menu(property_id)


func buy_lot() -> void:
	var result: Dictionary = PropertyManager.buy_property(property_id)

	show_message(str(result.get("message", "")))

	if result.get("success", false):
		update_visual_state()
		show_lot_ui()


# ============================================================
# DELIVERY
# ============================================================

func activate_delivery() -> void:
	is_delivery_target = true

	if delivery_marker != null:
		delivery_marker.visible = true
	else:
		push_warning("DeliveryMarker não encontrado no lote: " + property_id)

	show_message("Nova entrega: " + property_name)
	print("Entrega ativa neste lote:", property_id)


func deactivate_delivery() -> void:
	is_delivery_target = false

	if delivery_marker != null:
		delivery_marker.visible = false


func complete_delivery_if_possible(body: Node) -> void:
	if not is_delivery_target:
		return

	if body.name != "Player" and not body.is_in_group("player"):
		return

	print("Entrega realizada no lote:", property_id)

	deactivate_delivery()

	if DeliveryManager.has_method("complete_delivery"):
		DeliveryManager.complete_delivery()


# ============================================================
# CONSTRUÇÃO RECEBIDA DO BUILDING MANAGER
# ============================================================

func _on_house_built(updated_property_id: String, house_type: String) -> void:
	if updated_property_id != property_id:
		return

	spawn_house(house_type)
	update_visual_state()

	if player_inside:
		show_lot_ui()


func load_existing_building() -> void:
	if not BuildingManager.has_building(property_id):
		return

	var house_type: String = BuildingManager.get_house_type(property_id)
	spawn_house(house_type)


func spawn_house(house_type: String) -> void:
	if house_instance != null:
		house_instance.queue_free()
		house_instance = null

	var scene_to_use: PackedScene = house_scene
	var scene_path: String = BuildingData.get_house_scene_path(house_type)

	if scene_path != "" and ResourceLoader.exists(scene_path):
		scene_to_use = load(scene_path)

	if scene_to_use == null:
		show_message("Erro: cena da casa não definida para " + house_type)
		return

	house_instance = scene_to_use.instantiate()
	add_child(house_instance)
	house_instance.position = Vector3.ZERO


# ============================================================
# UI
# ============================================================

func show_lot_ui() -> void:
	var data: Dictionary = PropertyManager.get_property(property_id)

	if data.is_empty():
		return

	if BuildingManager.has_building(property_id):
		var house_type: String = BuildingManager.get_house_type(property_id)
		data["building_status"] = "built"
		data["house_type"] = house_type
		data["house_name"] = BuildingData.get_house_name(house_type)
	else:
		data["building_status"] = "empty"
		data["house_type"] = ""
		data["house_name"] = ""

	data["is_delivery_target"] = is_delivery_target

	var ui := get_tree().get_first_node_in_group("ui")

	if ui != null and ui.has_method("show_property_panel"):
		ui.show_property_panel(data)
	else:
		print(data)


func hide_lot_ui() -> void:
	var ui := get_tree().get_first_node_in_group("ui")

	if ui != null and ui.has_method("hide_property_panel"):
		ui.hide_property_panel()


func show_message(message: String) -> void:
	var ui := get_tree().get_first_node_in_group("ui")

	if ui != null and ui.has_method("show_system_message"):
		ui.show_system_message(message)
	else:
		print(message)


# ============================================================
# ATUALIZAÇÕES
# ============================================================

func _on_property_updated(updated_property_id: String) -> void:
	if updated_property_id == property_id:
		update_visual_state()

		if player_inside:
			show_lot_ui()


func update_visual_state() -> void:
	var data: Dictionary = PropertyManager.get_property(property_id)

	if data.is_empty():
		apply_color(available_color)
		return

	var status: String = str(data.get("status", "available"))

	if status == "sold":
		if BuildingManager.has_building(property_id):
			apply_color(built_color)
		else:
			apply_color(owned_empty_color)
	elif status == "rented":
		apply_color(rented_color)
	else:
		apply_color(available_color)


func apply_color(color: Color) -> void:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 1.0
	material.metallic = 0.0

	var mesh_instance: MeshInstance3D = get_node_or_null(".") as MeshInstance3D

	if mesh_instance == null:
		mesh_instance = find_child("*", true, false) as MeshInstance3D

	if mesh_instance == null:
		push_warning("Nenhum MeshInstance3D encontrado no lote: " + property_id)
		return

	mesh_instance.material_override = material

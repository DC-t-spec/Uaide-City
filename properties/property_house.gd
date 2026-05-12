extends Node3D

@export var rest_energy_amount: float = 30.0
@export var rest_cooldown_seconds: float = 3.0
@export var push_force: float = 8.0
@export var push_distance: float = 1.5

@export_enum("simple", "family", "modern", "luxury")
var house_visual_type: String = "simple"

@onready var house_mesh: Node3D = $HouseMesh
@onready var interaction_area: Area3D = $InteractionArea
@onready var entry_area: Area3D = get_node_or_null("EntryArea")

var player_inside: bool = false
var can_rest: bool = true
var parent_lot: Node = null


func _ready() -> void:
	parent_lot = get_parent()

	if interaction_area != null:
		if not interaction_area.body_entered.is_connected(_on_body_entered):
			interaction_area.body_entered.connect(_on_body_entered)

		if not interaction_area.body_exited.is_connected(_on_body_exited):
			interaction_area.body_exited.connect(_on_body_exited)

	if entry_area != null:
		if not entry_area.body_entered.is_connected(_on_entry_area_body_entered):
			entry_area.body_entered.connect(_on_entry_area_body_entered)

	_apply_house_type_from_building_manager()
	build_house_visual()

	print("Casa ativada:", house_visual_type)


func _process(_delta: float) -> void:
	if player_inside and Input.is_action_just_pressed("rest"):
		try_rest()


func _apply_house_type_from_building_manager() -> void:
	if parent_lot == null:
		return

	if not "property_id" in parent_lot:
		return

	var property_id: String = str(parent_lot.property_id)
	var saved_house_type: String = BuildingManager.get_house_type(property_id)

	match saved_house_type:
		"house_simple":
			house_visual_type = "simple"
		"house_family":
			house_visual_type = "family"
		"house_modern":
			house_visual_type = "modern"
		"house_luxury":
			house_visual_type = "luxury"


func build_house_visual() -> void:
	if house_mesh == null:
		return

	for child in house_mesh.get_children():
		child.queue_free()

	match house_visual_type:
		"simple":
			_build_simple_house()
		"family":
			_build_family_house()
		"modern":
			_build_modern_house()
		"luxury":
			_build_luxury_house()
		_:
			_build_simple_house()


# =========================================================
# CASA SIMPLES
# =========================================================

func _build_simple_house() -> void:
	var root := Node3D.new()
	root.name = "SimpleHouse"
	house_mesh.add_child(root)

	_create_box(root, "Body", Vector3(8.0, 3.0, 7.0), Vector3(0, 1.5, 0), Color("#5FAFD3"))
	_create_box(root, "Roof", Vector3(9.0, 0.35, 7.8), Vector3(0, 3.15, -0.05), Color("#F2F2EC"), Vector3(deg_to_rad(-8), 0, 0))

	_create_box(root, "Door", Vector3(1.1, 2.0, 0.12), Vector3(0, 1.0, -3.58), Color("#F4F0E6"))
	_create_box(root, "WindowLeft", Vector3(1.4, 1.0, 0.1), Vector3(-2.4, 1.7, -3.6), Color("#1F2B30"))
	_create_box(root, "WindowRight", Vector3(1.4, 1.0, 0.1), Vector3(2.4, 1.7, -3.6), Color("#1F2B30"))

	_create_window_frame(root, Vector3(-2.4, 1.7, -3.7))
	_create_window_frame(root, Vector3(2.4, 1.7, -3.7))

	_create_box(root, "Steps", Vector3(2.4, 0.2, 1.2), Vector3(0, 0.1, -4.15), Color("#D9D9D9"))


# =========================================================
# CASA FAMILIAR — CONFORTÁVEL
# =========================================================

func _build_family_house() -> void:
	var root := Node3D.new()
	root.name = "FamilyHouse_Option2"
	house_mesh.add_child(root)

	_create_box(root, "MainBody", Vector3(8.8, 3.2, 7.2), Vector3(-1.0, 1.6, 0), Color("#D8C2A3"))
	_create_box(root, "GarageBody", Vector3(3.6, 3.0, 5.2), Vector3(4.2, 1.5, 0.8), Color("#C9AD8A"))
	_create_box(root, "GarageDoor", Vector3(2.6, 2.0, 0.14), Vector3(4.2, 1.05, -1.85), Color("#4A3A2D"))

	_create_gable_roof(root, "MainGableRoof", Vector3(10.0, 1.4, 8.2), Vector3(-1.0, 3.55, 0), Color("#4A2E1F"))
	_create_gable_roof(root, "GarageGableRoof", Vector3(4.4, 1.1, 6.0), Vector3(4.2, 3.35, 0.8), Color("#3A2519"))

	_create_box(root, "PorchFloor", Vector3(4.8, 0.22, 1.6), Vector3(-1.8, 0.12, -4.2), Color("#D8D1C4"))
	_create_box(root, "PorchRoof", Vector3(5.2, 0.28, 1.8), Vector3(-1.8, 2.85, -4.25), Color("#5B3A24"))

	_create_box(root, "PorchColumnLeft", Vector3(0.18, 2.5, 0.18), Vector3(-4.0, 1.35, -4.25), Color("#F1E6D4"))
	_create_box(root, "PorchColumnRight", Vector3(0.18, 2.5, 0.18), Vector3(0.4, 1.35, -4.25), Color("#F1E6D4"))

	_create_box(root, "FrontDoor", Vector3(1.15, 2.15, 0.14), Vector3(-1.8, 1.1, -3.72), Color("#4C2F1E"))
	_create_box(root, "WindowLeft", Vector3(1.45, 1.05, 0.12), Vector3(-4.5, 1.85, -3.72), Color("#18242B"))
	_create_box(root, "WindowRight", Vector3(1.45, 1.05, 0.12), Vector3(1.2, 1.85, -3.72), Color("#18242B"))

	_create_window_frame(root, Vector3(-4.5, 1.85, -3.82))
	_create_window_frame(root, Vector3(1.2, 1.85, -3.82))

	_create_box(root, "StepWide", Vector3(3.8, 0.18, 1.1), Vector3(-1.8, 0.1, -5.0), Color("#CEC7BC"))
	_create_box(root, "Driveway", Vector3(3.3, 0.08, 5.0), Vector3(4.2, 0.04, -4.6), Color("#9E9E9E"))

	_create_box(root, "WallLightLeft", Vector3(0.18, 0.35, 0.12), Vector3(-3.1, 2.1, -3.82), Color("#FFD27D"))
	_create_box(root, "WallLightRight", Vector3(0.18, 0.35, 0.12), Vector3(-0.5, 2.1, -3.82), Color("#FFD27D"))
	_create_box(root, "Chimney", Vector3(0.55, 1.3, 0.55), Vector3(1.8, 4.15, 1.5), Color("#5A3824"))


# =========================================================
# CASA MODERNA — PRO / OPÇÃO 2
# =========================================================

func _build_modern_house() -> void:
	var root := Node3D.new()
	root.name = "ModernHouse_Pro"
	house_mesh.add_child(root)

	_create_box(root, "MainWhiteVolume", Vector3(8.6, 3.4, 6.8), Vector3(-0.8, 1.7, 0.1), Color("#ECEAE4"))
	_create_box(root, "LeftDarkTower", Vector3(3.0, 4.9, 6.6), Vector3(-3.6, 2.45, 0.2), Color("#24282B"))
	_create_box(root, "StoneFeatureWall", Vector3(1.7, 4.7, 0.7), Vector3(-0.4, 2.35, -3.35), Color("#746B61"))

	_create_box(root, "RightGarageMass", Vector3(3.8, 3.0, 5.4), Vector3(4.0, 1.5, 0.9), Color("#D8D4CC"))
	_create_box(root, "GarageDoor", Vector3(2.9, 2.0, 0.12), Vector3(4.0, 1.05, -1.9), Color("#25282A"))

	_create_box(root, "MainFlatRoof", Vector3(9.4, 0.35, 7.6), Vector3(-0.8, 3.55, 0.1), Color("#F8F6EF"))
	_create_box(root, "GarageFlatRoof", Vector3(4.2, 0.32, 5.9), Vector3(4.0, 3.1, 0.9), Color("#F8F6EF"))
	_create_box(root, "FrontFloatingCanopy", Vector3(6.8, 0.28, 1.35), Vector3(-1.0, 3.05, -4.0), Color("#F8F6EF"))

	_create_box(root, "TallGlassLeft", Vector3(1.9, 2.7, 0.12), Vector3(-3.6, 1.9, -3.62), Color("#13242B"))
	_create_box(root, "TallGlassCenter", Vector3(1.4, 3.25, 0.12), Vector3(-0.4, 2.15, -3.78), Color("#13242B"))
	_create_box(root, "RightWindow", Vector3(1.5, 1.25, 0.12), Vector3(1.7, 1.95, -3.62), Color("#13242B"))

	_create_window_frame(root, Vector3(-3.6, 1.9, -3.73))
	_create_window_frame(root, Vector3(1.7, 1.95, -3.73))

	_create_box(root, "WoodMainDoor", Vector3(1.1, 2.25, 0.14), Vector3(-1.55, 1.12, -3.74), Color("#734A2B"))
	_create_box(root, "DoorGlassStrip", Vector3(0.28, 2.05, 0.13), Vector3(-0.85, 1.15, -3.76), Color("#162B33"))

	_create_box(root, "WideEntryPlatform", Vector3(5.2, 0.18, 1.8), Vector3(-1.45, 0.09, -4.65), Color("#DAD7D0"))
	_create_box(root, "FrontStep", Vector3(4.2, 0.16, 0.9), Vector3(-1.45, 0.28, -5.05), Color("#C8C5BE"))

	_create_box(root, "WoodAccentVertical", Vector3(0.18, 2.6, 0.14), Vector3(-2.2, 1.5, -3.76), Color("#8A5A35"))
	_create_box(root, "PlanterLeft", Vector3(1.4, 0.38, 0.6), Vector3(-4.9, 0.2, -4.3), Color("#4E3F33"))
	_create_box(root, "PlanterRight", Vector3(1.4, 0.38, 0.6), Vector3(1.7, 0.2, -4.3), Color("#4E3F33"))

	_create_sphere(root, "PlantLeft", 0.45, Vector3(-4.9, 0.75, -4.3), Color("#3FAF6C"))
	_create_sphere(root, "PlantRight", 0.45, Vector3(1.7, 0.75, -4.3), Color("#3FAF6C"))

	_create_box(root, "WarmLightLeft", Vector3(0.16, 0.32, 0.1), Vector3(-2.2, 2.6, -3.82), Color("#FFD27D"))
	_create_box(root, "WarmLightRight", Vector3(0.16, 0.32, 0.1), Vector3(1.0, 2.6, -3.82), Color("#FFD27D"))


# =========================================================
# CASA LUXO — PRO / MANSÃO MODERNA
# =========================================================

func _build_luxury_house() -> void:
	var root := Node3D.new()
	root.name = "LuxuryHouse_Pro"
	house_mesh.add_child(root)

	_create_box(root, "GroundFloorMain", Vector3(10.6, 3.3, 7.6), Vector3(0, 1.65, 0), Color("#DCD4C8"))
	_create_box(root, "UpperFloorMain", Vector3(8.8, 3.0, 6.3), Vector3(-0.2, 4.95, 0.25), Color("#ECE5DA"))

	_create_box(root, "LeftPremiumDarkBlock", Vector3(3.0, 6.0, 6.2), Vector3(-4.4, 3.0, 0.3), Color("#252525"))
	_create_box(root, "RightStoneBlock", Vector3(2.4, 5.2, 6.0), Vector3(4.2, 2.6, 0.55), Color("#766C60"))

	_create_box(root, "LuxuryGarageBlock", Vector3(3.6, 2.9, 5.0), Vector3(5.5, 1.45, 0.8), Color("#CFC7BC"))
	_create_box(root, "LuxuryGarageDoor", Vector3(2.8, 2.0, 0.12), Vector3(5.5, 1.05, -1.85), Color("#202020"))

	_create_box(root, "MainRoofSlab", Vector3(11.4, 0.35, 8.2), Vector3(0, 6.55, 0.25), Color("#F7F2E8"))
	_create_box(root, "LuxuryLowerCanopy", Vector3(8.0, 0.3, 1.45), Vector3(-0.5, 3.25, -4.15), Color("#F7F2E8"))
	_create_box(root, "GarageRoof", Vector3(4.0, 0.3, 5.5), Vector3(5.5, 3.05, 0.8), Color("#F7F2E8"))

	_create_box(root, "BalconyFloor", Vector3(6.8, 0.25, 1.4), Vector3(-0.4, 3.55, -3.85), Color("#C9C3B8"))
	_create_box(root, "BalconyGlassFront", Vector3(6.5, 0.75, 0.12), Vector3(-0.4, 4.05, -4.55), Color("#AFC8D0"))
	_create_box(root, "BalconyLeftSide", Vector3(0.12, 0.75, 1.1), Vector3(-3.75, 4.05, -4.0), Color("#AFC8D0"))
	_create_box(root, "BalconyRightSide", Vector3(0.12, 0.75, 1.1), Vector3(2.95, 4.05, -4.0), Color("#AFC8D0"))

	_create_box(root, "GroundGlassLeft", Vector3(2.1, 2.35, 0.12), Vector3(-2.6, 1.85, -3.92), Color("#142329"))
	_create_box(root, "GroundGlassRight", Vector3(2.1, 2.35, 0.12), Vector3(2.1, 1.85, -3.92), Color("#142329"))
	_create_box(root, "UpperGlassLeft", Vector3(2.0, 2.1, 0.12), Vector3(-2.4, 5.1, -3.15), Color("#142329"))
	_create_box(root, "UpperGlassRight", Vector3(2.0, 2.1, 0.12), Vector3(1.8, 5.1, -3.15), Color("#142329"))

	_create_box(root, "LuxuryDoor", Vector3(1.35, 2.45, 0.14), Vector3(-0.25, 1.22, -4.02), Color("#5A3422"))
	_create_box(root, "DoorSideGlassLeft", Vector3(0.35, 2.3, 0.12), Vector3(-1.15, 1.22, -4.05), Color("#142329"))
	_create_box(root, "DoorSideGlassRight", Vector3(0.35, 2.3, 0.12), Vector3(0.65, 1.22, -4.05), Color("#142329"))

	_create_box(root, "LuxuryPlatform", Vector3(6.8, 0.2, 2.1), Vector3(-0.25, 0.1, -5.05), Color("#DAD5CC"))
	_create_box(root, "LuxuryStepFront", Vector3(5.8, 0.16, 1.0), Vector3(-0.25, 0.3, -5.6), Color("#C7C1B8"))
	_create_box(root, "LuxuryDriveway", Vector3(3.8, 0.08, 5.5), Vector3(5.5, 0.04, -4.8), Color("#A8A8A8"))

	_create_box(root, "ColumnLeft", Vector3(0.3, 3.2, 0.3), Vector3(-3.7, 1.65, -4.15), Color("#EFE6D9"))
	_create_box(root, "ColumnRight", Vector3(0.3, 3.2, 0.3), Vector3(3.2, 1.65, -4.15), Color("#EFE6D9"))

	_create_box(root, "LowWallLeft", Vector3(2.5, 0.7, 0.28), Vector3(-5.2, 0.35, -5.15), Color("#DCD4C8"))
	_create_box(root, "LowWallRight", Vector3(2.5, 0.7, 0.28), Vector3(4.5, 0.35, -5.15), Color("#DCD4C8"))

	_create_box(root, "GateLeft", Vector3(0.18, 1.2, 0.18), Vector3(-1.7, 0.65, -5.25), Color("#202020"))
	_create_box(root, "GateRight", Vector3(0.18, 1.2, 0.18), Vector3(1.2, 0.65, -5.25), Color("#202020"))
	_create_box(root, "GateBar", Vector3(2.9, 0.12, 0.12), Vector3(-0.25, 1.1, -5.25), Color("#202020"))

	_create_box(root, "LuxuryLightLeft", Vector3(0.18, 0.4, 0.12), Vector3(-1.55, 2.55, -4.15), Color("#FFD27D"))
	_create_box(root, "LuxuryLightRight", Vector3(0.18, 0.4, 0.12), Vector3(1.05, 2.55, -4.15), Color("#FFD27D"))

	_create_cylinder(root, "PalmLeft", 0.14, 2.8, Vector3(-6.0, 1.4, -4.6), Color("#6B4F2B"))
	_create_cylinder(root, "PalmRight", 0.14, 2.8, Vector3(6.9, 1.4, -4.6), Color("#6B4F2B"))
	_create_sphere(root, "PalmLeavesLeft", 1.0, Vector3(-6.0, 3.45, -4.6), Color("#3FAF6C"))
	_create_sphere(root, "PalmLeavesRight", 1.0, Vector3(6.9, 3.45, -4.6), Color("#3FAF6C"))


# =========================================================
# INTERAÇÃO
# =========================================================

func _on_body_entered(body: Node) -> void:
	if not _is_player(body):
		return

	player_inside = true

	if _player_can_use_house():
		show_message("T = Descansar em casa")
	else:
		show_message("Esta casa não te pertence.")


func _on_body_exited(body: Node) -> void:
	if _is_player(body):
		player_inside = false


func _is_player(body: Node) -> bool:
	return body.name == "Player" or body.is_in_group("player")


func _on_entry_area_body_entered(body: Node) -> void:
	if not _is_player(body):
		return

	if not _player_can_use_house():
		show_message("Entrada bloqueada. Esta casa não te pertence.")
		_push_player_away(body)


func _player_can_use_house() -> bool:
	if parent_lot == null:
		return false

	if not "property_id" in parent_lot:
		return false

	return PropertyManager.has_property(parent_lot.property_id)


func _push_player_away(body: Node) -> void:
	var push_direction: Vector3 = body.global_position - global_position
	push_direction.y = 0.0

	if push_direction.length() <= 0.01:
		push_direction = Vector3.BACK
	else:
		push_direction = push_direction.normalized()

	if "velocity" in body:
		body.velocity = push_direction * push_force

	body.global_position += push_direction * push_distance


func try_rest() -> void:
	if not _player_can_use_house():
		show_message("Só podes descansar numa casa tua.")
		return

	if not can_rest:
		show_message("Aguarda um pouco antes de descansar novamente.")
		return

	var life_manager: Node = get_node_or_null("/root/LifeManager")

	if life_manager == null:
		show_message("LifeManager não encontrado.")
		return

	if not "energy" in life_manager:
		show_message("Sistema de energia não encontrado.")
		return

	if float(life_manager.energy) >= 95.0:
		show_message("Energia já está quase cheia.")
		return

	can_rest = false
	show_message("A descansar...")

	if life_manager.has_method("rest"):
		life_manager.rest(rest_energy_amount)
	elif life_manager.has_method("restore_energy"):
		life_manager.restore_energy(rest_energy_amount)
	else:
		life_manager.energy = min(float(life_manager.energy) + rest_energy_amount, 100.0)

	if MissionManager != null:
		MissionManager.complete_rest_step()

	show_message("Descansaste e recuperaste energia.")

	await get_tree().create_timer(rest_cooldown_seconds).timeout
	can_rest = true


func show_message(message: String) -> void:
	var ui := get_tree().get_first_node_in_group("ui")

	if ui != null and ui.has_method("show_system_message"):
		ui.show_system_message(message)
	else:
		print(message)


# =========================================================
# HELPERS
# =========================================================

func _create_window_frame(parent: Node3D, center: Vector3) -> void:
	var frame_color := Color("#F3F0E8")

	_create_box(parent, "WindowFrameTop", Vector3(1.65, 0.08, 0.08), center + Vector3(0, 0.58, 0), frame_color)
	_create_box(parent, "WindowFrameBottom", Vector3(1.65, 0.08, 0.08), center + Vector3(0, -0.58, 0), frame_color)
	_create_box(parent, "WindowFrameLeft", Vector3(0.08, 1.2, 0.08), center + Vector3(-0.82, 0, 0), frame_color)
	_create_box(parent, "WindowFrameRight", Vector3(0.08, 1.2, 0.08), center + Vector3(0.82, 0, 0), frame_color)


func _create_gable_roof(
	parent: Node3D,
	node_name: String,
	size: Vector3,
	position: Vector3,
	color: Color
) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = node_name

	var w := size.x / 2.0
	var h := size.y
	var d := size.z / 2.0

	var vertices := PackedVector3Array([
		Vector3(-w, 0, -d),
		Vector3(w, 0, -d),
		Vector3(0, h, -d),
		Vector3(-w, 0, d),
		Vector3(w, 0, d),
		Vector3(0, h, d)
	])

	var indices := PackedInt32Array([
		0, 2, 1,
		3, 4, 5,
		0, 3, 5,
		0, 5, 2,
		1, 2, 5,
		1, 5, 4,
		0, 1, 4,
		0, 4, 3
	])

	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_INDEX] = indices

	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)

	mesh_instance.mesh = mesh
	mesh_instance.position = position

	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.9
	mesh_instance.material_override = mat

	parent.add_child(mesh_instance)
	return mesh_instance


func _create_box(
	parent: Node3D,
	box_name: String,
	size: Vector3,
	position: Vector3,
	color: Color,
	rotation: Vector3 = Vector3.ZERO
) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = box_name

	var box := BoxMesh.new()
	box.size = size

	mesh_instance.mesh = box
	mesh_instance.position = position
	mesh_instance.rotation = rotation

	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.85
	mesh_instance.material_override = mat

	parent.add_child(mesh_instance)
	return mesh_instance


func _create_cylinder(
	parent: Node3D,
	node_name: String,
	radius: float,
	height: float,
	position: Vector3,
	color: Color
) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = node_name

	var cylinder := CylinderMesh.new()
	cylinder.top_radius = radius
	cylinder.bottom_radius = radius
	cylinder.height = height

	mesh_instance.mesh = cylinder
	mesh_instance.position = position

	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mesh_instance.material_override = mat

	parent.add_child(mesh_instance)
	return mesh_instance


func _create_sphere(
	parent: Node3D,
	node_name: String,
	radius: float,
	position: Vector3,
	color: Color
) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = node_name

	var sphere := SphereMesh.new()
	sphere.radius = radius
	sphere.height = radius * 2.0

	mesh_instance.mesh = sphere
	mesh_instance.position = position

	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mesh_instance.material_override = mat

	parent.add_child(mesh_instance)
	return mesh_instance

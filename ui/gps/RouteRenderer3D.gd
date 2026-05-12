extends Node3D

@export var line_color: Color = Color("#00E5FF")
@export var line_width: float = 0.55
@export var height_offset: float = 0.35
@export var refresh_time: float = 0.15

var mesh_instance: MeshInstance3D
var current_points: Array[Vector3] = []
var refresh_timer: float = 0.0


func _ready() -> void:
	print("RouteRenderer3D entrou na cena.")

	mesh_instance = MeshInstance3D.new()
	mesh_instance.name = "RouteMesh"
	add_child(mesh_instance)

	_connect_route_manager()


func _process(delta: float) -> void:
	refresh_timer += delta

	if refresh_timer >= refresh_time:
		refresh_timer = 0.0
		_update_route_from_manager()


func _connect_route_manager() -> void:
	var route_manager := get_node_or_null("/root/RouteManager")

	if route_manager == null:
		print("ERRO: RouteRenderer3D não encontrou /root/RouteManager.")
		return

	print("RouteRenderer3D encontrou RouteManager.")

	if route_manager.has_signal("route_cleared"):
		if not route_manager.route_cleared.is_connected(_on_route_cleared):
			route_manager.route_cleared.connect(_on_route_cleared)


func _update_route_from_manager() -> void:
	var route_manager := get_node_or_null("/root/RouteManager")

	if route_manager == null:
		return

	if not route_manager.has_method("has_active_route"):
		return

	if not route_manager.has_active_route():
		_on_route_cleared()
		return

	if not route_manager.has_method("get_remaining_route"):
		return

	var points: Array = route_manager.get_remaining_route()

	if points.size() < 1:
		return

	var player := get_tree().get_first_node_in_group("player")

	if player == null or not player is Node3D:
		return

	current_points.clear()

	# Linha começa sempre no player
	current_points.append(player.global_position)

	for p in points:
		if p is Vector3:
			current_points.append(p)

	_generate_mesh()


func _on_route_cleared() -> void:
	current_points.clear()

	if mesh_instance != null:
		mesh_instance.mesh = null


func _generate_mesh() -> void:
	if current_points.size() < 2:
		return

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var valid_segments: int = 0

	for i in range(current_points.size() - 1):
		var world_a: Vector3 = current_points[i]
		var world_b: Vector3 = current_points[i + 1]

		world_a.y += height_offset
		world_b.y += height_offset

		var a: Vector3 = to_local(world_a)
		var b: Vector3 = to_local(world_b)

		var dir: Vector3 = b - a
		dir.y = 0.0

		if dir.length() < 0.01:
			continue

		dir = dir.normalized()

		var side: Vector3 = Vector3(-dir.z, 0.0, dir.x) * line_width

		var v1: Vector3 = a - side
		var v2: Vector3 = a + side
		var v3: Vector3 = b - side
		var v4: Vector3 = b + side

		st.add_vertex(v1)
		st.add_vertex(v2)
		st.add_vertex(v3)

		st.add_vertex(v3)
		st.add_vertex(v2)
		st.add_vertex(v4)

		valid_segments += 1

	if valid_segments <= 0:
		mesh_instance.mesh = null
		return

	var mesh := st.commit()

	var material := StandardMaterial3D.new()
	material.albedo_color = line_color
	material.emission_enabled = true
	material.emission = line_color
	material.emission_energy_multiplier = 5.0
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color.a = 1.0
	material.no_depth_test = true

	mesh_instance.mesh = mesh
	mesh_instance.material_override = material

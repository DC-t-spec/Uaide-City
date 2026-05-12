extends Node3D
class_name RoadPoint

@export var point_id: String = ""
@export var connected_points: Array[NodePath] = []

@export var debug_visible: bool = true
@export var debug_color: Color = Color("#00E5FF")

var neighbors: Array[RoadPoint] = []


func _ready() -> void:
	_setup_debug_visual()


func setup_neighbors() -> void:
	neighbors.clear()

	for path in connected_points:
		var node := get_node_or_null(path)
		if node != null and node is RoadPoint:
			neighbors.append(node)


func get_neighbors() -> Array[RoadPoint]:
	return neighbors


func _setup_debug_visual() -> void:
	var mesh_instance := get_node_or_null("MeshInstance3D")

	if mesh_instance == null:
		return

	mesh_instance.visible = debug_visible

	if mesh_instance is MeshInstance3D:
		var mat := StandardMaterial3D.new()
		mat.albedo_color = debug_color
		mat.emission_enabled = true
		mat.emission = debug_color
		mat.emission_energy_multiplier = 0.8
		mesh_instance.material_override = mat

extends Node3D

@export var grid_size: int = 10
@export var map_size: int = 300
@export var line_color: Color = Color(0.2, 0.2, 0.2, 0.6)

var mesh_instance: MeshInstance3D

func _ready():
	create_grid()


func create_grid():
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_LINES)

	var half_size = map_size / 2

	for i in range(-half_size, half_size + 1, grid_size):
		# Linhas paralelas ao eixo Z
		st.add_vertex(Vector3(i, 0.01, -half_size))
		st.add_vertex(Vector3(i, 0.01, half_size))

		# Linhas paralelas ao eixo X
		st.add_vertex(Vector3(-half_size, 0.01, i))
		st.add_vertex(Vector3(half_size, 0.01, i))

	var mesh = st.commit()

	mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = mesh

	var material = StandardMaterial3D.new()
	material.albedo_color = line_color
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	mesh_instance.material_override = material

	add_child(mesh_instance)

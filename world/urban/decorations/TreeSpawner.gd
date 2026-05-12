extends Node3D

@export var tree_scene: PackedScene
@export var tree_count: int = 25
@export var area_size: Vector2 = Vector2(80, 80)

@export var min_distance_between_trees: float = 6.0
@export var road_safe_distance: float = 7.0
@export var spawn_y: float = 0.15
@export var clear_previous: bool = true
@export var tree_visual_scale: float = 1.15

var spawned_positions: Array[Vector3] = []


func _ready() -> void:
	call_deferred("spawn_trees")


func spawn_trees() -> void:
	if tree_scene == null:
		print("TreeSpawner: tree_scene não definida.")
		return

	if clear_previous:
		_clear_old_trees()

	spawned_positions.clear()

	var attempts := 0
	var max_attempts := tree_count * 80

	while spawned_positions.size() < tree_count and attempts < max_attempts:
		attempts += 1

		var pos := Vector3(
			global_position.x + randf_range(-area_size.x * 0.5, area_size.x * 0.5),
			spawn_y,
			global_position.z + randf_range(-area_size.y * 0.5, area_size.y * 0.5)
		)

		if not _is_valid_tree_position(pos):
			continue

		var tree := tree_scene.instantiate()
		tree.name = "Tree_Auto_%02d" % spawned_positions.size()
		add_child(tree)
		tree.global_position = pos
		tree.scale = Vector3.ONE * tree_visual_scale

		spawned_positions.append(pos)

	print("TreeSpawner criou árvores: ", spawned_positions.size())


func _is_valid_tree_position(pos: Vector3) -> bool:
	for existing in spawned_positions:
		if existing.distance_to(pos) < min_distance_between_trees:
			return false

	var roads := get_tree().get_nodes_in_group("roads")

	for road in roads:
		if road is Node3D:
			if _is_near_road(pos, road):
				return false

	return true


func _is_near_road(pos: Vector3, road: Node3D) -> bool:
	var local_pos := road.to_local(pos)

	var road_size := _get_road_size(road)

	var half_x := road_size.x * 0.5 + road_safe_distance
	var half_z := road_size.z * 0.5 + road_safe_distance

	if abs(local_pos.x) <= half_x and abs(local_pos.z) <= half_z:
		return true

	return false


func _get_road_size(road: Node3D) -> Vector3:
	if road is MeshInstance3D:
		var mesh_instance := road as MeshInstance3D

		if mesh_instance.mesh is BoxMesh:
			var box := mesh_instance.mesh as BoxMesh
			return Vector3(
				box.size.x * abs(road.scale.x),
				box.size.y * abs(road.scale.y),
				box.size.z * abs(road.scale.z)
			)

		if mesh_instance.mesh is PlaneMesh:
			var plane := mesh_instance.mesh as PlaneMesh
			return Vector3(
				plane.size.x * abs(road.scale.x),
				0.1,
				plane.size.y * abs(road.scale.z)
			)

	return Vector3(6.0, 0.1, 6.0)


func _clear_old_trees() -> void:
	for child in get_children():
		if child.name.begins_with("Tree_Auto"):
			child.queue_free()

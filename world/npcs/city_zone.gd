extends Node3D

# ============================================================
# UAIDE CITY - CITY ZONE
# Cada zona controla seus próprios NPCs
# ============================================================

@export var zone_name: String = "Zona"
@export var npc_scene: PackedScene
@export var max_npcs: int = 3

var spawned_npcs: Array[Node3D] = []


func _ready() -> void:
	call_deferred("spawn_npcs")


func spawn_npcs() -> void:
	if npc_scene == null:
		push_warning(zone_name + ": npc_scene não definido.")
		return

	var spawn_points: Array[Node3D] = get_spawn_points()

	if spawn_points.is_empty():
		push_warning(zone_name + ": sem SpawnPoints.")
		return

	clear_invalid_npcs()

	var amount_to_spawn: int = max_npcs - spawned_npcs.size()

	if amount_to_spawn <= 0:
		return

	for i in range(amount_to_spawn):
		var spawn_point: Node3D = spawn_points[i % spawn_points.size()]
		spawn_single_npc(spawn_point)


func spawn_single_npc(spawn_point: Node3D) -> void:
	var npc: Node3D = npc_scene.instantiate()

	get_tree().current_scene.add_child(npc)

	npc.global_position = spawn_point.global_position
	npc.global_rotation = spawn_point.global_rotation

	spawned_npcs.append(npc)


func get_spawn_points() -> Array[Node3D]:
	var points: Array[Node3D] = []

	for child in get_children():
		if child is Marker3D:
			points.append(child)

	return points


func clear_invalid_npcs() -> void:
	for i in range(spawned_npcs.size() - 1, -1, -1):
		if not is_instance_valid(spawned_npcs[i]):
			spawned_npcs.remove_at(i)

extends Node3D

# ============================================================
# UAIDE CITY - NPC SPAWNER
# Controla quantidade e pontos de nascimento dos NPCs
# ============================================================

@export var npc_scene: PackedScene
@export var max_npcs: int = 5
@export var spawn_on_ready: bool = true

var spawned_npcs: Array[Node3D] = []


func _ready() -> void:
	if spawn_on_ready:
		call_deferred("spawn_npcs")


func spawn_npcs() -> void:
	if npc_scene == null:
		push_warning("NPCSpawner: npc_scene não foi definido.")
		return

	var spawn_points: Array[Node3D] = get_spawn_points()

	if spawn_points.is_empty():
		push_warning("NPCSpawner: nenhum SpawnPoint encontrado.")
		return

	clear_invalid_npcs()

	var amount_to_spawn: int = max_npcs - spawned_npcs.size()

	if amount_to_spawn <= 0:
		return

	for i in range(amount_to_spawn):
		var spawn_point: Node3D = spawn_points[i % spawn_points.size()]
		spawn_single_npc(spawn_point)


func spawn_single_npc(spawn_point: Node3D) -> void:
	if spawn_point == null:
		return

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


func remove_all_npcs() -> void:
	for npc in spawned_npcs:
		if is_instance_valid(npc):
			npc.queue_free()

	spawned_npcs.clear()

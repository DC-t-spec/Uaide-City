extends Node3D
class_name RoadNetwork

@export var auto_register_on_ready: bool = true
@export var debug_prints: bool = true

var road_points: Array[RoadPoint] = []
var is_ready_network: bool = false


func _ready() -> void:
	call_deferred("_setup_network")


func _setup_network() -> void:
	collect_road_points()
	setup_all_neighbors()
	is_ready_network = true

	if auto_register_on_ready:
		register_to_route_manager()

	if debug_prints:
		print("RoadNetwork pronto. Pontos carregados: ", road_points.size())


func collect_road_points() -> void:
	road_points.clear()
	_collect_points_recursive(self)

	if debug_prints:
		print("RoadNetwork coletou RoadPoints: ", road_points.size())


func _collect_points_recursive(node: Node) -> void:
	for child in node.get_children():
		if child is RoadPoint:
			road_points.append(child)

		if child.get_child_count() > 0:
			_collect_points_recursive(child)


func setup_all_neighbors() -> void:
	for point in road_points:
		if point != null and is_instance_valid(point):
			point.setup_neighbors()

	if debug_prints:
		print("RoadNetwork ligou vizinhos dos pontos.")


func register_to_route_manager() -> void:
	var route_manager := get_node_or_null("/root/RouteManager")

	if route_manager == null:
		print("RoadNetwork: RouteManager não encontrado.")
		return

	if route_manager.has_method("register_road_network"):
		route_manager.register_road_network(self)
		print("RouteManager recebeu RoadNetwork.")
	else:
		print("RoadNetwork: RouteManager não tem register_road_network().")


func refresh_network() -> void:
	_setup_network()


func get_closest_point(world_position: Vector3) -> RoadPoint:
	if road_points.is_empty():
		collect_road_points()

	var closest: RoadPoint = null
	var closest_distance := INF

	for point in road_points:
		if point == null or not is_instance_valid(point):
			continue

		var distance := point.global_position.distance_to(world_position)

		if distance < closest_distance:
			closest_distance = distance
			closest = point

	return closest


func get_all_points() -> Array[RoadPoint]:
	if road_points.is_empty():
		collect_road_points()

	return road_points


func has_points() -> bool:
	return not road_points.is_empty()


func get_point_count() -> int:
	return road_points.size()

extends Node

signal route_created(route_points: Array[Vector3])
signal route_cleared
signal next_route_point_changed(point_position: Vector3)

const COLOR_ROUTE := Color("#00E5FF")
const COLOR_TARGET := Color("#FF3B30")
const COLOR_PLAYER := Color("#FFD60A")
const COLOR_ROAD := Color("#2C2C2E")
const COLOR_ACTIVE := Color("#34C759")
const COLOR_WARNING := Color("#FF9500")

var road_network: RoadNetwork = null

var current_route_points: Array[Vector3] = []
var current_route_nodes: Array[RoadPoint] = []

var current_target_position: Vector3 = Vector3.ZERO
var current_route_index: int = 0

var route_active: bool = false

# Distância para considerar que o player chegou a um ponto
var next_point_reach_distance: float = 5.0

# Pontos mais perto que isto são ignorados ao iniciar a rota
var start_skip_distance: float = 7.0


func register_road_network(network: RoadNetwork) -> void:
	road_network = network
	print("RouteManager recebeu RoadNetwork.")


func create_route(from_position: Vector3, to_position: Vector3) -> Array[Vector3]:
	clear_route()

	if road_network == null:
		push_warning("RouteManager: RoadNetwork não registado.")
		return []

	var start_point := road_network.get_closest_point(from_position)
	var end_point := road_network.get_closest_point(to_position)

	if start_point == null or end_point == null:
		push_warning("RouteManager: não foi possível encontrar pontos de estrada.")
		return []

	var path_nodes := _find_path_astar(start_point, end_point)

	if path_nodes.is_empty():
		push_warning("RouteManager: nenhuma rota encontrada.")
		return []

	current_route_nodes = path_nodes
	current_route_points.clear()

	for node in current_route_nodes:
		current_route_points.append(node.global_position)

	current_target_position = to_position
	current_route_points.append(to_position)

	current_route_index = 0
	_skip_points_close_to_player(from_position)

	route_active = true

	route_created.emit(current_route_points)

	if current_route_index < current_route_points.size():
		next_route_point_changed.emit(current_route_points[current_route_index])

	print("Rota criada com pontos: ", current_route_points.size())
	print("Índice inicial da rota: ", current_route_index)
	print("Próximo ponto GPS: ", get_next_route_point())

	return current_route_points


func clear_route() -> void:
	current_route_points.clear()
	current_route_nodes.clear()
	current_route_index = 0
	route_active = false
	route_cleared.emit()


func update_route_progress(player_position: Vector3) -> void:
	if not route_active:
		return

	if current_route_points.is_empty():
		return

	if current_route_index >= current_route_points.size():
		clear_route()
		return

	var next_position := current_route_points[current_route_index]
	var distance := player_position.distance_to(next_position)

	if distance <= next_point_reach_distance:
		current_route_index += 1

		_skip_points_close_to_player(player_position)

		if current_route_index < current_route_points.size():
			next_route_point_changed.emit(current_route_points[current_route_index])
			print("GPS mudou para próximo ponto: ", current_route_index)
		else:
			clear_route()


func get_next_route_point() -> Vector3:
	if not route_active:
		return Vector3.ZERO

	if current_route_points.is_empty():
		return Vector3.ZERO

	if current_route_index >= current_route_points.size():
		return current_route_points[current_route_points.size() - 1]

	return current_route_points[current_route_index]


func get_remaining_route() -> Array[Vector3]:
	if not route_active:
		return []

	if current_route_index >= current_route_points.size():
		return []

	return current_route_points.slice(current_route_index)


func has_active_route() -> bool:
	return route_active


func _skip_points_close_to_player(player_position: Vector3) -> void:
	while current_route_index < current_route_points.size():
		var distance := player_position.distance_to(current_route_points[current_route_index])

		if distance <= start_skip_distance:
			current_route_index += 1
		else:
			break

	if current_route_index >= current_route_points.size():
		current_route_index = current_route_points.size() - 1


func _find_path_astar(start: RoadPoint, goal: RoadPoint) -> Array[RoadPoint]:
	var open_set: Array[RoadPoint] = [start]
	var came_from: Dictionary = {}

	var g_score: Dictionary = {}
	var f_score: Dictionary = {}

	for point in road_network.get_all_points():
		g_score[point] = INF
		f_score[point] = INF

	g_score[start] = 0.0
	f_score[start] = _heuristic(start, goal)

	while not open_set.is_empty():
		var current := _get_lowest_f_score(open_set, f_score)

		if current == goal:
			return _reconstruct_path(came_from, current)

		open_set.erase(current)

		for neighbor in current.get_neighbors():
			var tentative_g := float(g_score[current]) + current.global_position.distance_to(neighbor.global_position)

			if tentative_g < float(g_score.get(neighbor, INF)):
				came_from[neighbor] = current
				g_score[neighbor] = tentative_g
				f_score[neighbor] = tentative_g + _heuristic(neighbor, goal)

				if not open_set.has(neighbor):
					open_set.append(neighbor)

	return []


func _heuristic(a: RoadPoint, b: RoadPoint) -> float:
	return a.global_position.distance_to(b.global_position)


func _get_lowest_f_score(open_set: Array[RoadPoint], f_score: Dictionary) -> RoadPoint:
	var best_point := open_set[0]
	var best_score := float(f_score.get(best_point, INF))

	for point in open_set:
		var score := float(f_score.get(point, INF))

		if score < best_score:
			best_score = score
			best_point = point

	return best_point


func _reconstruct_path(came_from: Dictionary, current: RoadPoint) -> Array[RoadPoint]:
	var total_path: Array[RoadPoint] = [current]

	while came_from.has(current):
		current = came_from[current]
		total_path.insert(0, current)

	return total_path

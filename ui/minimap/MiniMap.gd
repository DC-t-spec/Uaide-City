extends Control

@export var map_width: float = 220.0
@export var map_height: float = 220.0
@export var map_scale: float = 0.08
@export var max_icon_distance: float = 95.0
@export var route_line_width: float = 3.0

const COLOR_ROUTE := Color("#00E5FF")
const COLOR_TARGET := Color("#FF3B30")
const COLOR_PLAYER := Color("#FFD60A")
const COLOR_BACKGROUND := Color("#141414BF")

var map_panel: Panel
var map_background: ColorRect
var player_icon: ColorRect
var target_icon: ColorRect
var direction_arrow: Label
var distance_label: Label

var player_ref: Node3D = null
var target_ref: Node3D = null
var has_target: bool = false
var target_position: Vector3 = Vector3.ZERO

var map_center: Vector2 = Vector2.ZERO
var route_points: Array[Vector3] = []


func _ready() -> void:
	_get_nodes_safely()
	_setup_visual()
	_find_player()
	_connect_delivery()
	_connect_route_manager()

	print("MINI MAP carregado")
	print("Player encontrado: ", player_ref)


func _process(_delta: float) -> void:
	if player_ref == null or not is_instance_valid(player_ref):
		_find_player()

	_update_player_icon()
	_update_target_icon()

	if has_target or not route_points.is_empty():
		queue_redraw()


func _draw() -> void:
	_draw_route()


func _get_nodes_safely() -> void:
	map_panel = get_node_or_null("Panel")
	map_background = get_node_or_null("Panel/MapBackground")
	player_icon = get_node_or_null("Panel/PlayerIcon")
	target_icon = get_node_or_null("Panel/TargetIcon")
	direction_arrow = get_node_or_null("Panel/DirectionArrow")
	distance_label = get_node_or_null("Panel/DistanceLabel")


func _setup_visual() -> void:
	size = Vector2(map_width, map_height + 40.0)
	position = Vector2(20.0, 450.0)

	map_center = Vector2(map_width, map_height) * 0.5

	if map_panel != null:
		map_panel.position = Vector2.ZERO
		map_panel.size = Vector2(map_width, map_height)

	if map_background != null:
		map_background.position = Vector2.ZERO
		map_background.size = Vector2(map_width, map_height)
		map_background.color = COLOR_BACKGROUND
		map_background.z_index = 0

	if player_icon != null:
		player_icon.size = Vector2(14.0, 14.0)
		player_icon.color = COLOR_PLAYER
		player_icon.z_index = 20
		player_icon.visible = true
		player_icon.position = map_center - player_icon.size * 0.5

	if target_icon != null:
		target_icon.size = Vector2(14.0, 14.0)
		target_icon.color = COLOR_TARGET
		target_icon.z_index = 21
		target_icon.visible = false

	if direction_arrow != null:
		direction_arrow.text = "▲"
		direction_arrow.size = Vector2(40.0, 40.0)
		direction_arrow.pivot_offset = direction_arrow.size * 0.5
		direction_arrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		direction_arrow.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		direction_arrow.z_index = 22
		direction_arrow.visible = false

	if distance_label != null:
		distance_label.position = Vector2(0.0, map_height - 35.0)
		distance_label.size = Vector2(map_width, 35.0)
		distance_label.text = "Sem destino"
		distance_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		distance_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		distance_label.z_index = 30


func _find_player() -> void:
	var players := get_tree().get_nodes_in_group("player")

	if players.size() > 0 and players[0] is Node3D:
		player_ref = players[0]


func _connect_delivery() -> void:
	if get_node_or_null("/root/DeliveryManager") == null:
		print("MiniMap: DeliveryManager não encontrado.")
		return

	if not DeliveryManager.delivery_started.is_connected(_on_delivery_started):
		DeliveryManager.delivery_started.connect(_on_delivery_started)

	if not DeliveryManager.delivery_completed.is_connected(_on_delivery_finished):
		DeliveryManager.delivery_completed.connect(_on_delivery_finished)

	if not DeliveryManager.delivery_failed.is_connected(_on_delivery_finished):
		DeliveryManager.delivery_failed.connect(_on_delivery_finished)

	if not DeliveryManager.delivery_cancelled.is_connected(_on_delivery_finished):
		DeliveryManager.delivery_cancelled.connect(_on_delivery_finished)


func _connect_route_manager() -> void:
	var route_manager := get_node_or_null("/root/RouteManager")

	if route_manager == null:
		print("MiniMap: RouteManager não encontrado. Rota azul não será desenhada.")
		return

	if route_manager.has_signal("route_created"):
		if not route_manager.route_created.is_connected(_on_route_created):
			route_manager.route_created.connect(_on_route_created)

	if route_manager.has_signal("route_cleared"):
		if not route_manager.route_cleared.is_connected(_on_route_cleared):
			route_manager.route_cleared.connect(_on_route_cleared)


func _update_player_icon() -> void:
	if player_icon == null:
		return

	player_icon.visible = true
	player_icon.position = map_center - player_icon.size * 0.5


func _update_target_icon() -> void:
	if target_icon == null:
		return

	if not has_target:
		target_icon.visible = false

		if direction_arrow != null:
			direction_arrow.visible = false

		if distance_label != null:
			distance_label.text = "Sem destino"

		return

	if player_ref == null or not is_instance_valid(player_ref):
		return

	var final_target_position: Vector3 = target_position

	if target_ref != null and is_instance_valid(target_ref):
		final_target_position = target_ref.global_position

	var offset_3d: Vector3 = final_target_position - player_ref.global_position
	var offset_2d: Vector2 = Vector2(offset_3d.x, offset_3d.z)
	var distance: float = offset_2d.length()

	var map_offset: Vector2 = offset_2d * map_scale

	if map_offset.length() > max_icon_distance:
		map_offset = map_offset.normalized() * max_icon_distance

	target_icon.position = map_center + map_offset - target_icon.size * 0.5
	target_icon.visible = true

	if distance_label != null:
		distance_label.text = str(int(distance)) + " m"

	if direction_arrow != null:
		if distance > 3.0:
			direction_arrow.visible = true
			direction_arrow.pivot_offset = direction_arrow.size * 0.5
			direction_arrow.position = map_center - direction_arrow.size * 0.5 + Vector2(0.0, -3.0)
			direction_arrow.rotation = offset_2d.angle() + deg_to_rad(90.0)
		else:
			direction_arrow.visible = false


func _draw_route() -> void:
	if route_points.size() < 2:
		return

	if player_ref == null or not is_instance_valid(player_ref):
		return

	for i in range(route_points.size() - 1):
		var point_a := _world_to_minimap(route_points[i])
		var point_b := _world_to_minimap(route_points[i + 1])

		draw_line(point_a, point_b, COLOR_ROUTE, route_line_width, true)


func _world_to_minimap(world_pos: Vector3) -> Vector2:
	if player_ref == null or not is_instance_valid(player_ref):
		return map_center

	var offset_3d: Vector3 = world_pos - player_ref.global_position
	var offset_2d := Vector2(offset_3d.x, offset_3d.z)
	var map_offset := offset_2d * map_scale

	if map_offset.length() > max_icon_distance:
		map_offset = map_offset.normalized() * max_icon_distance

	return map_center + map_offset


func set_target_node(node: Node3D) -> void:
	if node == null:
		clear_target()
		return

	target_ref = node
	target_position = node.global_position
	has_target = true

	print("MiniMap destino definido: ", node.name)


func set_target_position(pos: Vector3) -> void:
	target_ref = null
	target_position = pos
	has_target = true

	print("MiniMap destino por posição: ", pos)


func clear_target() -> void:
	target_ref = null
	target_position = Vector3.ZERO
	has_target = false
	route_points.clear()

	if target_icon != null:
		target_icon.visible = false

	if direction_arrow != null:
		direction_arrow.visible = false

	if distance_label != null:
		distance_label.text = "Sem destino"

	queue_redraw()


func _on_route_created(points: Array[Vector3]) -> void:
	route_points = points
	queue_redraw()


func _on_route_cleared() -> void:
	route_points.clear()
	queue_redraw()


func _on_delivery_started(
	destination_name: String,
	reward_money: int,
	reward_reputation: int,
	time_limit: int
) -> void:
	print("MiniMap recebeu delivery_started: ", destination_name)

	if DeliveryManager.has_method("get_target_lot"):
		var target = DeliveryManager.get_target_lot()

		if target != null and target is Node3D:
			set_target_node(target)
			return

	if DeliveryManager.has_method("get_target_position"):
		set_target_position(DeliveryManager.get_target_position())


func _on_delivery_finished(_a = null, _b = null, _c = null, _d = null, _e = null) -> void:
	clear_target()

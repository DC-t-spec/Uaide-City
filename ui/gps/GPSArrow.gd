extends Node3D

@export var height_above_player: float = 2.8
@export var rotate_speed: float = 10.0
@export var bob_speed: float = 3.0
@export var bob_height: float = 0.15

# Ajuste se o mesh estiver virado errado:
# 0, 90, -90 ou 180
@export var mesh_direction_offset_degrees: float = 0.0

var target_node: Node3D = null
var target_position: Vector3 = Vector3.ZERO
var has_target: bool = false
var time_passed: float = 0.0


func _ready() -> void:
	visible = false
	position = Vector3(0.0, height_above_player, 0.0)
	_connect_delivery()


func _process(delta: float) -> void:
	var player := get_parent()

	if player == null or not player is Node3D:
		visible = false
		return

	var final_target_position := _get_current_gps_target()

	if final_target_position == Vector3.ZERO and not has_target:
		visible = false
		return

	var direction: Vector3 = final_target_position - player.global_position
	direction.y = 0.0

	if direction.length() < 1.0:
		visible = false
		return

	visible = true
	time_passed += delta

	direction = direction.normalized()

	var local_direction: Vector3 = player.global_transform.basis.inverse() * direction
	local_direction.y = 0.0

	if local_direction.length() < 0.01:
		return

	local_direction = local_direction.normalized()

	var target_angle := atan2(local_direction.x, local_direction.z)
	target_angle += deg_to_rad(mesh_direction_offset_degrees)

	rotation.y = lerp_angle(rotation.y, target_angle, rotate_speed * delta)

	position = Vector3(
		0.0,
		height_above_player + sin(time_passed * bob_speed) * bob_height,
		0.0
	)


func _get_current_gps_target() -> Vector3:
	var route_manager := get_node_or_null("/root/RouteManager")

	if route_manager != null:
		if route_manager.has_method("has_active_route") and route_manager.has_active_route():
			if route_manager.has_method("get_next_route_point"):
				return route_manager.get_next_route_point()

	if target_node != null and is_instance_valid(target_node):
		return target_node.global_position

	return target_position


func _connect_delivery() -> void:
	if get_node_or_null("/root/DeliveryManager") == null:
		print("GPSArrow: DeliveryManager não encontrado.")
		return

	if not DeliveryManager.delivery_started.is_connected(_on_delivery_started):
		DeliveryManager.delivery_started.connect(_on_delivery_started)

	if not DeliveryManager.delivery_completed.is_connected(_on_delivery_finished):
		DeliveryManager.delivery_completed.connect(_on_delivery_finished)

	if not DeliveryManager.delivery_failed.is_connected(_on_delivery_finished):
		DeliveryManager.delivery_failed.connect(_on_delivery_finished)

	if not DeliveryManager.delivery_cancelled.is_connected(_on_delivery_finished):
		DeliveryManager.delivery_cancelled.connect(_on_delivery_finished)


func set_target_node(node: Node3D) -> void:
	if node == null:
		clear_target()
		return

	target_node = node
	target_position = node.global_position
	has_target = true
	visible = true


func set_target_position(pos: Vector3) -> void:
	target_node = null
	target_position = pos
	has_target = true
	visible = true


func clear_target() -> void:
	target_node = null
	target_position = Vector3.ZERO
	has_target = false
	visible = false


func _on_delivery_started(
	destination_name: String,
	reward_money: int,
	reward_reputation: int,
	time_limit: int
) -> void:
	if DeliveryManager.has_method("get_target_lot"):
		var target = DeliveryManager.get_target_lot()

		if target != null and target is Node3D:
			set_target_node(target)
			return

	if DeliveryManager.has_method("get_target_position"):
		set_target_position(DeliveryManager.get_target_position())


func _on_delivery_finished(_a = null, _b = null, _c = null, _d = null, _e = null) -> void:
	clear_target()

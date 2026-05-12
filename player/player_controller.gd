extends CharacterBody3D

@export var walk_speed: float = 6.0
@export var sprint_speed: float = 10.0
@export var jump_force: float = 8.0
@export var gravity: float = 20.0
@export var look_speed: float = 2.0

var camera_pivot: Node3D
var camera: Camera3D
var camera_pitch: float = 0.0


func _ready() -> void:
	add_to_group("player")

	camera_pivot = $CameraPivot
	camera = $CameraPivot/Camera3D

	camera_pivot.position = Vector3(0, 1.65, 0)
	camera_pivot.rotation = Vector3.ZERO

	camera.position = Vector3(0, 1.35, 7)
	camera.rotation_degrees = Vector3(-12, 0, 0)
	camera.current = true

	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	var spawn = get_tree().get_first_node_in_group("spawn")
	if spawn:
		global_position = spawn.global_position


func _physics_process(delta: float) -> void:
	var look_x := Input.get_action_strength("look_right") - Input.get_action_strength("look_left")
	var look_y := Input.get_action_strength("look_down") - Input.get_action_strength("look_up")

	rotation.y -= look_x * look_speed * delta

	camera_pitch += look_y * look_speed * delta
	camera_pitch = clamp(camera_pitch, deg_to_rad(-8), deg_to_rad(8))
	camera_pivot.rotation.x = camera_pitch

	var input_dir := Vector2.ZERO
	input_dir.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	input_dir.y = Input.get_action_strength("move_forward") - Input.get_action_strength("move_back")
	input_dir = input_dir.normalized()

	var forward: Vector3 = -transform.basis.z
	var right: Vector3 = transform.basis.x

	forward.y = 0
	right.y = 0
	forward = forward.normalized()
	right = right.normalized()

	var direction := (forward * input_dir.y) + (right * input_dir.x)

	if direction.length() > 0:
		direction = direction.normalized()

	var current_speed := walk_speed

	if Input.is_action_pressed("ui_accept"):
		current_speed = sprint_speed

	velocity.x = direction.x * current_speed
	velocity.z = direction.z * current_speed

	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0

		if Input.is_action_just_pressed("ui_select"):
			velocity.y = jump_force

	move_and_slide()

	_update_delivery_system()
	_update_route_system()
	_check_delivery_cancel()


func _update_delivery_system() -> void:
	if get_node_or_null("/root/DeliveryManager") == null:
		return

	if DeliveryManager.has_method("has_active_delivery") and DeliveryManager.has_active_delivery():
		if DeliveryManager.has_method("update_delivery_distance"):
			DeliveryManager.update_delivery_distance(global_position)


func _update_route_system() -> void:
	var route_manager := get_node_or_null("/root/RouteManager")

	if route_manager == null:
		return

	if route_manager.has_method("has_active_route") and route_manager.has_active_route():
		if route_manager.has_method("update_route_progress"):
			route_manager.update_route_progress(global_position)


func _check_delivery_cancel() -> void:
	if get_node_or_null("/root/DeliveryManager") == null:
		return

	if not DeliveryManager.has_method("has_active_delivery"):
		return

	if not DeliveryManager.has_active_delivery():
		return

	var pressed_cancel := false

	if InputMap.has_action("cancel_delivery"):
		pressed_cancel = Input.is_action_just_pressed("cancel_delivery")
	else:
		pressed_cancel = Input.is_key_pressed(KEY_Q)

	if pressed_cancel and DeliveryManager.has_method("cancel_delivery"):
		DeliveryManager.cancel_delivery()

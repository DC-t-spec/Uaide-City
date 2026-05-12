extends CharacterBody3D

@export var walk_speed: float = 1.2
@export var roam_radius: float = 8.0
@export var wait_time: float = 2.0
@export var gravity: float = 20.0

var start_position: Vector3
var target_position: Vector3
var waiting: bool = false
var rng := RandomNumberGenerator.new()


func _ready() -> void:
	rng.randomize()
	start_position = global_position
	_pick_new_target()


func _physics_process(delta: float) -> void:
	_apply_gravity(delta)

	if waiting:
		_stop_horizontal_movement()
		move_and_slide()
		return

	var direction_vector: Vector3 = target_position - global_position
	direction_vector.y = 0.0

	if direction_vector.length() < 0.5:
		_start_wait()
		return

	direction_vector = direction_vector.normalized()

	velocity.x = direction_vector.x * walk_speed
	velocity.z = direction_vector.z * walk_speed

	_rotate_to_target()

	move_and_slide()

	if is_on_wall():
		_pick_new_target()


func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = -0.2


func _stop_horizontal_movement() -> void:
	velocity.x = 0.0
	velocity.z = 0.0


func _rotate_to_target() -> void:
	var flat_target := Vector3(target_position.x, global_position.y, target_position.z)

	if global_position.distance_to(flat_target) > 0.1:
		look_at(flat_target, Vector3.UP)


func _pick_new_target() -> void:
	var random_offset := Vector3(
		rng.randf_range(-roam_radius, roam_radius),
		0.0,
		rng.randf_range(-roam_radius, roam_radius)
	)

	target_position = start_position + random_offset


func _start_wait() -> void:
	waiting = true
	_stop_horizontal_movement()

	await get_tree().create_timer(wait_time).timeout

	waiting = false
	_pick_new_target()

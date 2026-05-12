extends Node3D

# ============================================================
# UAIDE CITY - GARBAGE TASK POINT
# Ponto físico de recolha de lixo
# ============================================================

@export var required_job_id: String = "garbage"
@export var task_id: String = "garbage_001"

var player_inside: bool = false
var player_ref: Node3D = null
var collected: bool = false
var active: bool = false

@onready var interaction_area: Area3D = $InteractionArea
@onready var visual: MeshInstance3D = $MeshInstance3D
@onready var marker: Node3D = $Marker


func _ready() -> void:
	add_to_group("garbage_task_points")

	interaction_area.body_entered.connect(_on_body_entered)
	interaction_area.body_exited.connect(_on_body_exited)

	if not JobManager.job_started.is_connected(_on_job_started):
		JobManager.job_started.connect(_on_job_started)

	if not JobManager.job_completed.is_connected(_on_job_completed):
		JobManager.job_completed.connect(_on_job_completed)

	if not JobManager.job_cooldown_started.is_connected(_on_job_cooldown_started):
		JobManager.job_cooldown_started.connect(_on_job_cooldown_started)

	_set_active(false)
	_restore_if_job_already_active()


func _process(_delta: float) -> void:
	if not active:
		return

	if collected:
		return

	if not player_inside:
		return

	if Input.is_action_just_pressed("interact"):
		_collect_garbage()


func _on_body_entered(body: Node3D) -> void:
	if not active:
		return

	if collected:
		return

	if body.is_in_group("player"):
		player_inside = true
		player_ref = body
		print("Saco de lixo encontrado. Pressiona E para recolher.")


func _on_body_exited(body: Node3D) -> void:
	if body == player_ref:
		player_inside = false
		player_ref = null


func _collect_garbage() -> void:
	var current_job: Dictionary = JobManager.get_current_job()

	if current_job.is_empty():
		return

	if current_job.get("status", "") != "active":
		return

	if current_job.get("job_id", "") != required_job_id:
		return

	var success: bool = JobManager.complete_task(task_id)

	if not success:
		return

	collected = true
	player_inside = false

	_set_active(false)


func _on_job_started(job_data: Dictionary) -> void:
	if job_data.get("job_id", "") != required_job_id:
		return

	collected = false
	player_inside = false
	player_ref = null

	_set_active(true)


func _on_job_completed(job_data: Dictionary) -> void:
	if job_data.get("job_id", "") != required_job_id:
		return

	_set_active(false)


func _on_job_cooldown_started(job_data: Dictionary) -> void:
	if job_data.get("job_id", "") != required_job_id:
		return

	_set_active(false)


func _restore_if_job_already_active() -> void:
	var current_job: Dictionary = JobManager.get_current_job()

	if current_job.is_empty():
		return

	if current_job.get("job_id", "") != required_job_id:
		return

	if current_job.get("status", "") != "active":
		return

	if not current_job.has("collected_task_ids"):
		current_job["collected_task_ids"] = []

	var collected_ids: Array = current_job["collected_task_ids"]

	if collected_ids.has(task_id):
		collected = true
		_set_active(false)
		return

	collected = false
	player_inside = false
	player_ref = null

	_set_active(true)


func _set_active(value: bool) -> void:
	active = value

	if visual != null:
		visual.visible = value

	if marker != null:
		marker.visible = value

	if interaction_area != null:
		interaction_area.set_deferred("monitoring", value)

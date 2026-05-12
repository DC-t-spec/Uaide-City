extends Node3D

# ============================================================
# UAIDE CITY - JOB POINT
# Ponto físico de emprego no mundo
# ============================================================

@export var job_id: String = "garbage"

var player_inside: bool = false

@onready var interaction_area: Area3D = $InteractionArea


func _ready() -> void:
	interaction_area.body_entered.connect(_on_body_entered)
	interaction_area.body_exited.connect(_on_body_exited)


func _process(_delta: float) -> void:
	if not player_inside:
		return

	if Input.is_action_just_pressed("interact"):
		_try_start_job()


func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		player_inside = true
		_update_job_ui()


func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		player_inside = false

		var ui = get_tree().get_first_node_in_group("ui")
		if ui != null:
			ui.hide_job_info()


func _try_start_job() -> void:
	if not JobManager.job_exists(job_id):
		print("Este emprego não existe:", job_id)
		return

	if not JobManager.is_job_available(job_id):
		_update_job_ui()
		return

	var started: bool = JobManager.start_job(job_id)

	if started:
		_update_job_ui()


func _update_job_ui() -> void:
	var ui = get_tree().get_first_node_in_group("ui")
	if ui == null:
		return

	var base_job: Dictionary = JobManager.get_job_data(job_id)
	var current_job: Dictionary = JobManager.get_current_job()

	if base_job.is_empty():
		return

	if current_job.is_empty():
		ui.show_job_info(base_job, "Pressiona E para iniciar.")
		return

	if current_job.get("job_id", "") != job_id:
		ui.show_job_info(base_job, "Pressiona E para iniciar.")
		return

	var status: String = str(current_job.get("status", ""))

	if status == "active":
		ui.show_job_info(current_job, "Vai recolher os sacos de lixo.")
		return

	if status == "cooldown":
		var end_day: int = int(current_job.get("cooldown_end_day", 0))
		ui.show_job_info(current_job, "Disponível novamente no dia " + str(end_day) + ".")
		return

	ui.show_job_info(base_job, "Pressiona E para iniciar.")

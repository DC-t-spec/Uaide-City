extends Node

# ============================================================
# UAIDE CITY - JOB MANAGER
# Sistema central de empregos
# Usa dia absoluto para cooldown
# Integra FASE 6: fome/energia via LifeManager
# Integra FASE 7: reputação via ReputationManager
# ============================================================

signal job_started(job_data: Dictionary)
signal job_progress_updated(job_data: Dictionary)
signal job_completed(job_data: Dictionary)
signal job_cooldown_started(job_data: Dictionary)

var jobs_data: Dictionary = {}
var current_job: Dictionary = {}


func _ready() -> void:
	_register_default_jobs()
	load_job_state()
	print("JobManager carregado com sucesso.")


func _register_default_jobs() -> void:
	jobs_data.clear()

	jobs_data["garbage"] = {
		"job_id": "garbage",
		"job_name": "Recolha de Lixo",
		"job_type": "task",
		"reward": 40,
		"reputation_reward": 3,
		"required_tasks": 3,
		"cooldown_days": 1
	}


# ============================================================
# CONSULTAS
# ============================================================

func job_exists(job_id: String) -> bool:
	return jobs_data.has(job_id)


func get_job_data(job_id: String) -> Dictionary:
	if not job_exists(job_id):
		return {}

	return jobs_data[job_id]


func has_active_job() -> bool:
	return not current_job.is_empty() and current_job.get("status", "") == "active"


func get_current_job() -> Dictionary:
	return current_job


func is_job_available(job_id: String) -> bool:
	if not job_exists(job_id):
		return false

	if current_job.is_empty():
		return true

	if current_job.get("job_id", "") != job_id:
		return true

	if current_job.get("status", "") != "cooldown":
		return true

	var today_absolute: int = TimeManager.get_current_day_absolute()
	var cooldown_end_day: int = int(current_job.get("cooldown_end_day", 0))

	return today_absolute >= cooldown_end_day


# ============================================================
# INICIAR EMPREGO
# ============================================================

func start_job(job_id: String) -> bool:
	if not job_exists(job_id):
		print("Erro: emprego não encontrado:", job_id)
		return false

	if has_active_job():
		print("Erro: já existe um emprego ativo.")
		return false

	if not is_job_available(job_id):
		print("Erro: emprego ainda está em cooldown.")
		return false

	if _is_life_blocking_work():
		_show_ui_feedback("Não tens energia suficiente para começar este trabalho.", "warning")
		return false

	var base_job: Dictionary = jobs_data[job_id]

	current_job = {
		"job_id": base_job["job_id"],
		"job_name": base_job["job_name"],
		"job_type": base_job["job_type"],
		"reward": base_job["reward"],
		"reputation_reward": base_job.get("reputation_reward", 0),
		"required_tasks": base_job["required_tasks"],
		"completed_tasks": 0,
		"collected_task_ids": [],
		"cooldown_days": base_job["cooldown_days"],
		"cooldown_end_day": 0,
		"status": "active"
	}

	save_job_state()

	print("Emprego iniciado:", current_job["job_name"])
	job_started.emit(current_job)

	return true


# ============================================================
# PROGRESSO / TAREFAS
# ============================================================

func complete_task(task_id: String) -> bool:
	if task_id.strip_edges() == "":
		print("Erro: task_id vazio.")
		return false

	if current_job.is_empty():
		print("Erro: não existe emprego ativo.")
		return false

	if current_job.get("status", "") != "active":
		print("Erro: o emprego atual não está ativo.")
		return false

	if _is_life_blocking_work():
		_show_ui_feedback("Estás demasiado cansado para continuar o trabalho.", "warning")
		return false

	if not current_job.has("collected_task_ids"):
		current_job["collected_task_ids"] = []

	var collected_ids: Array = current_job["collected_task_ids"]

	if collected_ids.has(task_id):
		print("Tarefa já recolhida:", task_id)
		return false

	collected_ids.append(task_id)
	current_job["collected_task_ids"] = collected_ids

	_consume_life_energy_for_task()

	return add_task_progress(1)


func add_task_progress(amount: int = 1) -> bool:
	if current_job.is_empty():
		print("Erro: não existe emprego ativo.")
		return false

	if current_job.get("status", "") != "active":
		print("Erro: o emprego atual não está ativo.")
		return false

	current_job["completed_tasks"] += amount

	if current_job["completed_tasks"] > current_job["required_tasks"]:
		current_job["completed_tasks"] = current_job["required_tasks"]

	save_job_state()

	print("Progresso do emprego:", current_job["completed_tasks"], "/", current_job["required_tasks"])

	job_progress_updated.emit(current_job)

	if current_job["completed_tasks"] >= current_job["required_tasks"]:
		_complete_current_job()

	return true


# ============================================================
# CONCLUIR EMPREGO
# ============================================================

func _complete_current_job() -> void:
	if current_job.is_empty():
		return

	current_job["status"] = "completed"

	var gross_reward: int = int(current_job["reward"])
	var salary_tax: int = TaxManager.calculate_salary_tax(gross_reward)
	var net_reward: int = gross_reward - salary_tax

	# ============================================================
	# DINHEIRO
	# ============================================================

	EconomyManager.add_money(net_reward)

	FinanceManager.register_income(
		"job_salary_gross",
		gross_reward,
		"Salário bruto por concluir trabalho: %s" % current_job.get("job_name", ""),
		"job",
		current_job.get("job_id", "")
	)

	TaxManager.register_salary_tax(
		salary_tax,
		current_job.get("job_id", "")
	)

	# ============================================================
	# REPUTAÇÃO
	# ============================================================

	var reputation_reward: int = int(current_job.get("reputation_reward", 0))
	var reputation_manager = get_node_or_null("/root/ReputationManager")

	if reputation_manager != null and reputation_reward > 0:
		if reputation_manager.has_method("add_reputation"):
			reputation_manager.add_reputation(reputation_reward)
			print("Reputação ganha:", reputation_reward)

	print("Emprego concluído:", current_job["job_name"])
	print("Salário bruto:", gross_reward, "MZN")
	print("Imposto sobre salário:", salary_tax, "MZN")
	print("Pagamento líquido recebido:", net_reward, "MZN")

	job_completed.emit(current_job)

	_start_cooldown()


func _start_cooldown() -> void:
	if current_job.is_empty():
		return

	var today_absolute: int = TimeManager.get_current_day_absolute()
	var cooldown_days: int = int(current_job.get("cooldown_days", 1))

	current_job["status"] = "cooldown"
	current_job["cooldown_end_day"] = today_absolute + cooldown_days

	save_job_state()

	print("Emprego em cooldown até ao dia absoluto:", current_job["cooldown_end_day"])
	job_cooldown_started.emit(current_job)


# ============================================================
# LIFE INTEGRATION
# ============================================================

func _get_life_manager() -> Node:
	return get_node_or_null("/root/LifeManager")


func _is_life_blocking_work() -> bool:
	var life_manager: Node = _get_life_manager()

	if life_manager == null:
		return false

	if life_manager.has_method("is_exhausted") and life_manager.is_exhausted():
		return true

	if life_manager.has_method("is_starving") and life_manager.is_starving():
		return true

	return false


func _consume_life_energy_for_task() -> void:
	var life_manager: Node = _get_life_manager()

	if life_manager == null:
		return

	if life_manager.has_method("consume_energy_for_task"):
		life_manager.consume_energy_for_task()


func _show_ui_feedback(message: String, feedback_type: String = "info") -> void:
	var ui = get_tree().get_first_node_in_group("ui")

	if ui != null and ui.has_method("show_feedback"):
		ui.show_feedback(message, feedback_type)
	else:
		print(message)


# ============================================================
# SAVE / LOAD
# ============================================================

func save_job_state() -> void:
	SaveManager.save_job_data(current_job)


func load_job_state() -> void:
	var loaded_job: Dictionary = SaveManager.load_job_data()

	if loaded_job.is_empty():
		current_job = {}
		return

	current_job = loaded_job

	if not current_job.has("collected_task_ids"):
		current_job["collected_task_ids"] = []

	if not current_job.has("reputation_reward"):
		current_job["reputation_reward"] = 10

	if current_job.get("status", "") == "cooldown":
		var today_absolute: int = TimeManager.get_current_day_absolute()
		var cooldown_end_day: int = int(current_job.get("cooldown_end_day", 0))

		if today_absolute >= cooldown_end_day:
			current_job.clear()
			save_job_state()
			return

	print("Estado do emprego carregado:", current_job)

	var status: String = str(current_job.get("status", ""))

	if status == "active":
		job_started.emit(current_job)

	if status == "cooldown":
		job_cooldown_started.emit(current_job)


func clear_current_job() -> void:
	current_job.clear()
	save_job_state()

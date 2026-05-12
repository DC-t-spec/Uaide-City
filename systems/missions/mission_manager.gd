extends Node

# ============================================================
# UAIDE CITY - MISSION MANAGER
# Missão inicial guiada para demo
# ============================================================

signal mission_updated(mission_text: String)
signal mission_completed(step_id: String)

const SAVE_SECTION: String = "missions"
const SAVE_KEY: String = "main_step"

const STEP_WORK: String = "work"
const STEP_BUY_LOT: String = "buy_lot"
const STEP_BUILD_HOUSE: String = "build_house"
const STEP_REST: String = "rest"
const STEP_DONE: String = "done"

var current_step: String = STEP_WORK


func _ready() -> void:
	load_data()
	connect_game_signals()
	emit_current_mission()

	print("MissionManager carregado. Etapa:", current_step)


func connect_game_signals() -> void:
	if not JobManager.job_completed.is_connected(_on_job_completed):
		JobManager.job_completed.connect(_on_job_completed)

	if not PropertyManager.property_updated.is_connected(_on_property_updated):
		PropertyManager.property_updated.connect(_on_property_updated)

	if not BuildingManager.house_built.is_connected(_on_house_built):
		BuildingManager.house_built.connect(_on_house_built)


func get_current_mission_text() -> String:
	if current_step == STEP_WORK:
		return "Missão: arranja um trabalho e ganha dinheiro."

	if current_step == STEP_BUY_LOT:
		return "Missão: compra o teu primeiro lote."

	if current_step == STEP_BUILD_HOUSE:
		return "Missão: constrói a tua primeira casa."

	if current_step == STEP_REST:
		return "Missão: descansa na tua casa."

	if current_step == STEP_DONE:
		return "Missão inicial concluída. Continua a evoluir na cidade."

	return "Missão: explora a cidade."


func emit_current_mission() -> void:
	mission_updated.emit(get_current_mission_text())


func advance_to(step_id: String) -> void:
	if current_step == step_id:
		return

	current_step = step_id
	save_data()
	emit_current_mission()
	mission_completed.emit(step_id)

	print("Missão avançou para:", step_id)


func complete_rest_step() -> void:
	if current_step == STEP_REST:
		advance_to(STEP_DONE)


# ============================================================
# EVENTOS DO JOGO
# ============================================================

func _on_job_completed(_job_data: Dictionary) -> void:
	if current_step == STEP_WORK:
		advance_to(STEP_BUY_LOT)


func _on_property_updated(property_id: String) -> void:
	if current_step != STEP_BUY_LOT:
		return

	if PropertyManager.has_property(property_id):
		advance_to(STEP_BUILD_HOUSE)


func _on_house_built(_property_id: String, _house_type: String) -> void:
	if current_step == STEP_BUILD_HOUSE:
		advance_to(STEP_REST)


# ============================================================
# SAVE / LOAD
# ============================================================

func save_data() -> void:
	SaveManager.save_value(SAVE_SECTION, SAVE_KEY, current_step)


func load_data() -> void:
	current_step = str(SaveManager.load_value(SAVE_SECTION, SAVE_KEY, STEP_WORK))

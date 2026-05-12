extends Node

# ============================================================
# UAIDE CITY - LIFE MANAGER
# Sistema de fome e energia (FASE 6)
# ============================================================

signal hunger_changed(value: float)
signal energy_changed(value: float)

# ============================================================
# CONFIG
# ============================================================

const MAX_HUNGER: float = 100.0
const MAX_ENERGY: float = 100.0

# 1 dia no jogo = 10 minutos reais.
const HUNGER_DECAY_PER_MINUTE: float = 0.02
const ENERGY_DECAY_PER_MINUTE: float = 0.015

# consumo ao concluir uma tarefa de emprego
const ENERGY_COST_PER_TASK: float = 2.0

# usa true só se precisares limpar save antigo bugado
const FORCE_RESET_ON_START: bool = false

# ============================================================
# STATE
# ============================================================

var hunger: float = 100.0
var energy: float = 100.0


# ============================================================
# INIT
# ============================================================

func _ready() -> void:
	load_state()

	if FORCE_RESET_ON_START:
		reset_life()

	if not TimeManager.minute_changed.is_connected(_on_minute_changed):
		TimeManager.minute_changed.connect(_on_minute_changed)

	_save_and_emit()

	print("LifeManager carregado. Fome:", hunger, " Energia:", energy)


# ============================================================
# TIME UPDATE
# ============================================================

func _on_minute_changed(_minute: int) -> void:
	_reduce_needs()
	_save_and_emit()


func _reduce_needs() -> void:
	hunger -= HUNGER_DECAY_PER_MINUTE
	energy -= ENERGY_DECAY_PER_MINUTE

	hunger = clamp(hunger, 0.0, MAX_HUNGER)
	energy = clamp(energy, 0.0, MAX_ENERGY)


# ============================================================
# JOB INTEGRATION
# ============================================================

func consume_energy_for_task() -> void:
	energy -= ENERGY_COST_PER_TASK
	energy = clamp(energy, 0.0, MAX_ENERGY)

	_save_and_emit()


# ============================================================
# FOOD / REST SYSTEM
# ============================================================

func eat(amount: float) -> void:
	if amount <= 0:
		return

	hunger += amount
	hunger = clamp(hunger, 0.0, MAX_HUNGER)

	_save_and_emit()


func rest(amount: float) -> void:
	if amount <= 0:
		return

	energy += amount
	energy = clamp(energy, 0.0, MAX_ENERGY)

	_save_and_emit()


func recover_energy(amount: float) -> void:
	rest(amount)


func reset_life() -> void:
	hunger = MAX_HUNGER
	energy = MAX_ENERGY

	_save_and_emit()


# ============================================================
# CHECKS
# ============================================================

func is_exhausted() -> bool:
	return energy <= 5.0


func is_starving() -> bool:
	return hunger <= 5.0


func can_work() -> bool:
	return not is_exhausted() and not is_starving()


# ============================================================
# SAVE / LOAD
# ============================================================

func _save_and_emit() -> void:
	SaveManager.save_value("life", "hunger", hunger)
	SaveManager.save_value("life", "energy", energy)

	hunger_changed.emit(hunger)
	energy_changed.emit(energy)


func load_state() -> void:
	hunger = float(SaveManager.load_value("life", "hunger", MAX_HUNGER))
	energy = float(SaveManager.load_value("life", "energy", MAX_ENERGY))

	hunger = clamp(hunger, 0.0, MAX_HUNGER)
	energy = clamp(energy, 0.0, MAX_ENERGY)

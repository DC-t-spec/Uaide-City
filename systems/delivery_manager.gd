extends Node

signal delivery_started(destination_name: String, reward_money: int, reward_reputation: int, time_limit: int)
signal delivery_updated(destination_name: String, distance: float, reward_money: int, time_left: int)
signal delivery_completed(destination_name: String, reward_money: int, reward_reputation: int, bonus_money: int, bonus_reputation: int)
signal delivery_failed(destination_name: String)
signal delivery_cancelled

var active_delivery: bool = false
var target_lot: Node3D = null

var start_position: Vector3 = Vector3.ZERO
var current_destination_position: Vector3 = Vector3.ZERO

var base_reward_money: int = 50
var reward_per_meter: float = 2.0
var base_reward_reputation: int = 5

var min_time_limit_seconds: int = 45
var max_time_limit_seconds: int = 180
var seconds_per_meter: float = 1.2
var time_limit_seconds: int = 90
var time_left_seconds: float = 0.0

var fast_bonus_time_ratio: float = 0.45
var fast_bonus_money: int = 35
var fast_bonus_reputation: int = 2

var fail_reputation_penalty: int = 3
var cancel_reputation_penalty: int = 1

var current_reward_money: int = 0
var current_reward_reputation: int = 0
var current_destination_name: String = ""


func _process(delta: float) -> void:
	if not active_delivery:
		return

	time_left_seconds -= delta

	if time_left_seconds <= 0.0:
		fail_delivery()


func start_delivery(player_position: Vector3 = Vector3.ZERO) -> void:
	if active_delivery:
		print("Já tens uma entrega ativa.")
		return

	var player := get_tree().get_first_node_in_group("player")

	if player_position == Vector3.ZERO and player != null and player is Node3D:
		player_position = player.global_position

	var lots: Array = get_tree().get_nodes_in_group("delivery_points")
	print("Quantidade de lotes encontrados:", lots.size())

	if lots.is_empty():
		print("Nenhum ponto de entrega encontrado.")
		return

	var valid_lots: Array = []

	for lot in lots:
		if lot != null and lot is Node3D and lot.has_method("activate_delivery"):
			valid_lots.append(lot)

	if valid_lots.is_empty():
		print("Nenhum lote válido com activate_delivery().")
		return

	target_lot = valid_lots.pick_random()
	active_delivery = true
	start_position = player_position

	current_destination_name = _get_lot_display_name(target_lot)
	current_destination_position = target_lot.global_position

	var distance: float = start_position.distance_to(current_destination_position)

	time_limit_seconds = calculate_time_limit(distance)
	time_left_seconds = float(time_limit_seconds)

	current_reward_money = calculate_money_reward(distance)
	current_reward_reputation = calculate_reputation_reward(distance)

	target_lot.activate_delivery()

	_clear_old_delivery_targets()
	target_lot.add_to_group("delivery_target")

	_create_navigation_route()

	delivery_started.emit(
		current_destination_name,
		current_reward_money,
		current_reward_reputation,
		time_limit_seconds
	)

	delivery_updated.emit(
		current_destination_name,
		distance,
		current_reward_money,
		int(ceil(time_left_seconds))
	)

	print("Entrega iniciada:", current_destination_name)
	print("Distância:", int(distance), "m")
	print("Tempo limite:", time_limit_seconds, "s")
	print("Recompensa:", current_reward_money)


func complete_delivery() -> void:
	if not active_delivery:
		print("Não existe entrega ativa.")
		return

	if target_lot == null:
		print("Erro: target_lot está vazio.")
		return

	var bonus_money: int = 0
	var bonus_reputation: int = 0

	var used_time: float = float(time_limit_seconds) - time_left_seconds
	var fast_limit: float = float(time_limit_seconds) * fast_bonus_time_ratio

	if used_time <= fast_limit:
		bonus_money = fast_bonus_money
		bonus_reputation = fast_bonus_reputation

	var final_money: int = current_reward_money + bonus_money
	var final_reputation: int = current_reward_reputation + bonus_reputation

	if is_instance_valid(target_lot) and target_lot.has_method("deactivate_delivery"):
		target_lot.deactivate_delivery()

	if EconomyManager and EconomyManager.has_method("add_money"):
		EconomyManager.add_money(final_money)

	if ReputationManager and ReputationManager.has_method("add_reputation"):
		ReputationManager.add_reputation(final_reputation)

	if get_node_or_null("/root/DeliveryStatsManager") != null:
		DeliveryStatsManager.register_success(
			used_time,
			final_money,
			final_reputation,
			bonus_money > 0
		)

	_clear_navigation_route()

	delivery_completed.emit(
		current_destination_name,
		final_money,
		final_reputation,
		bonus_money,
		bonus_reputation
	)

	print("Entrega concluída:", current_destination_name)
	print("Recebeste:", final_money, "MZN +", final_reputation, "REP")

	if bonus_money > 0 or bonus_reputation > 0:
		print("Bónus rápido:", bonus_money, "MZN +", bonus_reputation, "REP")

	_reset_delivery()


func fail_delivery() -> void:
	if not active_delivery:
		return

	if is_instance_valid(target_lot) and target_lot.has_method("deactivate_delivery"):
		target_lot.deactivate_delivery()

	if ReputationManager and ReputationManager.has_method("remove_reputation"):
		ReputationManager.remove_reputation(fail_reputation_penalty)

	if get_node_or_null("/root/DeliveryStatsManager") != null:
		DeliveryStatsManager.register_failure()

	_clear_navigation_route()

	delivery_failed.emit(current_destination_name)

	print("Entrega falhou:", current_destination_name)
	print("Penalização:", fail_reputation_penalty, "REP")

	_reset_delivery()


func cancel_delivery() -> void:
	if not active_delivery:
		return

	if is_instance_valid(target_lot) and target_lot.has_method("deactivate_delivery"):
		target_lot.deactivate_delivery()

	if ReputationManager and ReputationManager.has_method("remove_reputation"):
		ReputationManager.remove_reputation(cancel_reputation_penalty)

	if get_node_or_null("/root/DeliveryStatsManager") != null:
		DeliveryStatsManager.register_failure()

	_clear_navigation_route()

	delivery_cancelled.emit()

	print("Entrega cancelada.")
	print("Penalização:", cancel_reputation_penalty, "REP")

	_reset_delivery()


func update_delivery_distance(player_position: Vector3) -> void:
	if not active_delivery:
		return

	if target_lot == null:
		return

	current_destination_position = target_lot.global_position

	var distance: float = player_position.distance_to(current_destination_position)

	delivery_updated.emit(
		current_destination_name,
		distance,
		current_reward_money,
		int(ceil(time_left_seconds))
	)


func calculate_time_limit(distance: float) -> int:
	var calculated_time: int = int(distance * seconds_per_meter)

	return clamp(
		calculated_time,
		min_time_limit_seconds,
		max_time_limit_seconds
	)


func calculate_money_reward(distance: float) -> int:
	var reward: int = int(base_reward_money + distance * reward_per_meter)

	if ReputationManager and ReputationManager.has_method("get_reputation_level"):
		var level: String = ReputationManager.get_reputation_level()

		match level:
			"Suspeito":
				reward = int(reward * 0.85)
			"Normal":
				reward = int(reward * 1.0)
			"Confiável":
				reward = int(reward * 1.15)
			"Respeitado":
				reward = int(reward * 1.30)
			"Elite":
				reward = int(reward * 1.50)

	if get_node_or_null("/root/DeliveryStatsManager") != null:
		reward = int(reward * DeliveryStatsManager.get_reward_multiplier())

	return max(reward, base_reward_money)


func calculate_reputation_reward(distance: float) -> int:
	if distance >= 80.0:
		return base_reward_reputation + 3
	elif distance >= 50.0:
		return base_reward_reputation + 2
	elif distance >= 25.0:
		return base_reward_reputation + 1

	return base_reward_reputation


func has_active_delivery() -> bool:
	return active_delivery


func get_target_lot() -> Node3D:
	return target_lot


func get_target_position() -> Vector3:
	return current_destination_position


func get_time_left() -> int:
	return int(ceil(time_left_seconds))


func get_current_destination_name() -> String:
	return current_destination_name


func _create_navigation_route() -> void:
	var route_manager := get_node_or_null("/root/RouteManager")

	if route_manager == null:
		print("DeliveryManager: RouteManager não encontrado. GPS direto continuará funcionando.")
		return

	var player := get_tree().get_first_node_in_group("player")

	if player == null or not player is Node3D:
		print("DeliveryManager: player não encontrado para criar rota.")
		return

	if target_lot == null or not is_instance_valid(target_lot):
		print("DeliveryManager: target_lot inválido para criar rota.")
		return

	route_manager.create_route(player.global_position, target_lot.global_position)


func _clear_navigation_route() -> void:
	var route_manager := get_node_or_null("/root/RouteManager")

	if route_manager != null and route_manager.has_method("clear_route"):
		route_manager.clear_route()


func _get_lot_display_name(lot: Node) -> String:
	if lot == null:
		return "Destino desconhecido"

	if "property_name" in lot:
		return lot.property_name

	if "lot_name" in lot:
		return lot.lot_name

	return lot.name


func _clear_old_delivery_targets() -> void:
	var old_targets: Array = get_tree().get_nodes_in_group("delivery_target")

	for old_target in old_targets:
		if old_target != null and old_target.is_in_group("delivery_target"):
			old_target.remove_from_group("delivery_target")


func _reset_delivery() -> void:
	if is_instance_valid(target_lot):
		if target_lot.is_in_group("delivery_target"):
			target_lot.remove_from_group("delivery_target")

	active_delivery = false
	target_lot = null
	start_position = Vector3.ZERO
	current_destination_position = Vector3.ZERO
	time_limit_seconds = 90
	time_left_seconds = 0.0
	current_reward_money = 0
	current_reward_reputation = 0
	current_destination_name = ""

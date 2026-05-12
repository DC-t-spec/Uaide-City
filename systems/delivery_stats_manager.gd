extends Node

signal stats_updated

var total_deliveries: int = 0
var successful_deliveries: int = 0
var failed_deliveries: int = 0

var total_money_earned: int = 0
var total_reputation_earned: int = 0

var best_time: float = 99999.0

var delivery_level: int = 1
var delivery_xp: int = 0

var xp_per_delivery: int = 10
var xp_per_fast_bonus: int = 5


func register_success(time_used: float, money: int, reputation: int, fast_bonus: bool) -> void:
	total_deliveries += 1
	successful_deliveries += 1

	total_money_earned += money
	total_reputation_earned += reputation

	if time_used < best_time:
		best_time = time_used

	var xp_gain: int = xp_per_delivery

	if fast_bonus:
		xp_gain += xp_per_fast_bonus

	add_xp(xp_gain)

	stats_updated.emit()


func register_failure() -> void:
	total_deliveries += 1
	failed_deliveries += 1

	stats_updated.emit()


func add_xp(amount: int) -> void:
	delivery_xp += amount

	var required_xp: int = delivery_level * 50

	if delivery_xp >= required_xp:
		delivery_xp = 0
		delivery_level += 1

		print("LEVEL UP DELIVERY:", delivery_level)


func get_success_rate() -> float:
	if total_deliveries == 0:
		return 0.0

	return float(successful_deliveries) / float(total_deliveries) * 100.0


func get_reward_multiplier() -> float:
	return 1.0 + (delivery_level * 0.05)

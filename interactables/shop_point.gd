extends Node3D

# ============================================================
# UAIDE CITY - SHOP POINT
# Ponto físico de compra de produtos/serviços
# Integra PriceManager + LifeManager + UI premium
# ============================================================

@export var item_id: String = "food_basic"
@export var quantity: int = 1
@export var source: String = "market"
@export var interaction_text: String = "Pressione E para comprar"

var player_near: bool = false
var can_interact: bool = true


func _ready() -> void:
	if has_node("Area3D"):
		$Area3D.body_entered.connect(_on_body_entered)
		$Area3D.body_exited.connect(_on_body_exited)
	else:
		push_error("ShopPoint precisa de um nó Area3D.")


func _process(_delta: float) -> void:
	if not player_near:
		return

	if not can_interact:
		return

	if Input.is_action_just_pressed("interact"):
		_buy_item()


func _buy_item() -> void:
	can_interact = false

	if quantity <= 0:
		_show_error("Quantidade inválida no ShopPoint.")
		can_interact = true
		return

	if not PriceManager.has_method("buy_item"):
		_show_error("PriceManager não tem buy_item().")
		can_interact = true
		return

	if not PriceManager.has_item(item_id):
		_show_error("Produto não encontrado: " + item_id)
		can_interact = true
		return

	var result: Dictionary = PriceManager.buy_item(item_id, quantity, source)

	var ui = get_tree().get_first_node_in_group("ui")

	if ui != null and ui.has_method("show_purchase_feedback"):
		ui.show_purchase_feedback(result)
	else:
		_print_purchase_fallback(result)

	await get_tree().create_timer(0.3).timeout
	can_interact = true


func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return

	player_near = true

	var message: String = _get_interaction_message()

	var ui = get_tree().get_first_node_in_group("ui")

	if ui != null and ui.has_method("show_system_message"):
		ui.show_system_message(message)
	else:
		print(message)


func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		player_near = false


func _get_interaction_message() -> String:
	if not PriceManager.has_item(item_id):
		return "Produto não encontrado: " + item_id

	var item_name: String = item_id
	var total_price: int = 0

	if PriceManager.has_method("get_item_name"):
		item_name = PriceManager.get_item_name(item_id)

	if PriceManager.has_method("get_total_price"):
		total_price = PriceManager.get_total_price(item_id) * quantity

	return "%s | Item: %s | Qtd: %s | Total: %s MZN" % [
		interaction_text,
		item_name,
		quantity,
		total_price
	]


func _print_purchase_fallback(result: Dictionary) -> void:
	var success: bool = bool(result.get("success", false))
	var message: String = str(result.get("message", ""))
	var item_name: String = str(result.get("item_name", result.get("name", item_id)))
	var total_price: int = int(result.get("total_price", result.get("final_total", 0)))

	if success:
		print("Compra realizada:", item_name, "x", quantity, "| Total:", total_price, "MZN")
	else:
		print("Compra falhou:", message)


func _show_error(message: String) -> void:
	var ui = get_tree().get_first_node_in_group("ui")

	if ui != null and ui.has_method("show_error_message"):
		ui.show_error_message(message)
	else:
		print("Erro:", message)

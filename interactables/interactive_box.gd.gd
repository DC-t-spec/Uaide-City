extends Node3D

@export var price: int = 10

var player_near: bool = false


func _process(_delta: float) -> void:
	if player_near and Input.is_action_just_pressed("interact"):
		var success := EconomyManager.spend_money(price)

		if success:
			print("Compraste! Valor pago:", price)
		else:
			print("Dinheiro insuficiente!")


func _on_area_3d_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		player_near = true
		print("Pressione E para comprar")


func _on_area_3d_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		player_near = false

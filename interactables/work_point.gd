extends Node3D

@export var reward_amount: int = 50000
@export var cooldown: float = 5.0

var player_near: CharacterBody3D = null
var can_interact: bool = true


func _ready() -> void:
	$Area3D.body_entered.connect(_on_body_entered)
	$Area3D.body_exited.connect(_on_body_exited)


func _process(_delta: float) -> void:
	if player_near == null:
		return

	if Input.is_action_just_pressed("interact") and can_interact:
		EconomyManager.add_money(reward_amount)
		print("Recompensa recebida! Dinheiro atual:", EconomyManager.get_money())

		can_interact = false
		await get_tree().create_timer(cooldown).timeout
		can_interact = true


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		player_near = body
		print("Pressione E para trabalhar/ganhar dinheiro")


func _on_body_exited(body: Node) -> void:
	if body == player_near:
		player_near = null

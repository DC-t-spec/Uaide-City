extends Node3D

@onready var interaction_area: Area3D = $InteractionArea

var player_inside: bool = false
var current_player: Node3D = null


func _ready() -> void:
	interaction_area.body_entered.connect(_on_body_entered)
	interaction_area.body_exited.connect(_on_body_exited)


func _process(_delta: float) -> void:
	if player_inside and Input.is_action_just_pressed("interact"):
		start_delivery()


func _on_body_entered(body: Node3D) -> void:
	if body.name == "Player":
		player_inside = true
		current_player = body
		print("Pressiona E para aceitar uma entrega.")


func _on_body_exited(body: Node3D) -> void:
	if body.name == "Player":
		player_inside = false
		current_player = null


func start_delivery() -> void:
	if current_player == null:
		return

	print("Entrega iniciada no DeliveryHub.")
	DeliveryManager.start_delivery(current_player.global_position)

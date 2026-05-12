extends Node3D

@onready var light: OmniLight3D = get_node_or_null("OmniLight3D")


func _ready() -> void:
	if light == null:
		push_error("StreetLight: OmniLight3D não encontrado.")
		return

	if not TimeManager.hour_changed.is_connected(_update_light):
		TimeManager.hour_changed.connect(_update_light)

	_update_light()


func _update_light(_h: int = 0) -> void:
	if light == null:
		return

	var hour: int = TimeManager.current_hour

	# liga a partir das 15h
	if hour >= 15 or hour < 6:
		light.visible = true
	else:
		light.visible = false

extends Control

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	get_tree().paused = false

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		toggle_pause()

func toggle_pause():
	var paused := !get_tree().paused
	get_tree().paused = paused
	visible = paused

	if paused:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _on_resume_button_pressed():
	toggle_pause()

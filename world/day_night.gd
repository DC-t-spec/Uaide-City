extends Node3D

# ============================================================
# UAIDE CITY - DAY / NIGHT VISUAL PRO
# Versão mais clara e jogável
# ============================================================

@onready var sun: DirectionalLight3D = get_node_or_null("DirectionalLight3D")
@onready var world_environment: WorldEnvironment = get_node_or_null("WorldEnvironment")

var environment: Environment = null


func _ready() -> void:
	if sun == null:
		push_error("DayNight: DirectionalLight3D não encontrado.")
		return

	if world_environment == null:
		push_error("DayNight: WorldEnvironment não encontrado.")
		return

	if world_environment.environment == null:
		world_environment.environment = Environment.new()

	environment = world_environment.environment

	if not TimeManager.hour_changed.is_connected(_on_hour_changed):
		TimeManager.hour_changed.connect(_on_hour_changed)

	_update_day_night()


func _on_hour_changed(_hour: int) -> void:
	_update_day_night()


func _update_day_night() -> void:
	var hour: int = TimeManager.current_hour
	var minute: int = TimeManager.current_minute
	var time_float: float = float(hour) + float(minute) / 60.0

	_update_sun_rotation(time_float)
	_update_visual_phase(time_float)


func _update_sun_rotation(time_float: float) -> void:
	# sol nasce de manhã, fica alto ao meio-dia e desce à tarde
	var sun_height: float = sin((time_float - 6.0) / 12.0 * PI)
	sun_height = clamp(sun_height, -0.2, 1.0)

	sun.rotation_degrees.x = lerp(-15.0, -75.0, sun_height)
	sun.rotation_degrees.y = -35.0


func _update_visual_phase(time_float: float) -> void:
	# NOITE / MADRUGADA
	if time_float >= 20.0 or time_float < 5.0:
		_apply_visual(
			0.10,
			Color(0.45, 0.50, 1.0),
			Color(0.02, 0.025, 0.07),
			Color(0.08, 0.09, 0.16),
			0.35
		)
		return

	# AMANHECER
	if time_float >= 5.0 and time_float < 8.0:
		var t: float = inverse_lerp(5.0, 8.0, time_float)

		_apply_visual(
			lerp(0.45, 1.15, t),
			Color(1.0, 0.72, 0.45).lerp(Color(1.0, 0.92, 0.80), t),
			Color(0.40, 0.36, 0.50).lerp(Color(0.48, 0.70, 1.0), t),
			Color(0.35, 0.32, 0.42).lerp(Color(0.62, 0.70, 0.82), t),
			lerp(0.45, 0.85, t)
		)
		return

	# DIA CLARO: 08h - 15h
	if time_float >= 8.0 and time_float < 15.0:
		var midday_strength: float = 1.0 - abs(time_float - 12.0) / 4.0
		midday_strength = clamp(midday_strength, 0.0, 1.0)

		_apply_visual(
			lerp(1.35, 1.75, midday_strength),
			Color(1.0, 0.95, 0.84).lerp(Color(1.0, 1.0, 0.94), midday_strength),
			Color(0.42, 0.66, 1.0).lerp(Color(0.35, 0.62, 1.0), midday_strength),
			Color(0.72, 0.78, 0.86).lerp(Color(0.82, 0.86, 0.92), midday_strength),
			lerp(0.90, 1.10, midday_strength)
		)
		return

	# TARDE
	if time_float >= 15.0 and time_float < 16.0:
		var t2: float = inverse_lerp(15.0, 16.0, time_float)

		_apply_visual(
			lerp(1.25, 1.05, t2),
			Color(1.0, 0.90, 0.72).lerp(Color(1.0, 0.70, 0.40), t2),
			Color(0.48, 0.66, 0.95).lerp(Color(0.78, 0.48, 0.28), t2),
			Color(0.70, 0.72, 0.80).lerp(Color(0.65, 0.48, 0.36), t2),
			lerp(0.85, 0.65, t2)
		)
		return

	# PÔR DO SOL
	if time_float >= 16.0 and time_float < 18.0:
		var t3: float = inverse_lerp(16.0, 18.0, time_float)

		_apply_visual(
			lerp(1.00, 0.55, t3),
			Color(1.0, 0.68, 0.32).lerp(Color(1.0, 0.45, 0.25), t3),
			Color(0.86, 0.50, 0.26).lerp(Color(0.55, 0.32, 0.34), t3),
			Color(0.68, 0.48, 0.34).lerp(Color(0.42, 0.34, 0.40), t3),
			lerp(0.65, 0.42, t3)
		)
		return

	# ANOITECER
	if time_float >= 18.0 and time_float < 20.0:
		var t4: float = inverse_lerp(18.0, 20.0, time_float)

		_apply_visual(
			lerp(0.45, 0.12, t4),
			Color(0.80, 0.58, 1.0).lerp(Color(0.35, 0.42, 0.85), t4),
			Color(0.28, 0.20, 0.40).lerp(Color(0.02, 0.025, 0.07), t4),
			Color(0.28, 0.25, 0.38).lerp(Color(0.08, 0.09, 0.16), t4),
			lerp(0.45, 0.32, t4)
		)
		return


func _apply_visual(
	sun_energy: float,
	sun_color: Color,
	sky_color: Color,
	ambient_color: Color,
	ambient_energy: float
) -> void:
	if environment == null:
		return

	sun.light_energy = sun_energy
	sun.light_color = sun_color
	sun.shadow_enabled = true
	sun.shadow_bias = 0.08

	environment.background_mode = Environment.BG_COLOR
	environment.background_color = sky_color

	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = ambient_color
	environment.ambient_light_energy = ambient_energy

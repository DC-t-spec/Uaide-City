extends Node3D

# ============================================================
# UAIDE CITY - DAY / NIGHT VISUAL PRO
# Versão mais clara e jogável
# ============================================================

@onready var sun: DirectionalLight3D = get_node_or_null("DirectionalLight3D")
@onready var world_environment: WorldEnvironment = get_node_or_null("WorldEnvironment")

var environment: Environment = null
var sky_material: ProceduralSkyMaterial = null


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
	_ensure_environment_setup()

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


func _ensure_environment_setup() -> void:
	environment.background_mode = Environment.BG_SKY

	if environment.sky == null:
		environment.sky = Sky.new()

	if environment.sky.sky_material is ProceduralSkyMaterial:
		sky_material = environment.sky.sky_material as ProceduralSkyMaterial
	else:
		sky_material = ProceduralSkyMaterial.new()
		environment.sky.sky_material = sky_material

	# Tonemap / exposição (leitura mais cinematográfica e leve)
	environment.tonemap_mode = Environment.TONE_MAPPER_ACES
	environment.tonemap_exposure = 1.05
	environment.tonemap_white = 1.8
	environment.adjustment_enabled = true
	environment.adjustment_contrast = 1.08
	environment.adjustment_saturation = 1.06
	environment.adjustment_brightness = 1.02

	# Bloom sutil para realçar sol/janelas sem pesar
	environment.glow_enabled = true
	environment.glow_intensity = 0.55
	environment.glow_strength = 0.55
	environment.glow_bloom = 0.08
	environment.glow_hdr_threshold = 1.15
	environment.set("glow_levels/1", true)
	environment.set("glow_levels/2", true)
	environment.set("glow_levels/3", true)

	# SSAO suave para profundidade
	environment.ssao_enabled = true
	environment.ssao_radius = 0.7
	environment.ssao_intensity = 1.1
	environment.ssao_power = 1.3
	environment.ssao_detail = 0.4

	# Névoa leve para sensação urbana
	environment.fog_enabled = true
	environment.fog_density = 0.01
	environment.fog_light_energy = 0.8

	# Sombras menos agressivas
	sun.shadow_enabled = true
	sun.shadow_bias = 0.05
	sun.directional_shadow_max_distance = 85.0


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
			0.20,
			Color(0.45, 0.50, 1.0),
			Color(0.08, 0.10, 0.20),
			Color(0.15, 0.18, 0.28),
			Color(0.10, 0.13, 0.24),
			0.55,
			0.012
		)
		return

	# AMANHECER
	if time_float >= 5.0 and time_float < 8.0:
		var t: float = inverse_lerp(5.0, 8.0, time_float)

		_apply_visual(
			lerp(0.45, 1.15, t),
			Color(1.0, 0.72, 0.45).lerp(Color(1.0, 0.92, 0.80), t),
			Color(0.34, 0.30, 0.52).lerp(Color(0.52, 0.74, 1.0), t),
			Color(0.35, 0.32, 0.42).lerp(Color(0.62, 0.70, 0.82), t),
			Color(0.55, 0.44, 0.36).lerp(Color(0.80, 0.84, 0.94), t),
			lerp(0.58, 0.95, t),
			lerp(0.018, 0.010, t)
		)
		return

	# DIA CLARO: 08h - 15h
	if time_float >= 8.0 and time_float < 15.0:
		var midday_strength: float = 1.0 - abs(time_float - 12.0) / 4.0
		midday_strength = clamp(midday_strength, 0.0, 1.0)

		_apply_visual(
			lerp(1.05, 1.35, midday_strength),
			Color(1.0, 0.95, 0.84).lerp(Color(1.0, 1.0, 0.94), midday_strength),
			Color(0.48, 0.74, 1.0).lerp(Color(0.42, 0.70, 1.0), midday_strength),
			Color(0.72, 0.78, 0.86).lerp(Color(0.82, 0.86, 0.92), midday_strength),
			Color(0.84, 0.88, 0.95).lerp(Color(0.90, 0.93, 0.98), midday_strength),
			lerp(0.92, 1.15, midday_strength),
			0.009
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
			Color(0.78, 0.74, 0.70).lerp(Color(0.68, 0.52, 0.40), t2),
			lerp(0.85, 0.72, t2),
			lerp(0.010, 0.014, t2)
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
			Color(0.72, 0.50, 0.34).lerp(Color(0.46, 0.36, 0.42), t3),
			lerp(0.72, 0.56, t3),
			lerp(0.014, 0.020, t3)
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
			Color(0.40, 0.33, 0.44).lerp(Color(0.12, 0.14, 0.24), t4),
			lerp(0.52, 0.42, t4),
			lerp(0.020, 0.013, t4)
		)
		return


func _apply_visual(
	sun_energy: float,
	sun_color: Color,
	sky_color: Color,
	ambient_color: Color,
	horizon_color: Color,
	ambient_energy: float,
	fog_density: float
) -> void:
	if environment == null:
		return

	sun.light_energy = sun_energy
	sun.light_color = sun_color
	sun.shadow_enabled = true

	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = ambient_color
	environment.ambient_light_energy = ambient_energy
	environment.fog_density = fog_density
	environment.fog_light_color = sun_color

	if sky_material != null:
		sky_material.sky_top_color = sky_color
		sky_material.sky_horizon_color = horizon_color
		sky_material.ground_horizon_color = ambient_color
		sky_material.ground_bottom_color = ambient_color.darkened(0.15)

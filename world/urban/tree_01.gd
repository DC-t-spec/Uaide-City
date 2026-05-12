extends Node3D

@export var trunk_color: Color = Color("#6B4F2B")
@export var leaves_color: Color = Color("#39D98A")
@export var leaves_shadow_color: Color = Color("#1E9F5B")

@export var apply_random_variation: bool = false
@export var random_scale_min: float = 0.95
@export var random_scale_max: float = 1.08
@export var random_rotation: bool = false

@export var trunk_height: float = 1.8
@export var trunk_radius: float = 0.16
@export var leaves_height: float = 2.25
@export var leaves_scale: Vector3 = Vector3(1.25, 0.85, 1.25)

@onready var trunk: MeshInstance3D = get_node_or_null("Trunk")
@onready var leaves: MeshInstance3D = get_node_or_null("Leaves")


func _ready() -> void:
	_setup_shape()
	_apply_variation()
	_apply_materials()


func _setup_shape() -> void:
	if trunk != null:
		trunk.position = Vector3(0.0, trunk_height * 0.5, 0.0)
		trunk.scale = Vector3(trunk_radius, trunk_height * 0.5, trunk_radius)

	if leaves != null:
		leaves.position = Vector3(0.0, leaves_height, 0.0)
		leaves.scale = leaves_scale


func _apply_variation() -> void:
	if not apply_random_variation:
		return

	var s := randf_range(random_scale_min, random_scale_max)
	scale = Vector3(s, s, s)

	if random_rotation:
		rotation.y = randf_range(0.0, TAU)


func _apply_materials() -> void:
	if trunk != null:
		var trunk_mat := StandardMaterial3D.new()
		trunk_mat.albedo_color = trunk_color
		trunk_mat.roughness = 0.9
		trunk.material_override = trunk_mat

	if leaves != null:
		var leaves_mat := StandardMaterial3D.new()
		leaves_mat.albedo_color = leaves_color
		leaves_mat.roughness = 0.75
		leaves_mat.emission_enabled = true
		leaves_mat.emission = leaves_shadow_color
		leaves_mat.emission_energy_multiplier = 0.15
		leaves.material_override = leaves_mat

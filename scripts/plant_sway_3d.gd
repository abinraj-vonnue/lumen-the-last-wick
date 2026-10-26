@tool
extends Node3D

@export_range(0.0, 12.0, 0.1) var sway_degrees: float = 3.0
@export_range(0.1, 5.0, 0.1) var sway_speed: float = 1.5
@export var phase_offset: float = 0.0

var _base_rotation: float
var _time: float = 0.0


func _ready() -> void:
	_base_rotation = rotation.z


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_time += delta
	rotation.z = _base_rotation + sin(_time * sway_speed + phase_offset) * deg_to_rad(sway_degrees)

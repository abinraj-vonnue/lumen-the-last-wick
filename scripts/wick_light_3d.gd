extends OmniLight3D

@export var flare_range_bonus: float = 1.8
@export var flare_energy_multiplier: float = 1.65
@export var flare_range_multiplier: float = 1.65

var _base_range: float
var _base_energy: float
var _flare_active: bool = false
var _time: float = 0.0


func _ready() -> void:
	_base_range = omni_range
	_base_energy = light_energy


func _process(delta: float) -> void:
	_time += delta
	var breathe := sin(_time * 4.2) * 0.035
	var range_multiplier := flare_range_multiplier if _flare_active else 1.0 + breathe
	var energy_multiplier := flare_energy_multiplier if _flare_active else 1.0 + breathe
	omni_range = _base_range * range_multiplier
	light_energy = _base_energy * energy_multiplier


func set_flare_active(active: bool) -> void:
	_flare_active = active


func get_platform_range_bonus() -> float:
	return flare_range_bonus if _flare_active else 0.0

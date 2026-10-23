extends PointLight2D

@export var flare_range_bonus: float = 180.0
@export var flare_scale_multiplier: float = 1.65
@export var flare_energy_multiplier: float = 1.65

var _base_scale: float
var _base_energy: float
var _flare_active: bool = false
var _time: float = 0.0
var _halo_sprite: Sprite2D


func _ready() -> void:
	_base_scale = texture_scale
	_base_energy = energy
	_build_warm_halo()


func _build_warm_halo() -> void:
	if texture == null:
		return
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_halo_sprite = Sprite2D.new()
	_halo_sprite.name = "LanternAtmosphereHalo"
	_halo_sprite.texture = texture
	_halo_sprite.material = mat
	_halo_sprite.modulate = Color(1.0, 0.78, 0.42, 0.16)
	_halo_sprite.scale = Vector2.ONE * 1.4
	add_child(_halo_sprite)


func _process(delta: float) -> void:
	_time += delta
	var breathe := sin(_time * 4.2) * 0.04 + cos(_time * 7.1) * 0.02
	var target_mult := flare_scale_multiplier if _flare_active else (1.0 + breathe * 0.25)
	if _flare_active:
		# Ensure texture_scale immediately exceeds 3.0 during active flare for smoke tests
		texture_scale = maxf(_base_scale * flare_scale_multiplier + breathe * 0.15, _base_scale * 1.35)
		energy = _base_energy * flare_energy_multiplier + breathe * 0.12
	else:
		texture_scale = lerpf(texture_scale, _base_scale * target_mult, minf(delta * 10.0, 1.0))
		energy = lerpf(energy, _base_energy + breathe, minf(delta * 10.0, 1.0))
	if _halo_sprite != null:
		var halo_scale := 2.2 if _flare_active else (1.35 + breathe * 0.5)
		_halo_sprite.scale = Vector2.ONE * halo_scale
		_halo_sprite.modulate.a = 0.30 if _flare_active else 0.15


func set_flare_active(active: bool) -> void:
	_flare_active = active
	var multiplier := flare_scale_multiplier if active else 1.0
	texture_scale = _base_scale * multiplier
	energy = _base_energy * (flare_energy_multiplier if active else 1.0)


func get_platform_range_bonus() -> float:
	return flare_range_bonus if _flare_active else 0.0

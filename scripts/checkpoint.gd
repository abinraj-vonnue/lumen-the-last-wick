extends Area2D

signal activated(checkpoint: Area2D, respawn_position: Vector2)

@export var respawn_offset: Vector2 = Vector2(0.0, -24.0)

@onready var visual: Polygon2D = $Visual

var _activated: bool = false
var _time: float = 0.0
var _flame_node: Polygon2D
var _halo_node: Polygon2D
var _core_node: Polygon2D
var _embers: CPUParticles2D


func _ready() -> void:
	add_to_group("checkpoint")
	body_entered.connect(_on_body_entered)
	_build_shrine_art()


func _process(delta: float) -> void:
	_time += delta
	if _flame_node != null and _activated:
		var flicker := 1.0 + sin(_time * 9.5) * 0.11 + cos(_time * 15.0) * 0.06
		_flame_node.scale = Vector2(1.0 + sin(_time * 6.0) * 0.06, flicker)
	if _halo_node != null:
		var base_alpha := 0.32 if _activated else 0.07
		var pulse := sin(_time * (4.2 if _activated else 2.0)) * (0.06 if _activated else 0.02)
		_halo_node.color.a = base_alpha + pulse


func _build_shrine_art() -> void:
	# Reshape the primary visual into an ornate carved lantern post silhouette
	visual.color = Color("#4a5a78")
	visual.polygon = PackedVector2Array([
		Vector2(-14, 30), Vector2(-11, 20), Vector2(-5, 16),
		Vector2(-4, -14), Vector2(-10, -18), Vector2(-12, -25),
		Vector2(0, -34), Vector2(12, -25), Vector2(10, -18),
		Vector2(4, -14), Vector2(5, 16), Vector2(11, 20), Vector2(14, 30),
	])

	var plinth := Polygon2D.new()
	plinth.name = "ShrinePlinth"
	plinth.color = Color("#242b42")
	plinth.z_index = -1
	plinth.polygon = PackedVector2Array([
		Vector2(-20, 30), Vector2(-16, 22), Vector2(16, 22), Vector2(20, 30),
	])
	add_child(plinth)

	var glass := Polygon2D.new()
	glass.name = "LanternChamber"
	glass.color = Color(0.16, 0.21, 0.33, 0.85)
	glass.polygon = PackedVector2Array([
		Vector2(-8, -14), Vector2(-9, -24), Vector2(0, -29),
		Vector2(9, -24), Vector2(8, -14),
	])
	add_child(glass)

	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD

	_halo_node = Polygon2D.new()
	_halo_node.name = "ShrineHalo"
	_halo_node.position = Vector2(0, -21)
	_halo_node.color = Color(0.45, 0.68, 0.92, 0.08)
	_halo_node.material = mat
	var halo_pts := PackedVector2Array()
	for i in 16:
		var angle := float(i) * TAU / 16.0
		halo_pts.append(Vector2(cos(angle), sin(angle)) * 34.0)
	_halo_node.polygon = halo_pts
	add_child(_halo_node)

	_flame_node = Polygon2D.new()
	_flame_node.name = "SpiritFlame"
	_flame_node.position = Vector2(0, -16)
	_flame_node.color = Color(1.0, 0.72, 0.28, 0.95)
	_flame_node.visible = false
	_flame_node.polygon = PackedVector2Array([
		Vector2(0, -14), Vector2(6, -5), Vector2(4, 1),
		Vector2(0, 3), Vector2(-4, 1), Vector2(-6, -5),
	])
	add_child(_flame_node)

	_core_node = Polygon2D.new()
	_core_node.name = "FlameCore"
	_core_node.color = Color(1.0, 0.96, 0.82, 1.0)
	_core_node.polygon = PackedVector2Array([
		Vector2(0, -9), Vector2(3, -4), Vector2(0, 1), Vector2(-3, -4),
	])
	_flame_node.add_child(_core_node)

	_embers = CPUParticles2D.new()
	_embers.name = "ShrineEmbers"
	_embers.position = Vector2(0, -22)
	_embers.emitting = false
	_embers.amount = 14
	_embers.lifetime = 1.3
	_embers.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	_embers.emission_sphere_radius = 6.0
	_embers.direction = Vector2(0, -1)
	_embers.spread = 28.0
	_embers.gravity = Vector2(0, -22)
	_embers.initial_velocity_min = 8.0
	_embers.initial_velocity_max = 20.0
	_embers.scale_amount_min = 1.5
	_embers.scale_amount_max = 3.0
	_embers.color = Color(1.0, 0.84, 0.46, 0.75)
	add_child(_embers)


func _on_body_entered(body: Node2D) -> void:
	if _activated or not body.is_in_group("player"):
		return
	_activated = true
	visual.color = Color("#FFD58A")
	if _flame_node != null:
		_flame_node.visible = true
		_flame_node.scale = Vector2(0.2, 0.2)
		var tween := create_tween()
		tween.tween_property(_flame_node, "scale", Vector2.ONE, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if _halo_node != null:
		_halo_node.color = Color(1.0, 0.78, 0.36, 0.36)
	if _embers != null:
		_embers.emitting = true
	var audio := get_node_or_null("/root/AudioDirector")
	if audio != null and audio.has_method("play_sfx"):
		audio.call("play_sfx", "checkpoint")
	activated.emit(self, global_position + respawn_offset)

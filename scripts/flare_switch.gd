extends Node2D

signal activated

## This is a one-shot puzzle trigger: once a flare reaches it, it stays activated.

@export var activation_distance: float = 360.0
@export var requires_line_of_sight: bool = true

@onready var visual: Polygon2D = $Visual

var _activated: bool = false
var _player: Node2D
var _time: float = 0.0
var _outer_ring: Node2D
var _halo: Polygon2D
var _inner_gem: Polygon2D


func _ready() -> void:
	visual.color = Color("#70809C")
	_build_astrolabe_art()
	_player = get_tree().get_first_node_in_group("player") as Node2D
	if _player != null and _player.has_signal("flare_started"):
		_player.flare_started.connect(_on_flare_started)


func _process(delta: float) -> void:
	_time += delta
	if _outer_ring != null:
		var rot_speed := 1.8 if _activated else 0.35
		_outer_ring.rotation += delta * rot_speed
	if _halo != null:
		var base_a := 0.34 if _activated else 0.08
		_halo.color.a = base_a + sin(_time * (5.0 if _activated else 2.2)) * 0.05


func _build_astrolabe_art() -> void:
	visual.polygon = PackedVector2Array([
		Vector2(0, -18), Vector2(15, 0), Vector2(0, 18), Vector2(-15, 0),
	])

	var add_mat := CanvasItemMaterial.new()
	add_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD

	_halo = Polygon2D.new()
	_halo.name = "SwitchHalo"
	_halo.color = Color(0.55, 0.72, 0.95, 0.08)
	_halo.material = add_mat
	_halo.z_index = -1
	var pts := PackedVector2Array()
	for i in 16:
		var a := float(i) * TAU / 16.0
		pts.append(Vector2(cos(a), sin(a)) * 28.0)
	_halo.polygon = pts
	add_child(_halo)

	_outer_ring = Node2D.new()
	_outer_ring.name = "AstrolabeRing"
	add_child(_outer_ring)
	for idx in 4:
		var fin := Polygon2D.new()
		fin.color = Color(0.52, 0.62, 0.78, 0.85)
		fin.rotation = float(idx) * PI * 0.5 + PI * 0.25
		fin.polygon = PackedVector2Array([
			Vector2(0, -22), Vector2(4, -15), Vector2(0, -12), Vector2(-4, -15),
		])
		_outer_ring.add_child(fin)

	_inner_gem = Polygon2D.new()
	_inner_gem.name = "InnerGem"
	_inner_gem.color = Color(0.78, 0.86, 0.98, 0.9)
	_inner_gem.polygon = PackedVector2Array([
		Vector2(0, -9), Vector2(7, 0), Vector2(0, 9), Vector2(-7, 0),
	])
	add_child(_inner_gem)


func _on_flare_started(origin: Vector2) -> void:
	if _activated or origin.distance_to(global_position) > activation_distance:
		return
	if requires_line_of_sight and not _has_clear_line(origin):
		return
	_activated = true
	visual.color = Color("#FFD58A")
	if _inner_gem != null:
		_inner_gem.color = Color(1.0, 0.98, 0.86, 1.0)
	if _halo != null:
		_halo.color = Color(1.0, 0.82, 0.38, 0.38)
	var audio := get_node_or_null("/root/AudioDirector")
	if audio != null and audio.has_method("play_sfx"):
		audio.call("play_sfx", "switch")
	activated.emit()


func _has_clear_line(origin: Vector2) -> bool:
	var world := get_world_2d()
	if world == null:
		return false
	var excluded: Array[RID] = []
	var owner_node: Node = _player
	while owner_node != null:
		if owner_node is CollisionObject2D:
			excluded.append((owner_node as CollisionObject2D).get_rid())
		owner_node = owner_node.get_parent()
	var query := PhysicsRayQueryParameters2D.create(origin, global_position)
	query.exclude = excluded
	query.collide_with_bodies = true
	query.collide_with_areas = false
	return world.direct_space_state.intersect_ray(query).is_empty()

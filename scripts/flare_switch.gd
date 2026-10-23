extends Node2D

signal activated

@export var activation_distance: float = 360.0
@export var requires_line_of_sight: bool = true

@onready var visual: Polygon2D = $Visual

var _activated: bool = false
var _player: Node2D


func _ready() -> void:
	visual.color = Color("#70809C")
	_player = get_tree().get_first_node_in_group("player") as Node2D
	if _player != null and _player.has_signal("flare_started"):
		_player.flare_started.connect(_on_flare_started)


func _on_flare_started(origin: Vector2) -> void:
	if _activated or origin.distance_to(global_position) > activation_distance:
		return
	if requires_line_of_sight and not _has_clear_line(origin):
		return
	_activated = true
	visual.color = Color("#FFD58A")
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

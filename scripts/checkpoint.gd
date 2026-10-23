extends Area2D

signal activated(checkpoint: Area2D, respawn_position: Vector2)

@export var respawn_offset: Vector2 = Vector2(0.0, -24.0)

@onready var visual: Polygon2D = $Visual

var _activated: bool = false


func _ready() -> void:
	add_to_group("checkpoint")
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if _activated or not body.is_in_group("player"):
		return
	_activated = true
	visual.color = Color("#FFD58A")
	activated.emit(self, global_position + respawn_offset)

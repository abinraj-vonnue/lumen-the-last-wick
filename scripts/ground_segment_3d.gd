@tool
extends StaticBody3D

@export var dimensions: Vector3 = Vector3(3.5, 0.6, 1.2):
	set(value):
		dimensions = Vector3(maxf(value.x, 0.2), maxf(value.y, 0.1), maxf(value.z, 0.2))
		if is_inside_tree():
			_sync_dimensions()

@export var art_texture: Texture2D


func _ready() -> void:
	_sync_dimensions()


func _sync_dimensions() -> void:
	var shape_node := get_node_or_null("CollisionShape3D") as CollisionShape3D
	if shape_node != null and shape_node.shape is BoxShape3D:
		(shape_node.shape as BoxShape3D).size = dimensions
	var sprite := get_node_or_null("Visual") as Sprite3D
	if sprite != null and art_texture != null:
		sprite.texture = art_texture
		sprite.pixel_size = 0.01
		var uniform_scale := dimensions.x / (art_texture.get_width() * sprite.pixel_size)
		sprite.scale = Vector3(uniform_scale, uniform_scale, 1.0)
		var art_height := art_texture.get_height() * sprite.pixel_size * uniform_scale
		sprite.position = Vector3(0.0, dimensions.y * 0.5 - art_height * 0.5, -0.04)

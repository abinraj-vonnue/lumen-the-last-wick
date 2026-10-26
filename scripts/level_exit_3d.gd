extends Area3D

signal completed

var _is_complete: bool = false
var _time: float = 0.0


func _ready() -> void:
	add_to_group("level_exit")
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	_time += delta
	var veil := get_node_or_null("PortalVeil") as MeshInstance3D
	if veil != null:
		var material := veil.material_override as StandardMaterial3D
		if material != null:
			var veil_color := material.albedo_color
			veil_color.a = 0.32 + sin(_time * 3.0) * 0.08
			material.albedo_color = veil_color


func _on_body_entered(body: Node3D) -> void:
	if _is_complete or not body.is_in_group("player"):
		return
	if body.has_method("is_dying") and body.call("is_dying"):
		return
	_is_complete = true
	if body.has_method("complete"):
		body.call("complete")
	var audio := get_node_or_null("/root/AudioDirector")
	if audio != null and audio.has_method("play_sfx"):
		audio.call("play_sfx", "complete")
	completed.emit()

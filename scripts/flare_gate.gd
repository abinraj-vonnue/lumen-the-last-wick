extends StaticBody2D

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var visual: Polygon2D = $Visual

var _opened: bool = false
var _time: float = 0.0
var _rune_channel: Polygon2D
var _seal_crest: Polygon2D


func _ready() -> void:
	_build_monolith_art()


func _process(delta: float) -> void:
	_time += delta
	if not _opened and _rune_channel != null:
		_rune_channel.color.a = 0.55 + sin(_time * 3.2) * 0.20


func _build_monolith_art() -> void:
	visual.color = Color(0.20, 0.26, 0.38, 0.98)
	visual.polygon = PackedVector2Array([
		Vector2(-14, -130), Vector2(-9, -134), Vector2(9, -134), Vector2(14, -130),
		Vector2(15, -45), Vector2(13, 0), Vector2(15, 55),
		Vector2(14, 130), Vector2(-14, 130),
		Vector2(-15, 55), Vector2(-13, 0), Vector2(-15, -45),
	])

	var trim_left := Polygon2D.new()
	trim_left.color = Color(0.34, 0.44, 0.62, 0.9)
	trim_left.polygon = PackedVector2Array([
		Vector2(-14, -130), Vector2(-9, -130), Vector2(-9, 130), Vector2(-14, 130),
	])
	visual.add_child(trim_left)

	_rune_channel = Polygon2D.new()
	_rune_channel.name = "RuneChannel"
	_rune_channel.color = Color(0.45, 0.78, 0.96, 0.7)
	_rune_channel.polygon = PackedVector2Array([
		Vector2(-3, -118), Vector2(3, -118), Vector2(4, 0),
		Vector2(3, 118), Vector2(-3, 118), Vector2(-4, 0),
	])
	visual.add_child(_rune_channel)

	_seal_crest = Polygon2D.new()
	_seal_crest.name = "SealCrest"
	_seal_crest.color = Color(0.95, 0.78, 0.45, 0.9)
	_seal_crest.polygon = PackedVector2Array([
		Vector2(0, -22), Vector2(11, 0), Vector2(0, 22), Vector2(-11, 0),
	])
	visual.add_child(_seal_crest)


func open() -> void:
	if _opened:
		return
	_opened = true
	collision_shape.set_deferred("disabled", true)
	if _rune_channel != null:
		_rune_channel.color = Color(1.0, 0.88, 0.52, 1.0)
	var audio := get_node_or_null("/root/AudioDirector")
	if audio != null and audio.has_method("play_sfx"):
		audio.call("play_sfx", "gate")
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(visual, "modulate:a", 0.0, 0.25)
	tween.tween_property(visual, "position:y", visual.position.y - 24.0, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.chain().tween_callback(visual.hide)

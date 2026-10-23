extends Node2D

@export var initial_spawn_position: Vector2 = Vector2(200.0, 560.0)

var _player: CharacterBody2D
var _completion_started: bool = false


func _ready() -> void:
	_player = get_tree().get_first_node_in_group("player") as CharacterBody2D
	if _player == null:
		push_error("LevelController requires a player in the player group.")
		return
	_player.set_respawn_position(initial_spawn_position)
	_player.died.connect(_on_player_died)
	for checkpoint in get_tree().get_nodes_in_group("checkpoint"):
		_connect_checkpoint(checkpoint)
	for exit_node in get_tree().get_nodes_in_group("level_exit"):
		if exit_node.has_signal("completed"):
			exit_node.completed.connect(_on_level_completed)


func _connect_checkpoint(checkpoint: Node) -> void:
	if checkpoint.has_signal("activated"):
		checkpoint.activated.connect(_on_checkpoint_activated)


func _on_checkpoint_activated(_checkpoint: Area2D, spawn_position: Vector2) -> void:
	_player.set_respawn_position(spawn_position)
	_player.refill_dash()


func _on_player_died(player: CharacterBody2D) -> void:
	await player.respawn_at()


func _on_level_completed() -> void:
	if _completion_started:
		return
	_completion_started = true
	_player.complete()

extends Node


signal player_initialized(player: CharacterBody2D)

var current_player: CharacterBody2D = null

func set_player(p: CharacterBody2D) -> void:
    current_player = p
    player_initialized.emit(p)

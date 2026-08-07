extends Node

var current_player: CharacterBody2D = null
var current_state: PlayerRuntimeState = null

signal player_initialized(player: CharacterBody2D)

func set_player(p: CharacterBody2D, state: PlayerRuntimeState) -> void:
    current_player = p
    current_state = state
    player_initialized.emit(p)
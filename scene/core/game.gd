extends Node2D

@onready var player: CharacterBody2D = $Player
@onready var ui: CanvasLayer = $Ui


# game.gd
func _ready() -> void:
    ui.bind_state(player.state)
    ui.bind_primary_attack_slot(player.primary_attack_slot)
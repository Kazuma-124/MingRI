extends Node2D

@onready var player: CharacterBody2D = $Player
@onready var hp_status:HBoxContainer = $Ui/HpAndMpStatus

func _ready() -> void:
    player.hp_changed.connect(hp_status.update_hp)
    player.emit_update_hp()

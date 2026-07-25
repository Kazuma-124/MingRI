extends Node2D

@onready var player: CharacterBody2D = $Player
@onready var hp_and_mp_status:HBoxContainer = $Ui/HpAndMpStatus

func _ready() -> void:
    player.hp_changed.connect(hp_and_mp_status.update_hp)
    player.mp_changed.connect(hp_and_mp_status.update_mp)
    player.emit_update_hp()
    player.emit_update_mp()

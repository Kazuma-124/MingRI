extends HBoxContainer


@onready var hp_bar: ProgressBar = $HPBar
@onready var mp_bar: MpBar = $MPBar
var player:CharacterBody2D

func _ready()->void:
    mp_bar.bind_to_state(player.state)

func update_hp(new_hp: float, max_hp: float) -> void:
    hp_bar.max_value = max_hp
    hp_bar.value = new_hp

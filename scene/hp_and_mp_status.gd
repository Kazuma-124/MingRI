extends HBoxContainer


@onready var hp_bar: ProgressBar = $HPBar
@onready var mp_bar: ProgressBar = $MPBar

func update_hp(new_hp: float, max_hp: float) -> void:
    hp_bar.max_value = max_hp
    hp_bar.value = new_hp

func update_mp(new_mp: float, max_mp: float) -> void:
    mp_bar.max_value = max_mp
    mp_bar.value = new_mp
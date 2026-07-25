extends HBoxContainer


@onready var hp_bar: ProgressBar = $HPBar


func update_hp(new_hp: float, max_hp: float) -> void:
    hp_bar.max_value = max_hp
    hp_bar.value = new_hp

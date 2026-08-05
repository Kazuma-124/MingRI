extends HBoxContainer


@onready var hp_bar: ProgressBar = $HPBar
@onready var mp_bar: MpBar = $MPBar
var player:CharacterBody2D


# hp_and_mp_status.gd
func bind_state(state: PlayerRuntimeState) -> void:
    state.hp_changed.connect(update_hp)
    update_hp(state.cur_hp, state.max_hp)  # 立即刷新
    mp_bar.bind_to_state(state)


func update_hp(new_hp: float, max_hp: float) -> void:
    hp_bar.max_value = max_hp
    hp_bar.value = new_hp


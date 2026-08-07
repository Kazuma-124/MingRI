extends HBoxContainer


@onready var hp_bar: ProgressBar = $HPBar
@onready var mp_bar: MpBar = $MPBar
var player:CharacterBody2D

func _ready() -> void:
    if GameManager.current_state:
        _init_with_state(GameManager.current_state)
    else:
        GameManager.player_initialized.connect(_on_player_initialized)
    EventBus.player_hp_changed.connect(_on_player_hp_changed)
    EventBus.player_mp_changed.connect(_on_player_mp_changed)
    EventBus.player_mp_all_changed.connect(_on_player_mp_all_changed)

func _on_player_initialized(player:CharacterBody2D)->void:
    _init_with_state(player.state)
    GameManager.player_initialized.disconnect(_on_player_initialized)
func _init_with_state(state:PlayerRuntimeState)->void:
    _on_player_hp_changed(state.cur_hp,state.max_hp)
    _on_player_mp_all_changed(
        state.chiyan_mp,
        state.shengxi_mp,
        state.shuangxuan_mp,
        state.youying_mp,
        state.max_mp
    )
func _on_player_hp_changed(cur_hp:float,max_hp:float)->void:
    hp_bar.value = cur_hp
    hp_bar.max_value = max_hp
func _on_player_mp_changed(attr:AttributeTypes.Type,value)->void:
    mp_bar.set_mp(attr,value)
func _on_player_mp_all_changed(
    chiyan:float,
    shengxi:float,
    shuangxuan:float,
    youyong:float,
    max_mp:float
)->void:
    mp_bar.set_all_mp(chiyan,shengxi,shuangxuan,youyong,max_mp)



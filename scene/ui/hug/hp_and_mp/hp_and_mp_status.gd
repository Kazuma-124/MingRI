extends HBoxContainer

#region onready
@onready var _hp_bar: ProgressBar = %HpBar
@onready var _mp_bar: MpBar = %MpBar
#endregion

#region 成员变量
var _player:CharacterBody2D
#endregion

#region 生命周期
func _ready() -> void:
	EventBus.player_hp_changed.connect(_on_player_hp_changed)
	EventBus.player_mp_changed.connect(_on_player_mp_changed)
	EventBus.player_mp_all_changed.connect(_on_player_mp_all_changed)
	if GameManager.current_player:
		GameManager.current_player.init_hp_and_mp_signal()
	else:
		GameManager.player_initialized.connect(_on_player_initialized)
#endregion

#region 信号处理
func _on_player_initialized()->void:
	GameManager.current_player.init_hp_and_mp_signal()
	GameManager.player_initialized.disconnect(_on_player_hp_changed)

func _on_player_hp_changed(cur_hp:float,max_hp:float)->void:
	_hp_bar.value = cur_hp
	_hp_bar.max_value = max_hp

func _on_player_mp_changed(attr:AttributeTypes.Type,value)->void:
	_mp_bar.set_mp(attr,value)

func _on_player_mp_all_changed(
	mps:Array[float],
	max_mp:float
)->void:
	_mp_bar.set_all_mp(mps,max_mp)
#endregion

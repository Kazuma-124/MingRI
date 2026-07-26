extends Node2D

@onready var player: CharacterBody2D = $Player
@onready var hp_and_mp_status:HBoxContainer = $Ui/HpAndMpStatus
@onready var primary_attack_slot: Control = $Ui/PrimaryAttackSlot

func _ready() -> void:
    # 玩家血量和能量信息绑定ui
    player.hp_changed.connect(hp_and_mp_status.update_hp)
    player.mp_changed.connect(hp_and_mp_status.update_mp)
    player.emit_update_hp()
    player.emit_update_mp()
    # 玩家技能状态绑定ui
    # 数据变化->ui显示
    player.primary_attack_slot.skill_changed.connect(primary_attack_slot.set_skill)
    # ui点击->数据响应
    primary_attack_slot.clicked.connect(player.switch_primary_attack_skill)
    # 初始化显示
    primary_attack_slot.set_skill(player.primary_attack_slot.skill_data)

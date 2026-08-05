extends Control

signal clicked()

@onready var icon_rect: TextureRect = $SkillIcon
@onready var cooldown_mask: ProgressBar = $CooldownMask
@onready var cooldown_label: Label = $CooldownLabel


func _ready() -> void:
    set_cooldown(0.0,0.0)

func _gui_input(event: InputEvent) -> void:
    if(
        event is InputEventMouseButton and 
        event.pressed and 
        event.button_index==MOUSE_BUTTON_LEFT
    ):
        clicked.emit()
        accept_event()

# primary_attack_slot.gd
func bind_skill_slot(slot: SkillSlot) -> void:
    slot.skill_changed.connect(set_skill)
    slot.cooldown_updated.connect(set_cooldown)
    set_skill(slot.skill_data)  # 立即刷新
    
    clicked.connect(slot.xxx)  # 这里要注意：UI 不应该调用 skill_slot 的方法

func set_cooldown(ratio:float,remaining:float)->void:
    cooldown_mask.value = ratio
    if remaining<=0.05:
        cooldown_label.text = ""
    else:
        cooldown_label.text = "%.1f"%remaining

# 技能数据是由别的场景持有的，ui只负责切换显示和通知信号
func set_skill(skill_data:SkillData)->void:
    if skill_data and skill_data.icon:
        icon_rect.texture = skill_data.icon
    else:
        set_empty()
    set_cooldown(0.0,0.0)

func set_empty()->void:
    icon_rect.texture=null

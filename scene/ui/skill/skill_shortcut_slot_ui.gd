extends Control
class_name SkillSlotUI

signal clicked()


@onready var icon_rect: TextureRect = $SkillIcon
@onready var cooldown_mask: ProgressBar = $CooldownMask
@onready var cooldown_label: Label = $CooldownLabel

func _gui_input(event: InputEvent) -> void:
    if(
        event is InputEventMouseButton and 
        event.pressed and 
        event.button_index==MOUSE_BUTTON_LEFT
    ):
        clicked.emit()
        accept_event()

func _set_empty()->void:
    icon_rect.texture = null
    icon_rect.visible = false
    _on_cooldown_updated(0,0)

# 技能数据是由别的场景持有的，ui只负责切换显示和通知信号
func set_skill(skill_id:StringName)->void:
    var skill_instance:SkillInstance = GameManager.get_player_skill_instance(skill_id)
    if skill_instance:
        skill_instance.cooldown_updated.connect(_on_cooldown_updated)
        var skill_data = skill_instance.data
        # 设置图标
        if skill_data:
            icon_rect.texture = skill_data.icon
            icon_rect.visible = true
        else:
            icon_rect.texture = null
            icon_rect.visible = false
        _on_cooldown_updated(
            skill_instance.get_cooldown_ratio(),
            skill_instance.get_remaining_cooldown()
        )
    else:
        _set_empty()

func _on_cooldown_updated(ratio:float,remaining:float)->void:
    cooldown_mask.value = ratio
    if remaining<=0.05:
        cooldown_label.text = ""
        cooldown_mask.value = 0
    else:
        cooldown_label.text = "%.1f" % remaining


extends Control
class_name SkillSlotUI

#region 信号
signal skill_slot_clicked()
#endregion

#region 成员变量
var _current_instance:SkillInstance = null
#endregion

#region @onready
@onready var icon_rect: TextureRect = $IconRect
@onready var cooldown_mask: ProgressBar = $CooldownMask
@onready var cooldown_label: Label = $CooldownLabel
#endregion
#region 内置函数
func _gui_input(event: InputEvent) -> void:
    if(
        event is InputEventMouseButton and 
        event.pressed and 
        event.button_index==MOUSE_BUTTON_LEFT
    ):
        skill_slot_clicked.emit()
        accept_event()
#endregion

#region 公共接口
func set_empty()->void:
    icon_rect.texture = null
    icon_rect.visible = false
    _on_cooldown_updated(0,0)

# 技能数据是由别的场景持有的，ui只负责切换显示和通知信号
func set_skill(skill_id:StringName)->void:
    # 先断开旧技能的信号连接
    if _current_instance:
        if _current_instance.cooldown_updated.is_connected(_on_cooldown_updated):
            _current_instance.cooldown_updated.disconnect(_on_cooldown_updated)
        _current_instance = null
    
    # 获取新的技能实例
    _current_instance = GameManager.get_player_skill_instance(skill_id)
    if _current_instance:
        _current_instance.cooldown_updated.connect(_on_cooldown_updated)
        var skill_data = _current_instance.data
        # 设置图标
        if skill_data:
            icon_rect.texture = skill_data.icon
            icon_rect.visible = true
        else:
            icon_rect.texture = null
            icon_rect.visible = false
        _on_cooldown_updated(
            _current_instance.get_cooldown_ratio(),
            _current_instance.get_remaining_cooldown()
        )
    else:
        set_empty()
#endregion

#region 信号处理
func _on_cooldown_updated(ratio:float,remaining:float)->void:
    cooldown_mask.value = ratio
    if remaining<=0.05:
        cooldown_label.text = ""
        cooldown_mask.value = 0
    else:
        cooldown_label.text = "%.1f" % remaining


#endregion

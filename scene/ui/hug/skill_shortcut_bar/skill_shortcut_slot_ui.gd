extends Control
class_name SkillSlotUI

#region 信号
signal skill_slot_clicked()
#endregion

#region 成员变量
var _current_instance:SkillInstance = null
#endregion

#region @onready
@onready var _icon_rect: TextureRect = $IconRect
@onready var _cooldown_mask: ProgressBar = $CooldownMask
@onready var _cooldown_label: Label = $CooldownLabel
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
    _icon_rect.texture = null
    _icon_rect.visible = false
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
            _icon_rect.texture = skill_data.icon
            _icon_rect.visible = true
        else:
            _icon_rect.texture = null
            _icon_rect.visible = false
        _on_cooldown_updated(
            _current_instance.get_cooldown_ratio(),
            _current_instance.get_remaining_cooldown()
        )
    else:
        set_empty()
#endregion

#region 信号处理
func _on_cooldown_updated(ratio:float,remaining:float)->void:
    _cooldown_mask.value = ratio
    if remaining<=0.05:
        _cooldown_label.text = ""
        _cooldown_mask.value = 0
    else:
        _cooldown_label.text = "%.1f" % remaining


#endregion

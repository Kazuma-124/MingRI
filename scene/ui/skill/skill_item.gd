extends PanelContainer
class_name SkillItem


#region 信号
signal clicked(skill_id:StringName)
#endregion


#region 成员变量
var skill_id:StringName = &""
#region @onready
@onready var icon: TextureRect = $HBoxContainer/Icon
@onready var name_label: Label = $HBoxContainer/NameLabel
@onready var info_label: Label = $HBoxContainer/InfoLabel
#endregion
#endregion


#region 内置函数
# 输入
func _gui_input(event: InputEvent) -> void:
    if(
        event is InputEventMouseButton and 
        event.pressed and  #InputEventMouseButton的属性
        event.button_index == MOUSE_BUTTON_LEFT
    ):
        clicked.emit()
        # 事件标记为已处理，传播停止
        accept_event()
#endregion

#region 公共接口
func setup(skill_data:SkillData,is_learned:bool)->void:
    skill_id = skill_data.id
    icon.texture = skill_data.icon
    name_label.text = skill_data.name
    # 信息行
    
#endregion

#region 成员变量

#endregion

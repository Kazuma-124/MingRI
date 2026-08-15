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
func _gui_input(event: InputEvent) -> void:
    if event is InputEventMouseButton and event.pressed and event.button_idx == 
#endregion

#region 成员变量

#endregion

#region 成员变量

#endregion

#region 成员变量

#endregion

#region 成员变量

#endregion

#region 成员变量

#endregion

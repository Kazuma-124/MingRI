extends Control

signal clicked()

@onready var icon_rect: TextureRect = $SkillIcon

func _gui_input(event: InputEvent) -> void:
    if(
        event is InputEventMouseButton and 
        event.pressed and 
        event.button_index==MOUSE_BUTTON_LEFT
    ):
        clicked.emit()
        accept_event()


# 技能数据是由别的场景持有的，ui只负责切换显示和通知信号
func set_skill(skill_data:SkillData)->void:
    if skill_data and skill_data.icon:
        icon_rect.texture = skill_data.icon
    else:
        set_empty()

func set_empty()->void:
    icon_rect.texture=null

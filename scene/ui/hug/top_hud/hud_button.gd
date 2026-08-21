extends Button
class_name HudButton

#region 信号
# signal clicked()
#endregion


#region @export
@export var action:StringName = &""
@export var label:String = ""
@export var shortcut_hint:String = ""
#endregion

#region 内置函数
func _ready() -> void:
    # 设置按钮文本
    text = label if shortcut_hint == "" else "%s(%s)" % [label, shortcut_hint]
    pressed.connect(_on_pressed)

#endregion

#region 信号处理
func _on_pressed() -> void:
    EventBus.hud_action_pressed.emit(action)
#endregion
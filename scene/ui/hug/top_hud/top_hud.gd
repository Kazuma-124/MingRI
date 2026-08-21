extends PanelContainer
class_name TopHud


#region @export
@export var button_scene:PackedScene
#endregion
@onready var _box: HBoxContainer = $HBoxContainer

func _ready() -> void:
    # 初始化按钮
    add_button(&"skill_book", "技能书", "K")

func add_button(action: StringName, label: String, hint: String = "") ->void:
    var btn = button_scene.instantiate()
    btn.action = action
    btn.label = label
    btn.shortcut_hint = hint
    btn.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN  # 关键: 不拉伸,按内容宽度
    _box.add_child(btn)

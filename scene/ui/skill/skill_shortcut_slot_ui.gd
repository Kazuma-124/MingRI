extends Control
class_name SkillSlotUI

signal clicked()

var my_skill_id:StringName = &""

@onready var icon_rect: TextureRect = $SkillIcon
@onready var cooldown_mask: ProgressBar = $CooldownMask
@onready var cooldown_label: Label = $CooldownLabel


func _ready() -> void:
    EventBus.skill_cooldown_updated.connect(_on_cooldown_updated)
    _set_cooldown_display(0,0)

func _gui_input(event: InputEvent) -> void:
    if(
        event is InputEventMouseButton and 
        event.pressed and 
        event.button_index==MOUSE_BUTTON_LEFT
    ):
        clicked.emit()
        accept_event()

func set_empty()->void:
    icon_rect.texture=null
    _set_cooldown_display(0,0)

# 技能数据是由别的场景持有的，ui只负责切换显示和通知信号
func set_skill(skill_data:SkillData)->void:
    if skill_data:
        my_skill_id = skill_data.id
        icon_rect.texture = skill_data.icon
        icon_rect.visible = true
        _refresh_cooldown()
    else:
        my_skill_id = &""
        icon_rect.visible = false
        _set_cooldown_display(0,0)
        set_empty()

# 从state拉取当前冷却(初始化用)
func _refresh_cooldown()->void:
    if my_skill_id == &"":
        return
    var state = GameManager.current_player.state
    var instance = state.get_skill_instance(my_skill_id)
    if instance:
        _set_cooldown_display(instance.get_cooldown_ratio(),instance.current_cooldown)

func _set_cooldown_display(ratio:float,remaining:float)->void:
    cooldown_mask.value = ratio
    if remaining<=0.05:
        cooldown_label.text = ""
        cooldown_mask.value = 0
    else:
        cooldown_label.text = "%.1f" % remaining


func _on_cooldown_updated(skill_id:StringName,ratio:float,remaining:float)->void:
    if skill_id == my_skill_id:
        _set_cooldown_display(ratio,remaining)

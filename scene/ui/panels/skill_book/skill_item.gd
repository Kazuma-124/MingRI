extends PanelContainer
class_name SkillItem


#region 信号
signal clicked(skill_id:StringName)
#endregion


#region 成员变量
var _skill_id:StringName = &""
var _skill_instance:SkillInstance = null
#endregion


#region @onready
@onready var _cooldown_mask: ProgressBar = %CooldownMask
@onready var _icon: TextureRect = %Icon
@onready var _name_label: Label = %NameLabel
@onready var _info_label: Label = %InfoLabel
@onready var _cooldown_label: Label = %CooldownLabel
@onready var _info_cooldown_container: Control = $HBoxContainer/InfoCooldownContainer
#endregion

#region 初始化
func _ready() -> void:
    _cooldown_mask.max_value = 1
#endregion

#region 输入
# 输入
func _gui_input(event: InputEvent) -> void:
    if(
        event is InputEventMouseButton and 
        event.pressed and  #InputEventMouseButton的属性
        event.button_index == MOUSE_BUTTON_LEFT
    ):
        clicked.emit(_skill_id)
        # 事件标记为已处理，传播停止
        accept_event()
#endregion

#region 信号处理
# 技能冷却时间变更信号最终在这里处理
func _on_cooldown_updated(ratio:float,remaining:float)->void:
    _cooldown_mask.value = ratio
    if remaining>0.05:
        _info_label.visible = false
        _cooldown_label.visible = true
        _cooldown_label.text = "%.1fs" % remaining
    else:
        _info_label.visible = true
        _cooldown_label.visible = false
        _cooldown_label.text = ""
#endregion


#region 公共接口
func setup(skill_id:StringName)->void:
    # 断开旧连接
    if _skill_instance:
        if _skill_instance.cooldown_updated.is_connected(_on_cooldown_updated):
            _skill_instance.cooldown_updated.disconnect(_on_cooldown_updated)
        _skill_instance = null
    _skill_id = skill_id
    var skill_data:SkillData = SkillLibrary.get_skill(skill_id)
    if skill_data:
        _icon.texture = skill_data.icon
        _name_label.text = skill_data.name

    # 动态信息：冷却信号
    _skill_instance = GameManager.get_player_skill_instance(_skill_id)
    if _skill_instance:
        # 已学习的技能展示信息
        # 静态信息
        var parts:Array[String] = []
        if skill_data.mp_cost>0:
            var attr_name = AttributeTypes.NAMES[skill_data.attribute_type]
            parts.append("消耗:%.0f(%s)" % [skill_data.mp_cost,attr_name])
        _info_label.text = " | ".join(parts)
        # 动态信息：冷却
        # 连接信号
        _skill_instance.cooldown_updated.connect(_on_cooldown_updated)
        # 预留最大宽度给冷却时间
        _cooldown_label.text = "%.1fs"%_skill_instance.get_max_cooldown()
        # 设定容器宽度下限
        _reserve_label_width()
        # 恢复为真实冷却时间
        _on_cooldown_updated(
            _skill_instance.get_cooldown_ratio(),
            _skill_instance.get_remaining_cooldown()
        )
    else:
        # 未学习的技能不展示冷却信息
        _info_label.text = "未学习"
        _cooldown_label.text = ""
        _reserve_label_width()

func _reserve_label_width()->void:
    await get_tree().process_frame
    var w = max(_info_label.get_minimum_size().x,_cooldown_label.get_minimum_size().x)
    _info_cooldown_container.custom_minimum_size.x=w
#endregion

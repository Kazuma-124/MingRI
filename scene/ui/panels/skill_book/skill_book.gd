extends Control
class_name SkillBook

#region @export
@export var _skill_item_scene:PackedScene
#endregion


#region _skill_items:Array[SkillItem] = []
var _skill_items:Array[SkillItem]
var _learnable_visible:bool = false
#endregion

#region @onready
@onready var _background: ColorRect = $Background
@onready var _close_button: Button = $Panel/MarginContainer/VBoxContainer/TitleBar/CloseButton
@onready var _learned_skill_items: VBoxContainer = $Panel/MarginContainer/VBoxContainer/HBoxContainer/LearnedSkills/LearnedSkillItems
@onready var _learnable_toggle: Button = $Panel/MarginContainer/VBoxContainer/HBoxContainer/LearnableToggle
@onready var _learnable_skill_items: VBoxContainer = $Panel/MarginContainer/VBoxContainer/HBoxContainer/LearnableSkills/LearnableSkillItems
#endregion


#region 内置函数
func _ready() -> void:
    _background.set_anchors_preset(Control.PRESET_FULL_RECT)
    _background.mouse_filter = Control.MOUSE_FILTER_STOP
    # 技能书默认隐藏
    visible = false
    _learnable_skill_items.visible = false

    _close_button.pressed.connect(_on_close_pressed)
    _learnable_toggle.pressed.connect(_on_learnable_toggle_pressed)

func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("toggle_skill"):
        toggle()
        # 标记当前事件已处理，阻止其继续传播
        get_viewport().set_input_as_handled()
#endregion

#region 公共接口
func toggle()->void:
    visible = !visible
    if visible:
        _populate_list()
    else:
        _clear_list()
#endregion


#region 内部方法
func _populate_list()->void:
    _clear_list()
    var player_state:PlayerSaveableState = GameManager.current_player.state
    
    # var learned_count = 0
    var learnable_count = 0
    for skill_id in SkillLibrary.get_all_skill_ids():
        # skill_data用于获取技能等级判断是否可学习
        var skill_data = SkillLibrary.get_skill(skill_id)
        if not skill_data:
            continue
        
        if skill_id in player_state.learned_skill_ids:
            _create_item(skill_id,true)
            # learned_count += 1
        elif player_state.base_level>=skill_data.unlock_level:
            _create_item(skill_id,false)
            learnable_count+=1
    
    _learnable_toggle.text = "可学技能 %s" % [">>>" if _learnable_visible else "<<<"]
    _learnable_toggle.visible = learnable_count>0

func _create_item(skill_id:StringName,is_learned:bool)->void:
    var item = _skill_item_scene.instantiate() as SkillItem
    # 先添加进场景，后面才能修改一些onready数据
    if is_learned:
        _learned_skill_items.add_child(item)
    else:
        _learnable_skill_items.add_child(item)
    item.setup(skill_id)
    item.clicked.connect(_on_skill_item_clicked)

func _clear_list()->void:
    for item in _skill_items:
        item.queue_free()
    _skill_items.clear()

#endregion


#region 信号处理
func _on_skill_item_clicked(skill_id:StringName)->void:
    EventBus.skill_book_skill_clicked.emit(skill_id)

func _on_close_pressed()->void:
    visible = false
    _clear_list()

func _on_learnable_toggle_pressed()->void:
    _learnable_visible = !_learnable_visible
    _learnable_skill_items.visible = _learnable_visible
    if not _learnable_visible:
        pass
    _learnable_toggle.text = "可学技能 %s" % [">>>" if _learnable_visible else "<<<"]
#endregion

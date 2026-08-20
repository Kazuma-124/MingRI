extends Control
class_name SkillBook

#region @export
#endregion


#region _skill_items:Array[SkillItem] = []
# var _skill_items:Array[SkillItem]
var _learnable_visible:bool = false
#endregion

#region @onready
@onready var _draggable: Draggable = $Panel/Body/TitleBar
@onready var _close_button: Button = %CloseButton
@onready var _learned_items: SkillItemList = %LearnedItems
@onready var _learnable_toggle_button: Button = %LearnableToggleButton
@onready var _learnable_items: SkillItemList = %LearnableItems
#endregion


#region 内置函数
func _ready() -> void:
    # 技能书默认隐藏
    visible = false
    _learnable_items.visible = false
    _update_content_min()

    _close_button.pressed.connect(_on_close_pressed)
    _learnable_toggle_button.pressed.connect(_on_learnable_toggle_pressed)

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
        _learned_items.clear_skills()
        _learnable_items.clear_skills()
#endregion


#region 内部方法
func _populate_list()->void:
    _learned_items.clear_skills()
    _learnable_items.clear_skills()
    var player_state:PlayerSaveableState = GameManager.current_player.state
    
    # var learned_count = 0
    var learnable_count = 0
    for skill_id in SkillLibrary.get_all_skill_ids():
        # skill_data用于获取技能等级判断是否可学习
        var skill_data = SkillLibrary.get_skill(skill_id)
        if not skill_data:
            continue
        
        if skill_id in player_state.learned_skill_ids:
            _learned_items.add_skill(skill_id)
        elif player_state.base_level>=skill_data.unlock_level:
            _learnable_items.add_skill(skill_id)
            learnable_count+=1
    
    print_debug("learnable_count: ",learnable_count)
    _learnable_toggle_button.text = "可\n学\n技\n能\n %s" % [">>>" if _learnable_visible else "<<<"]
    _learnable_toggle_button.visible = learnable_count>0

    # 更新拖动的size最小值
    _update_content_min()

func _update_content_min()->void:
    await get_tree().process_frame
    _draggable.set_content_min($Panel.get_combined_minimum_size())
#endregion


#region 信号处理
func _on_skill_item_clicked(skill_id:StringName)->void:
    EventBus.skill_book_skill_clicked.emit(skill_id)

func _on_close_pressed()->void:
    visible = false
    _learned_items.clear_skills()
    _learnable_items.clear_skills()

func _on_learnable_toggle_pressed()->void:
    _learnable_visible = !_learnable_visible
    _learnable_items.visible = _learnable_visible
    if not _learnable_visible:
        pass
    _learnable_toggle_button.text = "可\n学\n技\n能\n %s" % [">>>" if _learnable_visible else "<<<"]
    # 点击拓展后，容器最小大小更新
    _update_content_min()
#endregion


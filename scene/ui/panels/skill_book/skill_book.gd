extends Control
class_name SkillBook

#region @export
#endregion


#region 成员变量
# var _skill_items:Array[SkillItem]
var _learnable_visible:bool = false
#endregion

#region @onready
@onready var _draggable: Draggable = $Panel/Body/TitleBar       # 标题栏上的拖拽/缩放组件(负责窗口移动与四角缩放)
@onready var _close_button: Button = %CloseButton
@onready var _learned_items: SkillItemList = %LearnedItems
@onready var _learnable_toggle_button: Button = %LearnableToggleButton
@onready var _learnable_items: SkillItemList = %LearnableItems
#endregion


#region 内置函数
func _ready() -> void:
    visible = false                     # 技能书默认隐藏
    _learnable_items.visible = false
    _update_content_min(false)               # 初始化时把内容最小尺寸同步给拖拽下限

    _close_button.pressed.connect(_on_close_pressed)
    _learnable_toggle_button.pressed.connect(_on_learnable_toggle_pressed)
    _learned_items.item_clicked.connect(_on_skill_item_clicked)
    # 可学习的技能无法释放
    # _learnable_items.item_clicked.connect(_on_skill_item_clicked)


func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("toggle_skill"):
        toggle()
        get_viewport().set_input_as_handled()   # 标记当前事件已处理，阻止其继续传播
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
# 生成技能书列表
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
    _learnable_toggle_button.text = _generate_learnable_toggle_button_text()
    _learnable_toggle_button.visible = learnable_count>0

    # 列表项数量变化 → 内容最小尺寸变化,同步拖拽下限
    _update_content_min(false)

# 把“内容当前所需的最小尺寸”同步给拖拽组件。
# 关键:Godot 的布局/最小尺寸计算不是同步的——修改子节点可见性或内容后只是排队重排,
# 要等下一帧 process_frame 布局刷新完,祖先的 get_combined_minimum_size() 才是新值。
# 所以先 await 一帧,再读最新值传给 draggable,避免传入“上一帧的旧数据”导致窗口尺寸对不上内容。
func _update_content_min(is_keep_margin:bool)->void:
    await get_tree().process_frame
    if is_keep_margin:
        _draggable.set_content_min_keep_margin($Panel.get_combined_minimum_size())
    else:
        _draggable.set_content_min($Panel.get_combined_minimum_size())

func _generate_learnable_toggle_button_text()->String:
    return "可\n学\n技\n能\n%s" % [">>" if _learnable_visible else "<<"]
    # return "可学技能%s" % [">>" if _learnable_visible else "<<"]
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
    _learnable_items.visible = _learnable_visible   # 展开/收起改变内容尺寸
    _learnable_toggle_button.text = _generate_learnable_toggle_button_text()
    _update_content_min(true) # 内容尺寸变化 → 同步拖拽下限与窗口大小
#endregion


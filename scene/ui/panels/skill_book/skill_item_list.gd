extends ScrollContainer
class_name SkillItemList

#region 信号
signal item_clicked(skill_id:StringName)
signal item_quick_cast(skill_id:StringName)
#endregion

#region 变量
@export var skill_item_scene:PackedScene
var _items:Array[SkillItem] = []
@onready var items_list: VBoxContainer = $ItemsList
#endregion


#region 接口函数
func add_skill(skill_id:StringName)->void:
    var item = skill_item_scene.instantiate() as SkillItem
    if item:
        items_list.add_child(item)
        _items.append(item)
        item.setup(skill_id)
        item.clicked.connect(_on_item_clicked)
        item.quick_cast.connect(_on_item_quick_cast)
    else:
        push_error("创建skill_item示例失败")
func clear_skills()->void:
    for it in _items:
        it.queue_free()
    _items.clear()
#endregion

#region 信号接口
# 把skill_item信号到自己这里，自己再转到根节点，根节点和eventbus沟通
func _on_item_clicked(skill_id:StringName)->void:
    item_clicked.emit(skill_id)
func _on_item_quick_cast(skill_id:StringName)->void:
    item_quick_cast.emit(skill_id)
#endregion

extends RefCounted
class_name AttributeSystem

# 中间属性系统：管理角色所有可悲角色自身和buff直接修改的中间属性
# 值的类型支持：float和Vector2
# 对值的修改操作支持：
#   SET_BASE
#   FLAT_ADD / PERCENT_ADD / MULTIPLY
#   OVERRIDE

#region 信号
signal stat_changed(stat_name:StringName,old_value:Variant,new_value:Variant)
signal override_winner_changed(stat_name:StringName, old_buff_id:StringName, new_buff_id:StringName)
#endregion

#region 成员变量
var _owner:Node = null
var _attributes:Dictionary = {} # 属性名->Attribute
var _active_tags:Dictionary = {} # tag->int
#endregion


#region 构造
func _init(p_owner:Node = null)->void:
    _owner = p_owner
#endregion

#region 外部接口
func register_stat(stat_name:StringName,base_value:Variant=null)->void:
    if _attributes.has(stat_name):
        push_error("AttributeSystem: 属性 %s 重复注册" % stat_name)
        return
    # 创建attribute
    var base:Variant = base_value if base_value!=null else StatusStats.DEFAULTS.get(stat_name,0.0)
    var attr:=Attribute.new(stat_name,base)
    attr.value_changed.connect(func(old:Variant,new:Variant):stat_changed.emit(stat_name,old,new))
    attr.override_winner_changed.connect(func(o,n):override_winner_changed.emit(stat_name,o,n))
    # 加到属性名映射
    _attributes[stat_name] = attr
func register_all_defaults()->void:
    for stat_name in StatusStats.DEFAULTS:
        register_stat(stat_name)

func set_base_value(stat_name:StringName,value:Variant)->void:
    var attr:=_get_attribute(stat_name)
    if attr!=null:
        attr.set_base_value(value)
# func get_base_value(stat_name:StringName)->Variant:
    # var attr:=_get_attribute(stat_name)
    # if attr!=null:
    #     return attr.get_base_value()
    # return 0.0

func add_modifier(modifier:BuffModifier)->void:
    var attr:=_get_attribute(modifier.stat_name)
    if attr!=null:
        attr.add_modifier(modifier)
func has_modifier(stat_name:StringName)->bool:
    var attr:=_get_attribute(stat_name)
    if attr!=null:
        return attr.has_modifier()
    return false

func remove_modifiers_from_buff(buff_id:StringName)->void:
    for attr in _attributes.values():
        attr.remove_modifiers_from_buff(buff_id)
func remove_modifiers_from_buff_effect(buff_id:StringName,effect_id:StringName)->void:
    for attr in _attributes.values():
        attr.remove_modifiers_from_buff_effect(buff_id,effect_id)
func clear_all_modifiers()->void:
    for attr in _attributes.values():
        attr.clear_modifiers()


func get_final_value(stat_name:StringName)->Variant:
    var attr:=_get_attribute(stat_name)
    if attr!=null:
        return attr.get_final_value()
    return 0.0

func add_tag(tag:StringName)->void:
    _active_tags[tag]=_active_tags.get(tag,0)+1

func remove_tag(tag:StringName)->void:
    if _active_tags.has(tag):
        _active_tags[tag]-=1
        if _active_tags[tag]<=0:
            _active_tags.erase(tag)
func has_tag(tag:StringName)->bool:
    return _active_tags.has(tag)
func has_any_tag(tags:Array)->bool:
    for tag in tags:
        if _active_tags.has(tag):
            return true
    return false

func get_all_stats()->Dictionary:
    var result:={}
    for stat_name in _attributes.keys():
        result[stat_name] = _attributes[stat_name].get_final_value()
    return result
#endregion

#region 内部函数
func _get_attribute(stat_name:StringName)->Attribute:
    if not _attributes.has(stat_name):
        push_error("AttributeSystem: 未注册的属性 %s" % stat_name)
        return null
    return _attributes[stat_name]
#endregion
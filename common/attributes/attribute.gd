extends RefCounted
class_name Attribute


# 单个中间属性：自持基础值、modifier、计算结果缓存
# 叠加层（FLAT_ADD/PERCENT_ADD/MULTIPLY）按 buff_id 分组，全部参与公式
# 覆盖层（OVERRIDE）按 buff_id 唯一存储，只取 priority 最高者
# 值类型由基础值推断（float 或 Vector2）
# 计算链：(base + ΣFLAT_ADD) × (1 + ΣPERCENT_ADD) × Π(MULTIPLY)，OVERRIDE 直接替换

#region 信号
signal value_changed(old_value:Variant,new_value:Variant)
signal override_winner_changed(old_buff_id:StringName, new_buff_id:StringName)
#endregion

#region 成员变量
var stat_name:StringName
var _base_value:Variant
var _modifiers:Dictionary = {} # buff_id->Array[BuffModifier]
var _overrides:Dictionary = {} # buff_id->BuffModifier（覆盖修改器一个buff最多1个）
var _last_override_winner:StringName = &""
var _cached_value:Variant
var _dirty:bool = false
#endregion

#region 构造
func _init(p_name:StringName,p_base_value:Variant)->void:
    stat_name=p_name
    _base_value = p_base_value
    _cached_value = p_base_value
#endregion

#region 外部接口
func set_base_value(value:Variant)->void:
    _base_value = value
    _mark_dirty()

func get_base_value()->Variant:
    return _base_value

func add_modifier(modifier:BuffModifier)->void:
    if modifier.layer==BuffEnums.CalcLayer.OVERRIDE:
        _overrides[modifier.source_buff] = modifier
    else:
        if not _modifiers.has(modifier.source_buff):
            _modifiers[modifier.source_buff] = []
        _modifiers[modifier.source_buff].append(modifier)
    _refresh_override_winner()# get_final_value也会更新但不够及时，这里主动更新
    _mark_dirty()
func has_modifier()->bool:
    return not (_modifiers.is_empty() and _overrides.is_empty())

func remove_modifiers_from_buff(buff_id:StringName)->void:
    var removed:bool = _modifiers.erase(buff_id)
    removed = _overrides.erase(buff_id) or removed
    if removed:
        _mark_dirty()

func remove_modifiers_from_buff_effect(buff_id:StringName,effect_id:StringName)->void:
    var removed:bool = false
    if _modifiers.has(buff_id):
        var mods:Array = _modifiers[buff_id]
        for i in range(mods.size()-1,-1,-1):
            if mods[i].source_effect == effect_id:
                mods.remove_at(i)
                removed = true
        if mods.is_empty():
            _modifiers.erase(buff_id)
    if _overrides.has(buff_id) and _overrides[buff_id].source_effect==effect_id:
        _overrides.erase(buff_id)
        removed = true
    if removed:
        _mark_dirty()

func clear_modifiers()->void:
    _modifiers.clear()
    _overrides.clear()
    _mark_dirty()


func get_final_value()->Variant:
    if _dirty:
        _recalculate()
    return _cached_value

func get_overriding_buff_id()->StringName:
    var best:=_get_best_override()
    return best.source_buff if best!=null else &""
#endregion

#region 内部函数
func _recalculate()->void:
    var is_vector:bool = _base_value is Vector2
    var new_value:Variant
    # 假如有覆盖就覆盖
    var best_override:BuffModifier = _get_best_override()
    if best_override!=null:
        new_value = best_override.value
    else:
        var flat_sum:Variant = Vector2.ZERO if is_vector else 0.0
        var percent_sum:float = 0.0
        var multiply_product:float = 1.0
        for mods in _modifiers.values():
            for mod in mods:
                match mod.layer:
                    BuffEnums.CalcLayer.FLAT_ADD:
                        flat_sum+=mod.value
                    BuffEnums.CalcLayer.PERCENT_ADD:
                        percent_sum+=mod.value
                    BuffEnums.CalcLayer.MULTIPLY:
                        multiply_product*=mod.value
        new_value = (_base_value+flat_sum)*(1.0+percent_sum)*multiply_product
    
    var old_value:Variant=_cached_value
    # 更新
    _cached_value = new_value
    _dirty = false
    # 检查是否发送实际变化，根据情况发送信号
    var changed:bool
    if is_vector:
        changed = (new_value-old_value).length()>0.001
    else:
        changed = abs(new_value-old_value)>0.001
    if changed:
        value_changed.emit(old_value,new_value)
    
func _get_best_override()->BuffModifier:
    var best:BuffModifier = null
    for mod in _overrides.values():
        if best==null or mod.priority>best.priority:
            best = mod
    return best

func _mark_dirty()->void:
    _dirty = true

func _refresh_override_winner()->void:
    var new_winner:=get_overriding_buff_id()
    if new_winner==_last_override_winner:
        return
    var old:=_last_override_winner
    _last_override_winner = new_winner
    override_winner_changed.emit(old,new_winner)
#endregion
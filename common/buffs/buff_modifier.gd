extends RefCounted
class_name BuffModifier

#region 成员变量
var source_buff: StringName              # 产生此修改器的 buff_id
var source_effect: StringName = &""      # 产生此修改器的 effect_id（精确移除外）
var stat_name: StringName                # 目标属性名
var layer: BuffEnums.CalcLayer           # 计算层级
var value: float                         # 数值
#endregion

#region 构造
func _init(p_source: StringName, p_stat: StringName, p_layer: BuffEnums.CalcLayer, p_value: float, p_effect: StringName = &"") -> void:
	source_buff = p_source
	source_effect = p_effect
	stat_name = p_stat
	layer = p_layer
	value = p_value
#endregion

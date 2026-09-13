extends RefCounted
class_name BuffModifier

# 持续修正载：一个 effect 对一个中间属性的一次持续修改（可撤销）
var source_buff: StringName
var source_effect: StringName = &""
var stat_name: StringName
var layer: BuffEnums.CalcLayer
var value: Variant
var priority: int = 0   # OVERRIDE 排序，大者优先

func _init(p_source: StringName, p_effect: StringName,
		p_stat: StringName, p_layer: BuffEnums.CalcLayer,
		p_value: Variant, p_priority: int = 0) -> void:
	source_buff = p_source
	source_effect = p_effect
	stat_name = p_stat
	layer = p_layer
	value = p_value
	priority = p_priority
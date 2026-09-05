extends BuffEffectDefinition
class_name EffectModifyStat

#region 配置
var stat_name: StringName = &""
var calc_layer: BuffEnums.CalcLayer = BuffEnums.CalcLayer.FLAT_ADD
var value: float = 0.0
var per_stack: bool = false
#endregion

#region 生命周期
func apply(instance: BuffInstance, manager: BuffManager) -> void:
	if stat_name.is_empty():
		push_error("EffectModifyStat.apply: stat_name 为空")
		return
	var final_value: float = value
	if per_stack:
		final_value *= instance.stacks
	var modifier := BuffModifier.new(instance.definition.buff_id, stat_name, calc_layer, final_value, effect_id)
	manager.add_modifier(modifier)

func remove(instance: BuffInstance, manager: BuffManager) -> void:
	manager.remove_modifiers_from_effect(instance.definition.buff_id, effect_id)
#endregion

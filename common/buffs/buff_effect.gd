extends RefCounted
class_name BuffEffectDefinition

# Effect 原子基类：具体 Effect 子类化，在 _init 或字段赋值中设置参数
# 不再是 Resource，由 BuffDefinition 子类在 _init 中动态 new

#region 配置
var effect_id: StringName = &""
var apply_phase: BuffEnums.ApplyPhase = BuffEnums.ApplyPhase.ON_APPLY
#endregion

#region 生命周期（子类重写）
func apply(_instance: BuffInstance, _manager: BuffManager) -> void:
	pass

func remove(_instance: BuffInstance, _manager: BuffManager) -> void:
	pass

func on_stack_changed(instance: BuffInstance, manager: BuffManager) -> void:
	remove(instance, manager)
	apply(instance, manager)
#endregion

extends RefCounted
class_name BuffEffectDefinition

# Effect 原子基类：具体 Effect 子类化，在 _init 或字段赋值中设置参数
# 由 BuffDefinition 子类在 _init 中动态 new

#region 配置
var effect_id: StringName = &""
# BuffManager的update时，根据时间调用buff_definition的on_tick(),
# 	进而调ON_TICK的effect
# 生效的时机，也就是apply调用的时机
# 可被修改进而创建不同生效时机版本的effect, 或者动态修改effect生效时机
var apply_phase: BuffEnums.ApplyPhase = BuffEnums.ApplyPhase.ON_APPLY
#endregion

#region 生命周期
# 调用使得本effect生效一次, 定义生效的效果逻辑
func apply(_instance: BuffInstance, _manager: BuffManager) -> void:
	pass

func remove(_instance: BuffInstance, _manager: BuffManager) -> void:
	pass

func on_stack_changed(instance: BuffInstance, manager: BuffManager) -> void:
	remove(instance, manager)
	apply(instance, manager)
#endregion

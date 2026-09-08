extends RefCounted
class_name BuffDefinition

# Buff 逻辑模板基类：具体 buff 逻辑通过子类化实现，在 _init 中设置数值和 Effect 组合
# 不再是 Resource，由技能在运行时 new 并传入数值，创建"数值版本"的 buff
# 所有生命周期回调为无状态函数，操作传入的 instance

#region 常量
const DURATION_PERMANENT: float = -1.0
#endregion

#region 逻辑配置（子类 _init 中设置）
var buff_id: StringName = &""
var display_name: String = ""
var effects: Array[BuffEffectDefinition] = []
var stack_policy_under: BuffEnums.StackPolicy = BuffEnums.StackPolicy.REFRESH_TIME
var stack_policy_full: BuffEnums.StackPolicy = BuffEnums.StackPolicy.REFRESH_TIME
var suppression_policy: BuffEnums.SuppressionPolicy = BuffEnums.SuppressionPolicy.NORMAL_TICK
var overridden_attributes: Array[StringName] = []
var priority: int = 0
#endregion

#region 数值配置（子类 _init 中设置，技能也可直接修改）
var base_duration: float = 5.0
var max_stacks: int = 1
var tick_interval: float = 0.0
#endregion

#region 生命周期回调（无状态，子类可覆写；默认实现遍历 effects 分发）
func on_add(_instance: BuffInstance, _manager: BuffManager) -> void:
	pass

func on_apply(instance: BuffInstance, manager: BuffManager) -> void:
	for effect in effects:
		if effect.apply_phase == BuffEnums.ApplyPhase.ON_APPLY:
			effect.apply(instance, manager)

func on_tick(instance: BuffInstance, manager: BuffManager) -> void:
	for effect in effects:
		if effect.apply_phase == BuffEnums.ApplyPhase.ON_TICK:
			effect.apply(instance, manager)

func on_refresh(_instance: BuffInstance, _manager: BuffManager) -> void:
	pass

func on_stack_added(instance: BuffInstance, manager: BuffManager) -> void:
	for effect in effects:
		if effect.apply_phase == BuffEnums.ApplyPhase.ON_STACK_CHANGED:
			effect.on_stack_changed(instance, manager)

func on_remove(instance: BuffInstance, manager: BuffManager) -> void:
	# 移除效果
	for effect in effects:
		effect.remove(instance, manager)

# buff被移除
func on_expire(instance: BuffInstance, manager: BuffManager) -> void:
	on_remove(instance, manager)

func on_suppressed(_instance: BuffInstance, _manager: BuffManager) -> void:
	pass

func on_restored(_instance: BuffInstance, _manager: BuffManager) -> void:
	pass
#endregion

#region 叠加策略处理（由 BuffManager 调用）
func apply_stack_policy_under(existing: BuffInstance, new_caster: Node, new_dynamic_values: Dictionary, manager: BuffManager) -> void:
	match stack_policy_under:
		BuffEnums.StackPolicy.REFRESH_TIME:
			existing.remaining_time = base_duration
			on_refresh(existing, manager)
		BuffEnums.StackPolicy.ADD_STACK:
			existing.stacks += 1
			on_stack_added(existing, manager)
		BuffEnums.StackPolicy.ADD_STACK_AND_REFRESH:
			existing.stacks += 1
			existing.remaining_time = base_duration
			on_stack_added(existing, manager)
			on_refresh(existing, manager)
		BuffEnums.StackPolicy.IGNORE:
			return
		BuffEnums.StackPolicy.OVERRIDE:
			existing.dynamic_values = new_dynamic_values
			existing.caster = new_caster
			existing.remaining_time = base_duration
			on_refresh(existing, manager)
		BuffEnums.StackPolicy.CUSTOM:
			on_custom_stack_under(existing, new_caster, new_dynamic_values, manager)

func apply_stack_policy_full(existing: BuffInstance, new_caster: Node, new_dynamic_values: Dictionary, manager: BuffManager) -> void:
	match stack_policy_full:
		BuffEnums.StackPolicy.REFRESH_TIME:
			existing.remaining_time = base_duration
			on_refresh(existing, manager)
		BuffEnums.StackPolicy.ADD_STACK:
			return
		BuffEnums.StackPolicy.ADD_STACK_AND_REFRESH:
			existing.remaining_time = base_duration
			on_refresh(existing, manager)
		BuffEnums.StackPolicy.IGNORE:
			return
		BuffEnums.StackPolicy.OVERRIDE:
			existing.dynamic_values = new_dynamic_values
			existing.caster = new_caster
			existing.remaining_time = base_duration
			on_refresh(existing, manager)
		BuffEnums.StackPolicy.CUSTOM:
			on_custom_stack_full(existing, new_caster, new_dynamic_values, manager)
#endregion

#region 自定义叠加回调（CUSTOM 策略时子类覆写）
func on_custom_stack_under(_existing: BuffInstance, _new_caster: Node, _new_values: Dictionary, _manager: BuffManager) -> void:
	pass

func on_custom_stack_full(_existing: BuffInstance, _new_caster: Node, _new_values: Dictionary, _manager: BuffManager) -> void:
	pass
#endregion

#region 查询工具
func is_permanent() -> bool:
	return base_duration == DURATION_PERMANENT
#endregion

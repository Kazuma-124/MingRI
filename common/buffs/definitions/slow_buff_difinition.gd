extends BuffDefinition
class_name SlowBuffDefinition

# 减速 buff 逻辑模板：速度乘数 PERCENT_ADD 负修正
# 数值由技能在 new 时指定：减速百分比、持续时间、最大层数
# 叠加策略：未满时加层并刷新，已满时刷新时间

#region 构造
func _init(p_slow_percent: float = 0.2, p_duration: float = 1.0, p_max_stacks: int = 3) -> void:
	buff_id = &"slow"
	display_name = "减速"
	base_duration = p_duration
	max_stacks = p_max_stacks
	tick_interval = 0.0
	stack_policy_under = BuffEnums.StackPolicy.ADD_STACK_AND_REFRESH
	stack_policy_full = BuffEnums.StackPolicy.REFRESH_TIME
	priority = 10

	var mod := EffectModifyStat.new()
	mod.effect_id = &"slow_speed_mod"
	mod.stat_name = StatusStats.SPEED_MULTIPLIER
	mod.calc_layer = BuffEnums.CalcLayer.PERCENT_ADD
	mod.value = -p_slow_percent
	mod.per_stack = true
	effects.append(mod)
#endregion


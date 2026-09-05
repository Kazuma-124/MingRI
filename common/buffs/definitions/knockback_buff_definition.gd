extends BuffDefinition
class_name KnockbackBuffDefinition

# 击退 buff 逻辑模板：设置 forced_velocity + STAGGERED 标签
# 数值由技能在 new 时指定：击退速度、持续时间
# 击退距离 = speed × duration（如 speed=200, duration=0.4 → 距离80）
# 叠加策略：OVERRIDE（新击退覆盖旧击退）

#region 构造
func _init(p_speed: float = 200.0, p_duration: float = 0.4) -> void:
	buff_id = &"knockback"
	display_name = "击退"
	base_duration = p_duration
	max_stacks = 1
	stack_policy_under = BuffEnums.StackPolicy.OVERRIDE
	stack_policy_full = BuffEnums.StackPolicy.OVERRIDE
	priority = 100
	overridden_attributes = [&"movement"]

	var kb := EffectKnockback.new()
	kb.effect_id = &"knockback_effect"
	kb.speed = p_speed
	effects.append(kb)
#endregion


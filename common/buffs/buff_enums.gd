extends RefCounted
class_name BuffEnums

#region 叠加策略：相同 buff 再次施加时的行为
# BuffDefinition用于定义buff自己的叠加策略
enum StackPolicy {
	REFRESH_TIME,           # 刷新剩余时间为基础持续时间
	ADD_STACK,              # 层数 +1（仅未满时有效）
	ADD_STACK_AND_REFRESH,  # 加层并刷新时间
	IGNORE,                 # 忽略新施加
	OVERRIDE,               # 用新数值覆盖旧实例
	CUSTOM,                 # 调用 definition 的自定义回调
}
#endregion

#region 抑制策略：高优先级 buff 接管属性时，如何处理其它低优先级 buff 的通用数据
# BuffDefinition用于定义buff自己的抑制策略
enum SuppressionPolicy {
	NORMAL_TICK,     # 正常计时、正常 tick（tick效果被抑制）
	PAUSE_DURATION,  # 暂停持续时间计时
	PAUSE_TICK,      # 暂停 tick，持续时间继续走
	RESET_STACKS,    # 重置层数为 0
}
#endregion

#region 属性计算层
# BuffModifier用于定义自己所处的计算层级
# EffectModifyStat定义自己的计算层级
enum CalcLayer {
	FLAT_ADD,     # 基础数值加法：基础值 + Σflat
	PERCENT_ADD,  # 百分比加法：(基础+flat) × (1 + Σpercent)
	MULTIPLY,     # 独立乘区：× Π(1 + multiply)
}
#endregion

#region Effect 应用阶段
#BuffEffectDefinition用于定义自身effect的生效时机
enum ApplyPhase {
	ON_APPLY,         # 生效时（首次添加 + 抑制恢复后重新生效）
	ON_TICK,          # 每个 tick 间隔
	ON_REMOVE,        # 移除时
	ON_STACK_CHANGED, # 层数变化时
}
#endregion

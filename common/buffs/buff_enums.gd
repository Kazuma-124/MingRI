extends RefCounted
class_name BuffEnums


#region 属性计算层
# BuffModifier用于定义自己所处的计算层级
# EffectModifyStat定义自己的计算层级
enum CalcLayer {
	FLAT_ADD,     # 基础数值加法：基础值 + Σflat
	PERCENT_ADD,  # 百分比加法：(基础+flat) × (1 + Σpercent)
	MULTIPLY,     # 独立乘区：× Π(multiply)
	OVERRIDE,
}
#endregion

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

#region Effect 生效时机
enum TriggerFlag{
    ON_APPLY = 0b0001,   # buff施加时
    ON_TICK = 0b0010,    # buff的tick更新时
    ON_STACK_CHANGED = 0b0100,   # buff层数变化时
    ON_REMOVE = 0b1000   # buff被移除时
}
#endregion

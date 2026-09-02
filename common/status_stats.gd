extends RefCounted
class_name StatusStats

# 状态管理器可修饰的标量属性键
# 使用 StringName 动态键：新增属性只需在此登记常量，管理器无需改动

#region 常量
const SPEED_MULTIPLIER:StringName = &"speed_multiplier"	# 自主速度乘数，缺省 1.0，减速<1/加速>1
# 未来扩展示例：
# const ATTACK:StringName := &"attack"
# const DEFENSE:StringName := &"defense"
#endregion

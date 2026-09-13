extends RefCounted
class_name StatusStats

# 中间属性名常量：register_stat 注册、effect 的 stat_name 都用它

const DEFAULTS := {
	MOVE_SPEED: 0.0,
	MOVE_DIRECTION: Vector2.ZERO,
	EXTERNAL_VELOCITY: Vector2.ZERO,
	FORCED_VELOCITY: Vector2.ZERO,
	# DAMAGE_TAKEN_MULTIPLIER: 1.0,
	# HEAL_MULTIPLIER: 1.0,
	# DEFENSE: 0.0,
}

#region 移动相关
# 强制速度
const FORCED_VELOCITY: StringName = &"forced_velocity"    # 向量：硬直强制位移
# 自主速度
const MOVE_DIRECTION: StringName = &"move_direction"   # 向量：自主移动单位方向
const MOVE_SPEED: StringName = &"move_speed"           # 标量：对象自主移动速率
# 外力速度
const EXTERNAL_VELOCITY: StringName = &"external_velocity" # 向量：非硬直环境外力
#endregion

#region 其它标量中间属性
# const DAMAGE_MULTIPLIER: StringName = &"damage_multiplier"              # 造成伤害倍率
# const DAMAGE_TAKEN_MULTIPLIER: StringName = &"damage_taken_multiplier"  # 受伤倍率
# const HEAL_MULTIPLIER: StringName = &"heal_multiplier"                  # 治疗倍率
# const DEFENSE: StringName = &"defense"
# const ATTACK_SPEED: StringName = &"attack_speed"
#endregion
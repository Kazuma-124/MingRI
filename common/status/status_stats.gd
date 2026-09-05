extends RefCounted
class_name StatusStats

# 属性名常量集合（复数命名）
# BuffStatComponent 注册属性时使用这些常量作为 key，EffectModifyStat 的 stat_name 也用这些常量

const SPEED_MULTIPLIER: StringName = &"speed_multiplier"    # 移动速度乘数（基础值1.0）
const DAMAGE_MULTIPLIER: StringName = &"damage_multiplier"  # 伤害乘数（基础值1.0）
const DEFENSE: StringName = &"defense"                      # 防御（基础值0）
const ATTACK_SPEED: StringName = &"attack_speed"            # 攻击速度乘数（基础值1.0）

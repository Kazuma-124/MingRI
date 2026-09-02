extends RefCounted
class_name StatusTags

# 控制标签：表达角色「能不能做某事」的离散状态
# 与数值正交：标签管"能不能"，标量槽管"是多少"，不再用数值向量伪装控制状态
# 效果每帧贡献标签，帧首随槽位统一清空（存活才持有，到期自动解除）

#region 常量
const STAGGERED:StringName = &"staggered"	# 硬直：冻结自主状态机，最终速度取强制位移（击退/眩晕）
const ROOTED:StringName = &"rooted"			# 定身：冻结自主移动、速度清零（仍可攻击/施法）
# 未来扩展示例：
# const STUNNED:StringName := &"stunned"	# 眩晕：硬直且禁技能
# const SILENCED:StringName := &"silenced"	# 沉默：禁技能
# const INVINCIBLE:StringName := &"invincible"
#endregion

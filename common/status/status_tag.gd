extends RefCounted
class_name StatusTags

# 状态标签常量集合（复数命名，遵循项目命名规范）
# 控制类 Effect 通过 BuffManager 注册/移除标签，character_base 查询标签决定行为
# 多个 buff 可叠加同一标签（引用计数），全部移除后标签才消失

const STAGGERED: StringName = &"staggered"      # 硬直：自主被接管，velocity=forced_velocity
const ROOTED: StringName = &"rooted"            # 定身：无法自主移动，velocity=ZERO
const SILENCED: StringName = &"silenced"        # 沉默：无法施法
const FROZEN: StringName = &"frozen"            # 冰冻：完全无法行动
const INVINCIBLE: StringName = &"invincible"    # 无敌：不受伤害

# skill_base.gd
extends Node2D
class_name SkillBase

# 技能配置数据
var data: SkillData
# 释放者（谁放的技能）
var caster: CharacterBody2D
# 释放者的状态（用来读/改数据）
var caster_state: PlayerSaveableState
# 释放上下文（释放时的位置、方向等信息）
var context: CastContext
var skill_node:Node2D

# 初始化（SkillCaster 调用）
func setup(skill_data: SkillData, caster_ref: CharacterBody2D, cast_context: CastContext) -> void:
    data = skill_data
    caster = caster_ref
    caster_state = caster_ref.state
    context = cast_context
    skill_node = get_parent() 
    # 调用子类的 on_cast
    on_cast()

# 供SkillCaster统一调用，无需在意具体技能的具体逻辑
# === 子类重写这些函数 ===
# 技能释放时调用（子类重写）
func on_cast() -> void:
    pass

# 每帧更新（子类重写，可选）
func on_update(delta: float) -> void:
    pass

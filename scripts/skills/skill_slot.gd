extends RefCounted
class_name SkillSlot

# 技能切换
signal skill_changed(data:SkillData)
# 冷却比例变化触发
signal cooldown_updated(ratio:float,remaining:float)

# enum SkillState {
#     IDLE,       # 空闲可施放
#     CASTING,    # 施法前摇中
#     COOLDOWN    # 冷却中
# }
# 技能数据配置
var skill_data:SkillData
# 技能场景
var skill_caster:CharacterBody2D
# 冷却数据
var cooldown:float = 0.0
var cooldown_remaining:float = 0.0

func _init(data:SkillData,caster:CharacterBody2D)->void:
    skill_data = data
    cooldown = skill_data.cooldown
    cooldown_remaining = 0.0
    skill_caster = caster
    # 信号
    skill_changed.emit(skill_data)

func set_skill(new_data:SkillData)->void:
    skill_data = new_data
    cooldown = skill_data.cooldown
    cooldown_remaining = 0.0
    # 技能图标
    skill_changed.emit(skill_data)
    # 冷却ui状态
    cooldown_updated.emit(0.0,0.0)

func update(delta:float)->void:
    if cooldown_remaining>0:
        cooldown_remaining-=delta
        if cooldown_remaining<0:
            cooldown_remaining=0.0
        var ratio:float = 0.0
        if cooldown>0:
            ratio = cooldown_remaining/cooldown
        cooldown_updated.emit(ratio,cooldown_remaining)

func can_cast()->bool:
    return (
        cooldown_remaining<=0 && 
        (skill_caster.get_mp()>=skill_data.flame_mp_cost)
    )

func cast(context:CastContext)->Node2D:
    if not can_cast():
        return null

    # 创建技能效果实例
    if skill_data.scene:
        var skill_instance = skill_data.scene.instantiate()
        skill_instance.data = skill_data
        if skill_instance.has_method("setup"):
            skill_instance.setup(context)
        # 花费能量
        skill_caster.cost_mp(skill_data.flame_mp_cost)
        # 开始冷却
        cooldown_remaining = cooldown
        return skill_instance
    else:
        return null

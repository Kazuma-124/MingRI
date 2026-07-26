extends RefCounted
class_name SkillSlot

# 技能切换
signal skill_changed(data:SkillData)
# 冷却比例变化触发
signal cooldown_updated(ratio:float)

# enum SkillState {
#     IDLE,       # 空闲可施放
#     CASTING,    # 施法前摇中
#     COOLDOWN    # 冷却中
# }
# 技能数据配置
var skill_data:Resource
# 技能场景
var skill_caster:CharacterBody2D
# 冷却数据
var cooldown:float = 0.0
var cooldown_remaining:float = 0.0

func _init(data:Resource,caster:CharacterBody2D)->void:
    skill_data = data
    cooldown = skill_data.cooldown
    cooldown_remaining = 0.0
    skill_caster = caster
    # 信号
    skill_changed.emit(skill_data)

func set_skill(new_data:Resource)->void:
    skill_data = new_data
    cooldown = skill_data.cooldown
    cooldown_remaining = 0.0
    skill_changed.emit(skill_data)

func update(delta:float)->void:
    if cooldown_remaining>0:
        cooldown_remaining-=delta
        if cooldown_remaining<0:
            cooldown_remaining=0.0

func can_cast()->bool:
    return (
        cooldown_remaining<=0 && 
        (skill_caster.get_mp()>=skill_data.flame_mp_cost)
    )

func cast(caster:Node2D)->Node2D:
    print_debug("最大冷却",cooldown)
    print_debug("剩余冷却",cooldown_remaining)
    if not can_cast():
        return null

    # 创建技能效果实例
    var skill_instance = skill_data.scene.instantiate()
    skill_instance.data = skill_data

    # 花费能量
    caster.cost_mp(skill_data.flame_mp_cost)
    # 开始冷却
    cooldown_remaining = cooldown
    return skill_instance

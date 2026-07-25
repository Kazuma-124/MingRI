extends RefCounted
class_name SkillSlot

# enum SkillState {
#     IDLE,       # 空闲可施放
#     CASTING,    # 施法前摇中
#     COOLDOWN    # 冷却中
# }
# 技能数据配置
var skill_data:Resource
# 技能场景
var skill_scene:PackedScene
var skill_caster:CharacterBody2D

var cooldown:float = 0.0
var cooldown_remaining:float = 0.0

func _init(data:Resource,scene:PackedScene,caster:CharacterBody2D)->void:
    skill_data = data
    skill_scene = scene
    skill_caster = caster
    cooldown = skill_data.cooldown
    cooldown_remaining = 0.0

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
    if not can_cast():
        return null
    # 花费能量
    caster.cost_mp(skill_data.flame_mp_cost)
    # 开始冷却
    cooldown_remaining = cooldown
    var skill_instance = skill_scene.instantiate()
    return skill_instance
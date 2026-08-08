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
var caster:CharacterBody2D
# 冷却数据
var cooldown:float = 0.0
var cooldown_remaining:float = 0.0

func _init()->void:
    pass

# skill_data和skill_caster等外部数据加载好之后
# 自己内部数据的初始化，例如cooldown和cooldown_remaining
func self_data_init()->void:
    cooldown = skill_data.cooldown
    cooldown_remaining = 0

# ===== 工厂方法，负责初始化外部数据
# static关键字，函数属于类，不属于实例，不需要实例化就能调用
static func from_data(data_input:SkillData,caster_input:CharacterBody2D)->SkillSlot:
    var slot = SkillSlot.new()
    slot.skill_data = data_input
    slot.caster = caster_input
    slot.self_data_init()
    return slot

static func from_id(skill_id:StringName,caster_input:CharacterBody2D)->SkillSlot:
    var data = SkillLibrary.get_skill(skill_id)
    return SkillSlot.from_data(data,caster_input)

static func empty()->SkillSlot:
    return SkillSlot.new()

func emit_skill_changed()->void:
    skill_changed.emit(skill_data)

func set_skill(new_data:SkillData)->void:
    skill_data = new_data
    self_data_init()
    # 技能图标
    skill_changed.emit(skill_data)
    # 冷却ui状态
    cooldown_updated.emit(0.0,0.0)

func update(delta:float)->void:
    # 不需要外部数据
    if cooldown_remaining>0 && skill_data && is_instance_valid(caster):
        cooldown_remaining-=delta
        if cooldown_remaining<0:
            cooldown_remaining=0.0
        var ratio:float = 0.0
        if cooldown>0:
            ratio = cooldown_remaining/cooldown
        cooldown_updated.emit(ratio,cooldown_remaining)

func can_cast() -> bool:
    if cooldown_remaining > 0:
        return false
    if not skill_data:
        return false
    if not is_instance_valid(caster):
        return false
    
    # 关键：通过 caster 的方法判定，不直接访问玩家变量
    if not caster.has_method("has_enough_mp"):
        return false
    
    return caster.has_enough_mp(skill_data.attribute_type, skill_data.mp_cost)

func cast(context:CastContext)->Node2D:
    if not can_cast():
        return null

    # 创建技能效果实例
    if skill_data.scene:
        var skill_instance = skill_data.scene.instantiate()
        skill_instance.data = skill_data
        if skill_instance.has_method("setup"):
            skill_instance.setup(context)
        if caster.has_method("cost_mp"):
            # 花费能量
            caster.cost_mp(skill_data.attribute_type,skill_data.mp_cost)
        # 开始冷却
        cooldown_remaining = cooldown
        cooldown_updated.emit(1.0,cooldown)
        return skill_instance
    else:
        return null

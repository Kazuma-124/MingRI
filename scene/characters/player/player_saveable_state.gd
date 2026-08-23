# UI的初始化由UI获取player信息后自己发动
extends RefCounted
class_name PlayerSaveableState

#region 信号与触发函数
signal hp_changed(cur:float,max:float)
signal mp_changed(attr:AttributeTypes.Type,cur:float)
signal mp_all_changed(
    mp:Array[float],
    max:float
)
signal primary_attack_switched(skill_id)
signal primary_attack_skills_updated(ids:Array[StringName])
signal slot_skill_changed(slot_id:int,skill_id:StringName)
func emit_hp_changed()->void:
    hp_changed.emit(cur_hp,max_hp)
func emit_mp_changed(attr:AttributeTypes.Type,val:float)->void:
    mp_changed.emit(attr,val)
func emit_mp_all_changed()->void:
    mp_all_changed.emit(mp,max_mp)
func emit_primary_attack_switched()->void:
    primary_attack_switched.emit(curr_primary_attack_skill_id)
func emit_primary_attack_skills_updated()->void:
    primary_attack_skills_updated.emit(primary_attack_skill_ids)
func emit_shortcut_skill_changed(slot_id:int):
    slot_skill_changed.emit(slot_id,skill_slot_ids[slot_id])
#endregion


#region 数据
# === 基础等级
var base_level:int = 1
var base_exp:int = 0
# === 四属性等级
var chiyan_level:int = 1
var chiyan_exp:int = 0

var shengxi_level:int = 1
var shengxi_exp:int = 0

var shuangxuan_level:int = 1
var shuangxuan_exp:int = 0

var youying_level:int = 1
var youying_exp:int = 0

# === 属性
var max_hp:float = 100.0
var cur_hp:float = 100.0
var max_mp:float = 1000.0
var mp:Array[float] = [250.0,250.0,250.0,250.0]

# 技能
# key:StringName(skill_id),value:SkillInstance
var skill_instances:Dictionary = {}
var learned_skill_ids:Array[StringName] = []
var primary_attack_skill_ids:Array[StringName] = []
var curr_primary_attack_index:int = 0
var curr_primary_attack_skill_id:StringName=&"empty_hand"
var skill_slot_ids:Array[StringName] = [] # 索引是槽位号
#endregion



#region 初始化init
# 初始化
func init_with_start_data(data:PlayerData)->void:
    init_hp(data.max_hp,data.max_hp)
    init_mp_from_max_mp(data.max_mp)
    # 已学习技能和普攻技能
    # 加载 learned_skill
    for skill in data.default_skills:
        if skill.unlock_level <= base_level:
            learn_skill(skill)
    # 加载 primary_attack_skill_ids
    for skill_id in learned_skill_ids:
        var skill = get_skill_data(skill_id)
        if skill.skill_type == SkillData.SkillType.PRIMARY_ATTACK && skill.unlock_level==0:
            primary_attack_skill_ids.append(skill_id)
    curr_primary_attack_index = 0
    curr_primary_attack_skill_id = primary_attack_skill_ids[0] if primary_attack_skill_ids.size()>0 else &""
    # skill_slot_ids
    skill_slot_ids.resize(data.skill_slot_count)
    skill_slot_ids.fill(&"")

func init_hp(cur:float,max_input:float)->void:
    cur_hp = cur
    max_hp = max_input
func init_mp_from_max_mp(max_input:float)->void:
    max_mp = max_input
    var per_mp:float = max_mp/AttributeTypes.Type.size()
    for i in range(AttributeTypes.Type.size()):
        mp[i] = per_mp
func init_mp_from_all_mp(mp_arr:Array[float],max_input:float)->void:
    mp = mp_arr
    max_mp = max_input
#endregion

#region hp_and_mp
# hp修改
func take_damage(amount:float)->void:
    cur_hp -= amount
    if cur_hp < 0:
        cur_hp = 0
    hp_changed.emit(cur_hp,max_hp)

func heal(amount:float)->void:
    cur_hp += amount
    if cur_hp > max_hp:
        cur_hp = max_hp
    hp_changed.emit(cur_hp,max_hp)

# mp获取
func get_mp(attr:AttributeTypes.Type)->float:
    return mp[attr]

func has_enough_mp(attr:AttributeTypes.Type,amount:float)->bool:
    return mp[attr]>=amount

func get_total_mp() -> float:
    var total:float = 0.0
    for val in mp:
        total+=val
    return total

# mp修改
func cost_mp(attr:AttributeTypes.Type,amount:float)->bool:
    if not has_enough_mp(attr,amount):
        return false
    mp[attr]-=amount

    emit_mp_changed(attr,mp[attr])
    return true

func drain_mp(attr:AttributeTypes.Type,amount:float)->float:
    if amount <=0.0:
        return 0.0
    var actual = min(mp[attr],amount)
    mp[attr]-=actual
    emit_mp_changed(attr,mp[attr])
    return actual

# 吸收某属性能量
func absorb_mp(attr: AttributeTypes.Type, amount: float) -> void:
    # 1. 先加上
    mp[attr]+=amount
    
    # 2. 检查是否超出上限
    var total = get_total_mp()
    if total <= max_mp:
        emit_mp_changed(attr,mp[attr])
        return  # 没超，不用消散
    
    # 3. 超出了，迭代消散
    var overflow = total - max_mp
    _dissipate_overflow(overflow)
    emit_mp_all_changed() 

# 迭代消散超出的能量
func _dissipate_overflow(overflow: float) -> void:
    var remaining = overflow
    
    # 最多迭代 4 轮（四种能量），不会死循环
    for _i in range(AttributeTypes.Type.size()):
        if remaining <= 0.001:  # float 精度，差不多 0 就算了
            break
        
        # 统计有多少种能量还能扣（> 0）
        var count = 0
        for val in mp:
            if val>0.001:
                count+=1
        
        if count == 0:
            push_warning("all_mp is 0 in dissipate_overflow")
            break  # 都扣光了，不应该发生
        
        # 每种要扣多少
        var per_mp = remaining / count
        
        # 实际扣了多少
        var actually_dissipated = 0.0
        
        for i in range(mp.size()):
            if mp[i] > 0.001:
                var deduct = min(mp[i],per_mp)
                mp[i]-=deduct
                actually_dissipated+=deduct
        # 更新剩余超出量
        remaining -= actually_dissipated

# 调整能量分配（从一种转移到另一种）
func transfer_mp(from_attr: AttributeTypes.Type, to_attr: AttributeTypes.Type, amount: float) -> bool:
    if mp[from_attr] < amount:
        return false
    
    var actual = drain_mp(from_attr,amount)
    mp[to_attr]+=actual

    emit_mp_changed(from_attr,mp[from_attr])
    emit_mp_changed(to_attr,mp[to_attr])
    return true

#endregion


# 技能
#region 技能通用设定
# ---skill_common
# 通用
func learn_skill(skill:SkillData)->void:
    if skill.id in skill_instances:
        return
    var instance = SkillInstance.new(skill)
    skill_instances[skill.id] = instance
    learned_skill_ids.append(skill.id)

func get_skill_instance(skill_id:StringName)->SkillInstance:
    return skill_instances.get(skill_id,null)
func get_skill_data(skill_id:StringName)->SkillData:
    var instance = get_skill_instance(skill_id)
    if instance:
        return instance.data
    return null
#endregion


#region skill_slots
# ---skill_slots ---slot_skills
# 技能快捷槽相关
func set_slot_skill(skill_id:StringName,slot_id:int)->void:
    if not (skill_id in skill_instances.keys()) or (slot_id<0 or slot_id>=skill_slot_ids.size()):
        return
    skill_slot_ids[slot_id] = skill_id 
    emit_shortcut_skill_changed(slot_id)
func get_slot_skill(slot_id:int)->SkillData:
    if slot_id < 0 or slot_id >= skill_slot_ids.size():
        return null
    return get_skill_data(skill_slot_ids[slot_id])
func get_slot_skill_id(slot_id:int)->StringName:
    if slot_id>=0 and slot_id<skill_slot_ids.size():
        return skill_slot_ids[slot_id]
    return &""
#endregion


#region 普攻
# 普攻
func add_skill_in_primary_attack(skill_id:StringName)->void:
    var data = get_skill_data(skill_id)
    if not data or data.skill_type!=SkillData.SkillType.PRIMARY_ATTACK:
        return
    primary_attack_skill_ids.append(skill_id)
    emit_primary_attack_skills_updated()
func change_skill_in_primary_attack(skill_id:StringName,arr_id:int)->void:
    if arr_id<0 or arr_id>=primary_attack_skill_ids.size():
        return
    var data = get_skill_data(skill_id)
    if not data or data.skill_type!=SkillData.SkillType.PRIMARY_ATTACK:
        return
    primary_attack_skill_ids[arr_id] = skill_id
    emit_primary_attack_skills_updated()
# 点击普攻槽 → 切换到下一个预设
func switch_primary_attack() -> void:
    if primary_attack_skill_ids.size() <= 1:
        return  # 只有一个，不用切
    
    # 找到当前技能在列表里的位置
    curr_primary_attack_index = (curr_primary_attack_index+1) % primary_attack_skill_ids.size()
    curr_primary_attack_skill_id = primary_attack_skill_ids[curr_primary_attack_index] 
    emit_primary_attack_switched()

#endregion


#region 释放技能相关
# 释放技能相关
func update_skill_cooldowns(delta: float) -> void:
    for skill_id in skill_instances.keys():
        var instance = skill_instances[skill_id]
        instance.update_cooldown(delta)

func is_skill_cooldown_ready(skill_id:StringName)->bool:
    var instance = get_skill_instance(skill_id)
    if not instance:
        return false
    return instance.current_cooldown<=0.0

func can_cast(skill_id:StringName)->bool:
    # 检查冷却
    if not is_skill_cooldown_ready(skill_id):
        return false
    # 检查能量
    var instance = get_skill_instance(skill_id)
    if not has_enough_mp(instance.data.attribute_type, instance.data.mp_cost):
        return false
    return true

# 开始技能冷却
func start_skill_cooldown(skill_id: StringName) -> void:
    var instance = get_skill_instance(skill_id)
    if not instance:
        return
    instance.start_cooldown()

func confirm_cast(skill_id:StringName)->bool:
    var instance = get_skill_instance(skill_id)
    if instance:
        # 消耗能量
        cost_mp(instance.data.attribute_type, instance.data.mp_cost)
        # 开始冷却
        start_skill_cooldown(skill_id)
        return true
    else:
        return false


# 尝试释放技能（检查冷却和能量）
func try_cast_skill(skill_id: StringName) -> bool:
    if can_cast(skill_id):
        return confirm_cast(skill_id)
    else:
        return false 
#endregion



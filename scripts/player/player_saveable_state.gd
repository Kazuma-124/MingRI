# UI的初始化由UI获取player信息后自己发动
extends RefCounted
class_name PlayerSaveableState

signal hp_changed(cur:float,max:float)
signal mp_changed(attr:AttributeTypes.Type,cur:float)
signal mp_all_changed(
    mp:Array[float],
    max:float
)
func emit_hp_changed()->void:
    hp_changed.emit(cur_hp,max_hp)
func emit_mp_changed(attr:AttributeTypes.Type,val:float)->void:
    mp_changed.emit(attr,val)
func emit_mp_all_changed()->void:
    mp_all_changed.emit(mp)

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
var learned_skills:Array[SkillData] = []
var primary_attack_skills:Array[SkillData] = []
var skills_in_slot:Array[SkillData] = [] # 索引是槽位号

# 初始化
func init_with_start_data(data:PlayerData)->void:
    init_hp(data.max_hp,data.max_hp)
    init_mp_from_max_mp(data.max_mp)
    # 已学习技能和普攻技能
    # 加载 learned_skill
    for skill in data.default_skills:
        if skill.unlock_level <= base_level:
            learned_skills.append(skill)
    # 加载 primary_attack_skills
    for skill in learned_skills:
        if skill.skill_type == SkillData.SkillType.PRIMARY_ATTACK && skill.unlock_level==0:
            primary_attack_skills.append(skill)
    # skills_in_slot
    skills_in_slot.resize(data.skill_slot_count)

func init_hp(cur:float,max:float)->void:
    cur_hp = cur
    max_hp = max
    emit_hp_changed()
func init_mp_from_max_mp(max:float)->void:
    max_mp = max
    var per_mp:float = max_mp/AttributeTypes.Type.size()
    for i in range(AttributeTypes.Type.size()):
        mp[i] = per_mp
func init_mp_from_all_mp(mp_arr:Array[float],max:float)->void:
    mp = mp_arr
    max_mp = max


# hp修改
func take_damage(amount:float)->void:
    cur_hp -= amount
    if cur_hp < 0:
        cur_hp = 0
    hp_changed.emit(cur_hp,max_hp)

func heap(amount:float)->void:
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
        



# var save_position:Vector2 = Vector2.ZERO
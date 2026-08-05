extends RefCounted
class_name PlayerRuntimeState

signal hp_changed(cur:float,max:float)
signal mp_changed(attr:AttributeTypes.Type,cur:float)
signal mp_all_changed(
    chiyan:float,
    shengxi:float,
    shuangxuan:float,
    youying:float,
    max:float
)

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
func _init_hp(cur:float,max:float)->void:
    cur_hp = cur
    max_hp = max
    emit_hp_changed()

func emit_hp_changed()->void:
    hp_changed.emit(cur_hp,max_hp)

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

var max_mp:float = 1000.0
var chiyan_mp: float = 250.0    # 赤焰能量
var shengxi_mp: float = 250.0   # 生息能量
var shuangxuan_mp: float = 250.0  # 霜玄能量
var youying_mp: float = 250.0   # 幽影能量


func _init_mp_from_max_mp(max:float)->void:
    max_mp = max
    var per_mp:float = max_mp/AttributeTypes.Type.size()
    chiyan_mp = per_mp    # 赤焰能量
    shengxi_mp = per_mp   # 生息能量
    shuangxuan_mp = per_mp  # 霜玄能量
    youying_mp = per_mp   # 幽影能量
    emit_mp_all_changed()
# func _init_mp(max:float)

func emit_mp_all_changed()->void:
    mp_all_changed.emit(
        chiyan_mp,
        shengxi_mp,
        shuangxuan_mp,
        youying_mp,
        max_mp
    )


func get_mp(attr:AttributeTypes.Type)->float:
    match attr:
        AttributeTypes.Type.CHIYAN:
            return chiyan_mp
        AttributeTypes.Type.SHENGXI:
            return shengxi_mp
        AttributeTypes.Type.SHUANGXUAN:
            return shuangxuan_mp
        AttributeTypes.Type.YOUYING:
            return youying_mp
        _:
            return 0.0

func has_enough_mp(attr:AttributeTypes.Type,amount:float)->bool:
    return get_mp(attr)>=amount

func get_total_mp() -> float:
    return chiyan_mp + shengxi_mp + shuangxuan_mp + youying_mp

func cost_mp(attr:AttributeTypes.Type,amount:float)->bool:
    if not has_enough_mp(attr,amount):
        return false
    match attr:
        AttributeTypes.Type.CHIYAN:
            chiyan_mp -= amount
        AttributeTypes.Type.SHENGXI:
            shengxi_mp -= amount
        AttributeTypes.Type.SHUANGXUAN:
            shuangxuan_mp -= amount
        AttributeTypes.Type.YOUYING:
            youying_mp -= amount
        _:
            push_warning("cost_mp has wrong atrr")
    mp_changed.emit(attr,get_mp(attr))
    return true

# 吸收某属性能量
func absorb_mp(attr: AttributeTypes.Type, amount: float) -> void:
    # 1. 先加上
    match attr:
        AttributeTypes.Type.CHIYAN:
            chiyan_mp += amount
        AttributeTypes.Type.SHENGXI:
            shengxi_mp += amount
        AttributeTypes.Type.SHUANGXUAN:
            shuangxuan_mp += amount
        AttributeTypes.Type.YOUYING:
            youying_mp += amount
    
    # 2. 检查是否超出上限
    var total = get_total_mp()
    if total <= max_mp:
        mp_changed.emit(attr,get_mp(attr))
        return  # 没超，不用消散
    
    # 3. 超出了，迭代消散
    var overflow = total - max_mp
    _dissipate_overflow(overflow)
    emit_mp_all_changed() 

# 迭代消散超出的能量
func _dissipate_overflow(overflow: float) -> void:
    var remaining = overflow
    
    # var count = AttributeTypes.Type.size()
    # 最多迭代 4 轮（四种能量），不会死循环
    for _i in 4:
        if remaining <= 0.001:  # float 精度，差不多 0 就算了
            break
        
        # 统计有多少种能量还能扣（> 0）
        var count = 0
        if chiyan_mp > 0.001: count += 1
        if shengxi_mp > 0.001: count += 1
        if shuangxuan_mp > 0.001: count += 1
        if youying_mp > 0.001: count += 1
        
        if count == 0:
            push_warning("all_attr_mp is 0, in dissipate_overflow,should not happen")
            break  # 都扣光了，不应该发生
        
        # 每种要扣多少
        var per_mp = remaining / count
        
        # 实际扣了多少
        var actually_dissipated = 0.0
        
        # 挨个扣
        if chiyan_mp > 0.001:
            var deduct = min(chiyan_mp, per_mp)
            chiyan_mp -= deduct
            actually_dissipated += deduct
        
        if shengxi_mp > 0.001:
            var deduct = min(shengxi_mp, per_mp)
            shengxi_mp -= deduct
            actually_dissipated += deduct
        
        if shuangxuan_mp > 0.001:
            var deduct = min(shuangxuan_mp, per_mp)
            shuangxuan_mp -= deduct
            actually_dissipated += deduct
        
        if youying_mp > 0.001:
            var deduct = min(youying_mp, per_mp)
            youying_mp -= deduct
            actually_dissipated += deduct
        
        # 更新剩余超出量
        remaining -= actually_dissipated

# 调整能量分配（从一种转移到另一种）
func transfer_mp(from_attr: AttributeTypes.Type, to_attr: AttributeTypes.Type, amount: float) -> bool:
    if get_mp(from_attr) < amount:
        return false
    
    cost_mp(from_attr, amount)
    # 这里直接加，因为是内部转移，总量不变
    match to_attr:
        AttributeTypes.Type.CHIYAN:
            chiyan_mp += amount
        AttributeTypes.Type.SHENGXI:
            shengxi_mp += amount
        AttributeTypes.Type.SHUANGXUAN:
            shuangxuan_mp += amount
        AttributeTypes.Type.YOUYING:
            youying_mp += amount
    mp_changed.emit(from_attr,get_mp(from_attr))
    mp_changed.emit(to_attr,get_mp(to_attr))
    return true
        

# 技能
var learned_skills:Array[SkillData] = []
var primary_attack_skills:Array[SkillData] = []
var skill_slots:Array[SkillData] = [] # 索引是槽位号

# var save_position:Vector2 = Vector2.ZERO
extends Node

# ==================== 内部缓存 ====================
# 所有技能数据缓存，key=技能ID，value=SkillData资源实例
var _skill_data_cache: Dictionary = {}
# 所有技能逻辑实例缓存，key=技能ID，value=无状态技能逻辑实例   
# 所有调用某一技能的角色使用的都是统一技能逻辑实例
var _skill_logic_cache: Dictionary = {}

# ==================== 信号（全局广播） ====================
signal skill_cast_success(skill_id: String, caster: EntityBase)
signal skill_cast_failed(skill_id: String, caster: EntityBase, reason: String)

# ==================== 初始化 ====================
func _ready() -> void:
    _load_all_skill_data()
    _register_all_skill_logic()

# 预加载所有技能配置资源（也可以按需懒加载）
func _load_all_skill_data() -> void:
    # 遍历data/skills目录加载所有.tres，或者用配置表注册
    # Demo阶段可以手动注册，正式项目用资源加载器批量扫
    _register_skill_data("bullet_flame", preload("res://data/skills/skill_bullet_flame.tres"))
    #_register_skill_data("slash", preload("res://data/skills/skill_slash.tres"))

# 注册所有技能逻辑（全局共享一份实例）
func _register_all_skill_logic() -> void:
    _skill_logic_cache["bullet_flame"] = SkillBulletFlame.new()
    #_skill_logic_cache["slash"] = SkillSlash.new()

# ==================== 对外公共接口 ====================

## 根据ID查询技能数据
func get_skill_data(skill_id: String) -> SkillData:
    return _skill_data_cache.get(skill_id, null)

## 判断技能是否存在
func has_skill(skill_id: String) -> bool:
    return _skill_data_cache.has(skill_id) && _skill_logic_cache.has(skill_id)

## 统一施放技能入口（SkillSlot调用这个执行实际效果）
func execute_skill(skill_id: String, caster: EntityBase) -> bool:
    # 1. 基础校验
    var data: SkillData = get_skill_data(skill_id)
    if data == null:
        skill_cast_failed.emit(skill_id, caster, "技能数据不存在")
        return false
    
    # 2. 全局公共校验：能量、等级、状态等
    if not _check_common_requirements(caster, data):
        skill_cast_failed.emit(skill_id, caster, "条件不满足")
        return false
    
    if not data.custom_energy_cost:
        # 3. 扣能量，扣指定角色，指定属性，指定技能需求的能量
        EnergySystem.consume_energy(caster, data.element, data.energy_cost)
    
    # 4. 调用对应技能逻辑执行效果，技能不存在就返回null
    var logic = _skill_logic_cache.get(skill_id, null)
    if logic == null:
        skill_cast_failed.emit(skill_id,caster,"技能逻辑不存在")
        return false
    logic.execute(caster, data)
        
    
    # 5. 全局广播
    skill_cast_success.emit(skill_id, caster)
    EventBus.skill_casted.emit(skill_id, caster)
    
    return true

# ==================== 内部方法 ====================

## 公共施放校验：能量、解锁等级等
func _check_common_requirements(caster: EntityBase, data: SkillData) -> bool:
    # 能量够不够
    if not EnergySystem.has_enough_energy(caster, data.element, data.energy_cost):
        return false
    # 角色有没有死亡
    if caster.is_dead:
        return false
    return true

## 注册技能数据
func _register_skill_data(skill_id: String, data: SkillData) -> void:
    _skill_data_cache[skill_id] = data

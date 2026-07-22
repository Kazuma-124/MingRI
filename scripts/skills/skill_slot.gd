extends RefCounted
class_name SkillSlot

## 技能槽类：管理单个技能槽的状态
## 每个角色的每个主动技能槽对应一个实例

# ==================== 状态数据 ====================
var skill_id: String = ""              # 当前装备的技能ID
var cooldown_remaining: float = 0.0    # 剩余冷却时间
var _data_cache: SkillData = null      # 技能数据缓存

# ==================== 信号 ====================
signal skill_casted(skill_id: String)
signal cooldown_started(skill_id: String, total: float)
signal skill_equip_changed(new_skill_id: String)

# ==================== 装备管理 ====================

## 装备技能到槽位
func equip(skill_id: String) -> void:
    if self.skill_id == skill_id:
        return
    
    self.skill_id = skill_id
    _data_cache = SkillSystem.get_skill_data(skill_id)
    cooldown_remaining = 0.0
    skill_equip_changed.emit(skill_id)

## 卸下槽位技能
func unequip() -> void:
    skill_id = ""
    _data_cache = null
    cooldown_remaining = 0.0
    skill_equip_changed.emit("")

# ==================== 状态更新 ====================

## 每帧更新冷却，由持有槽位的角色统一调用
func update(delta: float) -> void:
    if cooldown_remaining <= 0.0:
        return
    cooldown_remaining -= delta
    if cooldown_remaining < 0.0:
        cooldown_remaining = 0.0

# ==================== 施放接口 ====================

## 校验是否可以施放
func can_cast() -> bool:
    return skill_id != "" and _data_cache != null and cooldown_remaining <= 0.0

## 施放技能
func cast(caster: EntityBase) -> bool:
    if not can_cast():
        return false
    
    # 调用全局技能系统执行实际效果（全局校验、扣能量、逻辑执行）
    if not SkillSystem.execute_skill(skill_id, caster):
        return false
    
    # 本地维护冷却状态
    cooldown_remaining = _data_cache.cooldown
    cooldown_started.emit(skill_id, _data_cache.cooldown)
    skill_casted.emit(skill_id)
    return true

## 立即刷新冷却
func reset_cooldown() -> void:
    cooldown_remaining = 0.0

## 获取当前装备的技能数据
func get_data() -> SkillData:
    return _data_cache

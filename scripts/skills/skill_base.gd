
extends Node
class_name SkillBase

# ==================== 技能状态枚举 ====================
enum SkillState {
    IDLE,       # 空闲可施放
    CASTING,    # 施法前摇中
    COOLDOWN    # 冷却中
}

# ==================== 配置数据 ====================
@export var data: SkillData  # 技能配置资源，所有数值从这里取

# ==================== 运行时状态 ====================
var state: SkillState = SkillState.IDLE
var cooldown_remaining: float = 0.0
var caster: Node = null  # 施放者（玩家/敌人/NPC都可以）

# ==================== 信号 ====================
signal skill_cast_started(skill)
signal skill_cast_finished(skill)
signal cooldown_started(skill)

# ==================== 生命周期 ====================
func _process(delta: float) -> void:
    # 统一更新冷却
    if state == SkillState.COOLDOWN:
        cooldown_remaining -= delta
        if cooldown_remaining <= 0.0:
            cooldown_remaining = 0.0
            state = SkillState.IDLE

# ==================== 核心公共接口（所有技能通用） ====================

## 检查是否可以施放
func can_cast() -> bool:
    # 冷却中不能放
    if state != SkillState.IDLE:
        return false
    # 能量不足不能放（后面加能量系统再扩展）
    # if caster.energy < data.energy_cost:
    #     return false
    return true

## 施放技能入口，由技能系统/玩家调用
func cast(caster_node: Node) -> bool:
    if not can_cast():
        return false
    
    caster = caster_node
    state = SkillState.CASTING
    
    skill_cast_started.emit(self)
    EventBus.skill_casted.emit(data.id, caster)
    
    # 调用子类具体的施放逻辑
    _execute_cast()
    
    # 施放完成，进入冷却
    _start_cooldown()
    
    return true

## 立刻结束冷却（比如升级刷新技能）
func reset_cooldown() -> void:
    cooldown_remaining = 0.0
    state = SkillState.IDLE

# ==================== 子类重写区域（策略模式核心） ====================

## 具体技能效果，子类必须重写
func _execute_cast() -> void:
    # 投射物技能：生成子弹
    # 近战技能：触发范围判定
    # Buff技能：给目标加状态
    # 子类各自实现，基类不做具体逻辑
    push_warning("Skill %s not implement _execute_cast()" % data.id)

# ==================== 内部私有方法 ====================

func _start_cooldown() -> void:
    state = SkillState.COOLDOWN
    cooldown_remaining = data.cooldown
    cooldown_started.emit(self)

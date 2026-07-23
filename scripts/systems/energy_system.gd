extends Node
# 全局能量系统：四本源能量统一管理
# 能量值存储在每个EntityBase实体身上，本系统只提供统一操作接口

# ==================== 常量：四本源属性名 ====================
const ELEMENT_FLAME: String = "flame"
const ELEMENT_LIFE: String = "life"
const ELEMENT_FROST: String = "frost"
const ELEMENT_SHADOW: String = "shadow"

# ==================== 信号 ====================
signal energy_changed(entity: EntityBase, element: String, amount: float)

# ==================== 公共查询接口 ====================

## 判断实体是否有足够的能量
## @param entity: 目标实体
## @param element: 属性名 flame/life/frost/shadow
## @param amount: 需要消耗的量
func has_enough_energy(entity: EntityBase, element: String, amount: float) -> bool:
    if amount <= 0:
        return true  # 0消耗直接通过
    if entity == null or entity.is_dead:
        return false
    
    var current: float = _get_energy(entity, element)
    return current >= amount

## 获取实体某属性的当前能量
func get_energy(entity: EntityBase, element: String) -> float:
    if entity == null:
        return 0.0
    return _get_energy(entity, element)

# ==================== 公共操作接口 ====================

## 消耗能量
## @return 是否消耗成功
func consume_energy(entity: EntityBase, element: String, amount: float) -> bool:
    if amount <= 0:
        return true
    if not has_enough_energy(entity, element, amount):
        return false
    
    var current: float = _get_energy(entity, element)
    _set_energy(entity, element, current - amount)
    
    energy_changed.emit(entity, element, -amount)
    return true

## 增加能量（拾取结晶、环境吸收、技能回复用）
func add_energy(entity: EntityBase, element: String, amount: float) -> void:
    if entity == null or entity.is_dead or amount <= 0:
        return
    
    var current: float = _get_energy(entity, element)
    # 后面加能量上限可以在这里做clamp
    _set_energy(entity, element, current + amount)
    
    energy_changed.emit(entity, element, amount)

## 直接设置能量值（GM命令、初始化用）
func set_energy(entity: EntityBase, element: String, value: float) -> void:
    if entity == null:
        return
    var delta: float = value - _get_energy(entity, element)
    _set_energy(entity, element, value)
    energy_changed.emit(entity, element, delta)

# ==================== 内部工具方法 ====================

## 根据属性名读取实体对应的能量值
func _get_energy(entity: EntityBase, element: String) -> float:
    match element:
        ELEMENT_FLAME:
            return entity.energy_flame
        ELEMENT_LIFE:
            return entity.energy_life
        ELEMENT_FROST:
            return entity.energy_frost
        ELEMENT_SHADOW:
            return entity.energy_shadow
        _:
            push_warning("未知能量属性: %s" % element)
            return 0.0

## 根据属性名设置实体的能量值
func _set_energy(entity: EntityBase, element: String, value: float) -> void:
    match element:
        ELEMENT_FLAME:
            entity.energy_flame = value
        ELEMENT_LIFE:
            entity.energy_life = value
        ELEMENT_FROST:
            entity.energy_frost = value
        ELEMENT_SHADOW:
            entity.energy_shadow = value
        _:
            push_warning("未知能量属性: %s" % element)

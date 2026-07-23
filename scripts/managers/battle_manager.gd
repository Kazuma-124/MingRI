extends Node
# 全局战斗管理器：统一伤害结算入口

# ==================== 伤害公式参数 ====================
const DEFENSE_MITIGATION_FACTOR: float = 100.0  # 防御减伤系数，数值越高防御收益越低

# ==================== 统一伤害入口 ====================

## 结算伤害
## @param attacker: 攻击者（玩家/敌人/陷阱都可以）
## @param target: 受击目标，必须是EntityBase
## @param damage_info: 伤害信息字典 {damage, element, is_crit, source_id}
func deal_damage(attacker: Node, target: EntityBase, damage_info: Dictionary) -> void:
    # 1. 基础校验
    if target == null or target.is_dead:
        return
    if not damage_info.has("damage"):
        push_warning("伤害信息缺少damage字段")
        return
    
    # 2. 计算最终伤害
    var final_damage: float = _calculate_final_damage(target, damage_info)
    
    # 3. 构造最终伤害信息
    var final_info: Dictionary = damage_info.duplicate()
    final_info.damage = final_damage
    
    # 4. 目标扣血
    target.take_damage(final_info)
    
    # 5. 全局广播受伤事件（UI、统计、成就、buff都监听这个）
    EventBus.entity_damaged.emit(attacker, target, final_info)

# ==================== 内部伤害计算 ====================

func _calculate_final_damage(target: EntityBase, damage_info: Dictionary) -> float:
    var base_damage: float = damage_info.damage
    var defense: float = target.defense
    
    # 防御减伤公式：最终伤害 = 基础伤害 * ( 防御系数 / (防御系数 + 防御) )
    # 防御越高减伤越多，但永远不会到0，避免无敌
    var mitigation: float = DEFENSE_MITIGATION_FACTOR / (DEFENSE_MITIGATION_FACTOR + defense)
    var final_damage: float = base_damage * mitigation
    
    # 暴击倍率（后面加暴击系统再扩展）
    if damage_info.get("is_crit", false):
        final_damage *= 1.5
    
    # 最低伤害保底1点，避免0伤害
    return max(1.0, final_damage)

# ==================== 工具方法 ====================

## 范围伤害（AOE用）：给指定位置范围内所有实体造成伤害
func deal_area_damage(attacker: Node, center: Vector2, radius: float, damage_info: Dictionary) -> void:
    # 后面做AOE技能的时候再实现，用圆形区域检测Hurtbox
    pass

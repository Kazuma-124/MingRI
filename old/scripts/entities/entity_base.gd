extends CharacterBody2D
class_name EntityBase

# ==================== 基础属性 ====================
@export var max_hp: float = 100.0
@export var defense: float = 10.0  # 你原来写的100太高了，几乎不掉血，先改成10

var hp: float = 0.0
var is_dead: bool = false

# ==================== 修炼属性（四本源通用） ====================
# 四属性能量值
var energy_flame: float = 0.0
var energy_life: float = 0.0
var energy_frost: float = 0.0
var energy_shadow: float = 0.0

# 四属性修炼等级
var level_flame: int = 1
var level_life: int = 1
var level_frost: int = 1
var level_shadow: int = 1

# ==================== 信号 ====================
signal entity_hurt(damage_info)  # 受伤信号，UI/buff可以监听

# ==================== 生命周期 ====================
func _ready() -> void:
    hp = max_hp  # ✅ 新增：初始化血量，不然默认是0

# ==================== 核心接口 ====================

## 受到伤害（子类可重写，比如加受击硬直、减伤buff）
func take_damage(damage_info: Dictionary) -> void:
    if is_dead:
        return
    
    hp -= damage_info.damage
    entity_hurt.emit(damage_info)
    
    if hp <= 0:
        die()

## 死亡
func die() -> void:
    if is_dead:
        return
    is_dead = true
    EventBus.entity_died.emit(self)  # ✅ 修正：事件名和之前EventBus定义统一
    queue_free()

# ==================== 技能通用接口（虚函数，子类重写） ====================

## 获取当前瞄准方向（统一接口，玩家用鼠标，敌人用AI目标）
## 技能逻辑统一调用这个，不用区分是玩家还是敌人
func get_aim_direction() -> Vector2:
    return Vector2.RIGHT  # 默认朝右，子类重写

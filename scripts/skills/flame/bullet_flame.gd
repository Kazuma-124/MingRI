extends Area2D
class_name BulletFlame

# ==================== 配置参数 ====================
var _caster: EntityBase = null
var _damage: float = 0.0
var _element: String = ""
var _velocity: Vector2 = Vector2.ZERO
var _max_range: float = 600.0
var _start_pos: Vector2 = Vector2.ZERO
var _is_exploded: bool = false

# ==================== 初始化 ====================
func setup(caster: EntityBase, damage: float, element: String, direction: Vector2, speed: float, max_range: float) -> void:
    _caster = caster
    _damage = damage
    _element = element
    _velocity = direction.normalized() * speed
    _max_range = max_range
    _start_pos = global_position
    
    # 绑定命中检测
    area_entered.connect(_on_hit_area)

# ==================== 飞行逻辑 ====================
func _physics_process(delta: float) -> void:
    if _is_exploded:
        return
    
    # 移动
    global_position += _velocity * delta
    
    # 超过最大飞行距离 → 爆炸
    if global_position.distance_to(_start_pos) >= _max_range:
        _explode()

# ==================== 命中处理 ====================
func _on_hit_area(hit_area: Area2D) -> void:
    if _is_exploded:
        return
    
    # 打到自己不算
    var target_entity = hit_area.get_parent()
    if target_entity == _caster:
        return
    
    # 只打有Hurtbox的实体
    if not target_entity is EntityBase:
        return
    
    # 命中目标 → 爆炸造成伤害
    _explode(target_entity)

# ==================== 爆炸伤害 ====================
func _explode(direct_target: EntityBase = null) -> void:
    _is_exploded = true
    
    # 单体伤害：直接命中的目标
    if direct_target != null:
        BattleManager.deal_damage(_caster, direct_target, {
            "damage": _damage,
            "element": _element,
            "is_crit": false
        })
    
    # TODO：后面做AOE爆炸范围伤害，可以在这里加范围检测
    
    # 播放爆炸特效（后面加）
    queue_free()

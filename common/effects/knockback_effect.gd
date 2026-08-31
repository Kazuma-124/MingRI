extends StatusEffect
class_name KnockbackEffect

#region 常量
const DEFAULT_SPEED:float = 400.0
#endregion


#region 成员
var _direction:Vector2 = Vector2.ZERO
var _speed:float = 0.0
#endregion

func update(delta:float)->bool:
    # 施加本效果的影响
    target.stagger_velocity += _direction*_speed
    return super.update(delta)

func _init(dir:Vector2,distance:float,speed:float = DEFAULT_SPEED)->void:
    if dir!=Vector2.ZERO:
        _direction = dir.normalized()
    _speed = speed
    duration = distance/speed

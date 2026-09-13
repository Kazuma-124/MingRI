extends RefCounted
class_name AttributeConverter

var _attrs:AttributeSystem

func _init(p_attrs:AttributeSystem)->void:
    _attrs = p_attrs

func get_final_velocity()->Vector2:
    # 先看是否有FORCED_VELOCITY
    if _attrs.has_modifier(StatusStats.FORCED_VELOCITY):
        return _attrs.get_final_value(StatusStats.FORCED_VELOCITY)
    # 定身
    if _attrs.has_tag(StatusTags.ROOTED):
        return Vector2.ZERO
    # 最终速度：自身速度+外力速度
    var direction:Vector2 = _attrs.get_final_value(StatusStats.MOVE_DIRECTION)
    var speed:float = _attrs.get_final_value(StatusStats.MOVE_SPEED)
    var external:Vector2 = _attrs.get_final_value(StatusStats.EXTERNAL_VELOCITY)
    return direction*maxf(speed,0.0)+external

func get_final_heal(amount:float)->float:
    return amount
func get_final_damage(amount:float)->float:
    return amount
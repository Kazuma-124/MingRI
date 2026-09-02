extends Buff
class_name KnockbackBuff

# 击退（硬直类）：贡献 STAGGERED 标签冻结自主状态机 + 强制位移向量

#region 常量
const DEFAULT_SPEED:float = 400.0
#endregion

#region 成员
var _direction:Vector2 = Vector2.ZERO
var _speed:float = 0.0
#endregion

#region 内部函数
func update(delta:float,manager:StatusManager)->bool:
	# 零方向防护：无有效方向时不占标签/不冻结（等价旧机制零方向不硬直）
	if _direction!=Vector2.ZERO:
		manager.add_tag(StatusTags.STAGGERED) # 硬直
		manager.add_forced_velocity(_direction*_speed)
	return super.update(delta,manager)
#endregion

#region 初始化
func _init(dir:Vector2,distance:float,speed:float = DEFAULT_SPEED)->void:
	if dir!=Vector2.ZERO:
		_direction = dir.normalized()
	_speed = speed
	duration = distance/speed
#endregion

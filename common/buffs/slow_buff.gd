extends Buff
class_name SlowBuff

# 减速（非硬直）：向 SPEED_MULTIPLIER 独立乘区直接贡献目标乘率
# factor=0.6 表示速度变为原来的 60%；多个减速乘法叠加（0.6*0.6=0.36）

#region 成员
var _speed_factor:float = 1.0	# 目标速度乘率：1.0 不变，0.0 无法移动
#endregion

#region 内部函数
func update(delta:float,manager:StatusManager)->bool:
	manager.change_stat(StatusManager.Op.MUL,StatusStats.SPEED_MULTIPLIER,_speed_factor)
	return super.update(delta,manager)
#endregion

#region 初始化
# speed_factor 目标速度乘率[0,1]；duration 持续秒数
func _init(speed_factor:float,duration:float)->void:
	_speed_factor = clampf(speed_factor,0.0,1.0)
	self.duration = duration
#endregion

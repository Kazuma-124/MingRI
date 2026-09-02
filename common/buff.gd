extends RefCounted
class_name Buff

# Buff/状态效果基类：只描述持续时间，以及每帧向管理器贡献什么
# 不持有目标；每帧由 StatusManager.update_effects 驱动并传入管理器

#region 成员变量
var duration:float = 0.0
var _elapsed:float = 0.0
#endregion

#region 外部接口
# 每帧驱动；返回 false 表示到期，由管理器移除
func update(delta:float,_manager:StatusManager)->bool:
	_elapsed += delta
	return _elapsed<duration

# 移除时回调（对称传入管理器，供子类结束时清理/归还）
func remove(_manager:StatusManager)->void:
	pass
#endregion

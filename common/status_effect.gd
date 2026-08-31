extends RefCounted
class_name StatusEffect

#region 成员变量
var target:CharacterBody2D
var duration:float = 0.0
var _elapsed:float = 0.0
#endregion

#region 外部接口
func apply(_t:CharacterBody2D)->void:
	target = _t

func update(delta:float)->bool:
	_elapsed+=delta
	return _elapsed<duration # false=效果结束

func remove()->void:pass
#endregion

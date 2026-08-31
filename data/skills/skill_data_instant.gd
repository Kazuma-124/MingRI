extends SkillData
class_name SkillDataInstant

#region 枚举
enum DirectionMode{
	MOUSE_DIRECTION,	# 取鼠标方向
	CASTER_FACING,		# 施法者当前朝向
	NONE,				# 无方向（自身buff，自身范围技）
}
#endregion

#region export
@export var direction_mode = DirectionMode.MOUSE_DIRECTION
#endregion

#region 生命周期
func _init():
	targeting_type = TargetingType.INSTANT
#endregion

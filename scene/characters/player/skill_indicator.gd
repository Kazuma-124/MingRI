extends Node2D
class_name SkillIndicator

#region 外部接口
func setup(skill_data:SkillData,caster:Node2D)->void:
	pass

func generate_castcontext()->CastContext:
	return null
	pass

func get_is_valid()->bool:
	pass
	return true

func get_aim_direction()->Vector2:
	return Vector2.ZERO
#endregion

extends SkillData
class_name SkillDataInstant

enum DirectionMode{
	MOUSE_DIRECTION,
	CASTER_SELF
}

func _init():
	targeting_type = TargetingType.INSTANT

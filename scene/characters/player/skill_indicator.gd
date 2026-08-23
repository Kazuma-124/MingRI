extends Node2D
class_name SkillIndicator

func setup(skill_data:SkillData,caster:Node2D)->void:
    pass

func update_aim(mouse_position:Vector2)->CastContext:
    pass
    return null

func get_is_valid()->bool:
    pass
    return true

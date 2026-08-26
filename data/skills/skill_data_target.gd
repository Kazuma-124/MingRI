extends SkillData
class_name SkillDataTarget

@export_group("指示器")
@export var cast_range:float = 200.0
@export var select_tolerance:float = 20.0   # 鼠标选取容差半径
@export var highlight_radius:float = 24.0   # 目标高亮圈半径

func _init():
    targeting_type = TargetingType.TARGET
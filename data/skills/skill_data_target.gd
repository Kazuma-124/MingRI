extends SkillData
class_name SkillDataTarget

@export_group("指示器")
@export var cast_range:float = 200.0
@export var highlight_radius:float = 24.0   # 目标高亮圈半径
@export var select_tolerance:float = 8.0   # 鼠标选取容差半径
@export var cursor_radius:float = 8.0       # 鼠标位置小圆点
@export var indicator_color:Color = Color(0,0.2,1.0,0.5) 
@export var invalid_color:Color = Color(0.5,0.5,0.5,0.4)

@export_group("目标规则")
@export var can_target_self:bool = false    # 是否可以选择自己为施法对象

func _init():
    targeting_type = TargetingType.TARGET
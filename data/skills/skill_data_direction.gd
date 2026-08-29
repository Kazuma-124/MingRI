extends SkillData
class_name SkillDataDirection


#region 指示器
@export_group("指示器")
@export var indicator_shape:IndicatorShape
@export var indicator_color:Color = GameColors.INDICATOR_VALID
@export var show_fly_range:bool = true	# 是否画表示投射物飞行距离的圈
#endregion

@export_group("投射物")
@export var fly_distance: float
@export var fly_speed: float



func _init():
	targeting_type = TargetingType.DIRECTION

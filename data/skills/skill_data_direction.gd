extends SkillData
class_name SkillDataDirection

enum IndicatorShape{
	NONE, # 无范围图形, 纯方向选择
	RECTANGLE, # 长方形，以玩家为起点，朝方向眼神
	SECTOR,	# 扇形，以玩家为圆心，超方向展开
}

@export var indicator_shape:SkillDataDirection.IndicatorShape = IndicatorShape.NONE
@export var indicator_length:float	# 矩形长度/扇形半径
@export var indicator_width:float 	# 矩形宽度（扇形不用）
@export var indicator_angle:float	# 扇形角度（矩形不用）

@export_group("投射物")
@export var fly_distance: float
@export var fly_speed: float

@export_subgroup("fireball")
@export var damage_range:float = 32 # 伤害范围，直径
@export var anime_duration_time:float = 0.3
@export var bullet_diameter:float = 8 # 子弹直径（像素）
@export var explosion_diameter:float = 32 # 爆炸特效直径（像素）


func _init():
	targeting_type = TargetingType.DIRECTION

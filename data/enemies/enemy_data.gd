extends Resource
class_name EnemyData

# @export_group("基本信息")

@export_group("基础属性")
@export var max_hp:float = 100.0

@export_group("移动属性")
@export var vision_radius:float = 250.0 # 视野范围半径
@export var wander_speed:float = 60.0 # 游荡速度
@export var wander_distance:float = 150.0 # 单次游荡的距离
@export var wander_pause_min:float = 0.8 # 游荡停顿最短时间
@export var wander_pause_max:float = 2.0 # 游荡停顿最长时间
@export var charge_speed:float = 130.0 # 冲锋速度
@export var contact_damage:float = 10.0 # 撞击伤害
@export var bounce_distance:float = 40.0 # 撞击后最大惯性滑行距离
@export var bounce_speed:float = 240.0
@export var bounce_friction:float = 0.85
@export var bounce_min_speed:float = 20.0
@export var recovery_time:float = 0.6
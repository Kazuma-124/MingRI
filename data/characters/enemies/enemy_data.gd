extends Resource
class_name EnemyData

# @export_group("基本信息")

@export_group("基础属性")
@export var max_hp:float = 50.0

@export_group("移动属性")
# 游荡
@export var vision_radius:float = 200.0 # 视野范围半径
@export var wander_speed:float = 60.0 # 游荡速度
@export var wander_distance:float = 120.0 # 单次游荡的距离
@export var wander_pause_min:float = 0.8 # 游荡停顿最短时间
@export var wander_pause_max:float = 2.0 # 游荡停顿最长时间
# 冲锋攻击
@export var charge_speed:float = 140.0 # 冲锋速度
@export var contact_damage:float = 10.0 # 撞击伤害
@export var bounce_speed:float = 140.0
@export var bounce_friction:float = 0.85
@export var bounce_distance:float = 50.0 # 撞击后最大惯性滑行距离
@export var bounce_min_speed:float = 60.0
@export var recovery_time:float = 0.4

# 140初速度，0.85衰减
# 时间	速度	累计位移
# 0 s	140 px/s	0 px
# 0.5 s	129 px/s	67 px
# 1 s	119 px/s	130 px
# 2 s	101 px/s	241 px
# 3 s	85.8 px/s	335 px
# 5 s	61.7 px/s	483 px
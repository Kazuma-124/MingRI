extends Resource
class_name EnemyData

# @export_group("基本信息")

@export_group("基础属性")
@export var max_hp:float = 100.0

@export_group("移动属性")
@export var wander_speed:float = 60.0 # 游荡速度
@export var charge_speed:float = 120.0 # 冲锋速度
@export var wander_distance:float = 150.0 # 单次游荡的距离
@export var wander_pasuse_min:float = 0.8 # 游荡停顿最短时间
@export var wander_pasuse_max:float = 2.0 # 游荡停顿最长时间

@export_group("战斗属性")
@export var vision_radius:float = 250.0 # 视野范围半径
@export var contact_damage:float = 10.0 # 撞击伤害
@export var slide_distance:float = 80 # 撞击后惯性滑行距离
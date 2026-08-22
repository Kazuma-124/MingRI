extends SkillData
class_name SkillDataDirection

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

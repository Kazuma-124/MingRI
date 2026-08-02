extends Resource
class_name SkillData

@export_group("基础信息")
@export var id:StringName
@export var name:String
@export var icon:Texture2D
@export var scene:PackedScene

@export_group("数值")
@export var damage:float
@export var cooldown:float
@export var cast_range:float = 250
@export var flame_mp_cost:float

# ==================== 投射物专属 ====================
@export_group("投射物专属")
@export var fly_speed: float = 480.0


@export_group("bullet_flame")
@export var damage_range:float = 32 # 伤害范围，直径
@export_subgroup("子弹动画配置")
@export var anime_duration_time:float = 0.3
@export var bullet_diameter:float = 8 # 子弹直径（像素）
@export var explosion_diameter:float = 32 # 爆炸特效直径（像素）

extends Resource
class_name SkillData

@export_group("基础信息")
@export var id:StringName
@export var name:String

@export_group("数值")
@export var damage:float
@export var cooldown:float
@export var cast_range:float




# ==================== 投射物专属 ====================
@export_group("投射物专属")
@export var fly_speed: float = 400.0

# ==================== 资源关联 ====================
@export_group("资源关联")
#@export var effect_scene: PackedScene

@export_group("范围伤害")
@export var damage_range:float

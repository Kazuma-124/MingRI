extends Resource
class_name SkillData

# ==================== 基础信息 ====================
@export_group("基础信息")
@export var id: String = ""
@export var name: String = ""
@export var description: String = ""
@export var icon: Texture2D

# ==================== 属性与类型 ====================
@export_group("属性与类型")
@export var element: String = "flame"       # flame / life / frost / shadow
@export var skill_type: String = "projectile" # projectile / melee / aoe / buff
@export var custom_energy_cost:bool = false

# ==================== 数值配置 ====================
@export_group("数值配置")
@export var damage: float = 0.0
@export var cooldown: float = 2.0
@export var cast_range: float = 200.0
@export var energy_cost: float = 0.0
@export var unlock_level: int = 1

# ==================== 投射物专属 ====================
@export_group("投射物专属")
@export var fly_speed: float = 400.0
@export var max_range: float = 600.0

# ==================== 资源关联 ====================
@export_group("资源关联")
@export var effect_scene: PackedScene

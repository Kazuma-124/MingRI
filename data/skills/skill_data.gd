extends Resource
class_name SkillData

#region 枚举
enum SkillType{
	NORMAL,             # 普通技能
	PRIMARY_ATTACK,     # 普攻
	PASSIVE,            # 被动
}
enum TargetingType{
	INSTANT,            # 立即生效
	DIRECTION,          # 方向性技能
	POSITION,           # 位置性技能
	TARGET,             # 目标性技能
}
#endregion

#region export
@export_group("基础信息")
@export var id:StringName
@export var name:String
@export var skill_type:SkillType = SkillType.NORMAL
@export var targeting_type:TargetingType

@export_group("资源")
@export var icon:Texture2D
@export var scene:PackedScene
@export_group("能量属性相关")
@export var attribute_type:AttributeTypes.Type
@export var unlock_level:int
@export_group("数值")
@export var mp_cost:float
@export var damage:float
@export var cooldown:float
#endregion

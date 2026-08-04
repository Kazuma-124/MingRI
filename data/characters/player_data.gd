extends Resource
class_name PlayerData

@export_group("基础属性")
@export var max_hp:float = 100.0        # 1级时的最大生命
@export var max_mp:float = 1000.0       # 1级时的最大能量
@export var base_speed:float = 120.0    # 基础移动速度
@export_group("基础等级成长")
@export var hp_per_base_level:float = 100.0
@export var mp_per_base_level:float = 1000.0
@export var base_exp_required:float = 100.0 # 1->2级需要的经验
@export var exp_growth_factor:float = 1.5 # 每级所需经验增长系数
# 计算某级升到下一级所需经验
func get_exp_required_for_level(level:int)->int:
    return int(base_exp_required*pow(exp_growth_factor,level-1))
@export_group("能量转经验")
@export var energy_to_base_exp_ratio:float = 0.1 # 消耗10点能量=1点基础经验
@export var energy_to_attr_exp_ratio:float = 0.1 # 消耗10点属性能量=1点属性经验

@export_group("技能")
@export_subgroup("赤焰技能")
@export var default_skills:Array[SkillData] = []

@export_group("其它未分类")
@export var view_radius:float = 500.0
# @export var view_radius:float = 500.0
# @export var view_radius:float = 500.0
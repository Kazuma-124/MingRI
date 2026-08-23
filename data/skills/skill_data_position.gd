extends SkillData
class_name SkillDataPosition

# 位置类技能数据
# 玩家在事发范围内选择一个落点，技能在该位置生效
# 支持滚轮旋转形状朝向

#region 指示器配置
@export_group("指示器")
@export var indicator_shape:IndicatorShape
@export var indicator_color := Color(0,0.2,1.0,0.5)  # 处于合法施法范围内时指示器颜色
@export var invalid_color := Color(1,0.2,0.2,0.4)    # 处于非法范围时指示器的颜色
@export var cast_range:float                        # 最大施法距离（以玩家为中心的圆半径）
@export var allow_rotation:bool = true              # 是否允许滚轮旋转形状
@export var rotation_step:float = 15.0              # 每次滚轮旋转角度(角度值)
#endregion

func _init():
    targeting_type = TargetingType.POSITION

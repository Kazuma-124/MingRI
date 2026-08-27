extends RefCounted
class_name SkillInstance

#region 信号
signal cooldown_updated(ratio:float,remaining:float)
func emit_cooldown_updated(ratio,remaining)->void:
    cooldown_updated.emit(ratio,remaining)
#endregion


#region 成员变量
var data:SkillData
var current_cooldown:float
#endregion


#region 内置函数
# 声明周期
func _init(data_input:SkillData) -> void:
    data = data_input
    current_cooldown = 0
    # 准备阶段ui不一定已就绪，不需要发信号
#endregion



#region 冷却控制
func update_cooldown(delta:float)->void:
    if current_cooldown>0:
        current_cooldown = max(current_cooldown-delta,0.0)
        emit_cooldown_updated(get_cooldown_ratio(),current_cooldown)

func start_cooldown()->void:
    current_cooldown = data.cooldown
    emit_cooldown_updated(get_cooldown_ratio(),current_cooldown)

func get_max_cooldown()->float:
    return data.cooldown
#endregion


#region 查询
func get_cooldown_ratio()->float:
    if data.cooldown<=0:
        return 0.0
    return current_cooldown/data.cooldown
func get_remaining_cooldown()->float:
    return current_cooldown
#endregion

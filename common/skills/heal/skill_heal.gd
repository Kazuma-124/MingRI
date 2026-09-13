extends Node2D

# Target型单体治疗
# 立即回复HP+短暂持续回复效果
# 目标可为任意对象，敌人也可以治疗,目标无heal方法则跳过。

#region export
@export var initial_heal:float = 30.0
@export var hot_heap_per_tick:float =5.0
@export var hot_duration:float = 6.0
@export var hot_tick_interval:float = 0.5
#endregion

#region 成员变量
var _caster:CharacterBody2D = null
var _data:SkillDataTarget = null
#endregion

#region 外部接口
func setup(skill_data:SkillDataTarget,ctx:CastContext)->void:
    _data = skill_data
    _caster = ctx.caster
    var target:Node2D = ctx.target
    if target == null or not is_instance_valid(target):
        queue_free()
        return
    
    if target.has_method("heal"):
        target.heal(initial_heal)
    if target.has_method("add_buff"):
        target.add_buff(HealOverTimeBuff.new(hot_heap_per_tick,hot_duration,hot_tick_interval),_caster)
    queue_free()
#endregion
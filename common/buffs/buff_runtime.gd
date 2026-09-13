extends RefCounted
class_name BuffRuntime

# 运行时状态
var caster:Node = null
var remaining_time:float = 0.0
var stacks:int = 1
var tick_accumulator:float = 0.0
# var custom_state:Variant = null

func _init(p_base_duration:float,p_caster:Node=null)->void:
    remaining_time = p_base_duration
    caster = p_caster
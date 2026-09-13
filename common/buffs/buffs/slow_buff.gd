extends Buff
class_name SlowBuff

var _slow_effect:BuffModifierEffect
var _slow_percent:float = 0.0

func _init(p_slow_percent:float = 0.2,p_duration:float = 1.0,p_max_stacks:int = 3)->void:
    buff_id = &"slow"
    display_name = "减速"
    base_duration = p_duration
    max_stacks = p_max_stacks
    stack_policy_under = BuffEnums.StackPolicy.ADD_STACK_AND_REFRESH
    stack_policy_full = BuffEnums.StackPolicy.REFRESH_TIME

    _slow_percent = p_slow_percent
    var slow:=BuffModifierEffect.new()
    slow.effect_id = &"slow_speed_mod"
    slow.stat_name = StatusStats.MOVE_SPEED
    slow.calc_layer = BuffEnums.CalcLayer.PERCENT_ADD
    _add_effect(slow)
    _slow_effect = slow

func _sync_effects()->void:
    # apply, on_tick, on_stack_changed时会调用，同步更新最新状态
    _slow_effect.value = -_slow_percent*runtime.stacks
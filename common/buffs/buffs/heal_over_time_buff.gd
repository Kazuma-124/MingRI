extends Buff
class_name HealOverTimeBuff

func _init(p_heal_per_tick:float=5.0,p_duration:float=3.0,p_tick_interval:float=0.5)->void:
    buff_id=&"heal_over_time"
    display_name="持续恢复"
    base_duration = p_duration
    max_stacks = 1
    tick_interval = p_tick_interval
    stack_policy_under = BuffEnums.StackPolicy.REFRESH_TIME
    stack_policy_full = BuffEnums.StackPolicy.REFRESH_TIME

    var effect:=EffectHeal.new()
    effect.effect_id = &"heal_on_tick_effect"
    effect.triggers = BuffEnums.TriggerFlag.ON_TICK
    effect.heal_amount = p_heal_per_tick
    _add_effect(effect)

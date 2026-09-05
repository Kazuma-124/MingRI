extends BuffDefinition
class_name HealOverTimeBuffDefinition

func _init(p_heal_per_tick:float=5.0,p_duration:float=3.0,p_tick_interval:float=0.5)->void:
    buff_id = &"heal_over_time"
    display_name = "持续回复"
    base_duration = p_duration
    max_stacks = 1
    tick_interval = p_tick_interval
    stack_policy_under = BuffEnums.StackPolicy.REFRESH_TIME
    stack_policy_full = BuffEnums.StackPolicy.REFRESH_TIME

    # 当前buff_definition的on_tick时触发该effect
    var heal_on_tick_effect:=EffectHeal.new()
    heal_on_tick_effect.effect_id = &"heal_on_tick_effect"
    heal_on_tick_effect.apply_phase = BuffEnums.ApplyPhase.ON_TICK
    heal_on_tick_effect.heal_amount = p_heal_per_tick
    effects.append(heal_on_tick_effect)
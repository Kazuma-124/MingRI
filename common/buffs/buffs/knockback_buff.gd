extends Buff
class_name KnockbackBuff

var _control_frozen:bool = false

func _init(p_direction:Vector2,p_speed:float=400.0,p_duration:float=0.4)->void:
    buff_id = &"knockback"
    display_name = "击退"
    base_duration = p_duration
    max_stacks = 1
    stack_policy_under = BuffEnums.StackPolicy.OVERRIDE
    stack_policy_full = BuffEnums.StackPolicy.OVERRIDE

    # FORCED_VELOCITY, OVERRIDE, STAGGERED tag
    var kb:=EffectKnockback.new()
    kb.effect_id = &"knockback_effect"
    kb.value = p_direction.normalized()*p_speed
    _add_effect(kb)

func on_override_lost(_manager:BuffManager,stat:StringName)->void:
    if stat==StatusStats.FORCED_VELOCITY:
        _control_frozen = true
func on_override_gained(_manager:BuffManager,stat:StringName)->void:
    if stat==StatusStats.FORCED_VELOCITY:
        _control_frozen = false

func _does_time_pass()->bool:
    return true
func _does_tick_pass()->bool:
    return not _control_frozen
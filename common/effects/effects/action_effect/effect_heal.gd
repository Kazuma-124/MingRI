extends BuffActionEffect
class_name EffectHeal

var heal_amount:float = 0.0

func _build_action()->BuffAction:
    return HealAction.new(heal_amount)
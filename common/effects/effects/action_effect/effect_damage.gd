extends BuffActionEffect
class_name EffectDamage

var damage:float = 0.0

func _build_action()->BuffAction:
    return DamageAction.new(damage)
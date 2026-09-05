extends BuffEffectDefinition
class_name EffectPeriodicDamage

#region 配置
var damage: float = 0.0
var per_stack: bool = false
#endregion

#region 生命周期
func apply(instance: BuffInstance, manager: BuffManager) -> void:
	var final_damage: float = damage
	if per_stack:
		final_damage *= instance.stacks
	if manager.owner_character != null and manager.owner_character.has_method("take_damage"):
		manager.owner_character.take_damage(final_damage)

func remove(_instance: BuffInstance, _manager: BuffManager) -> void:
	pass
#endregion

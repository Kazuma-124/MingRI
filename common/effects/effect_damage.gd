extends BuffEffectDefinition
class_name EffectDamage

#region 配置
var damage: float = 0.0
var per_stack: bool = false
#endregion

#region 生命周期
func apply(instance: BuffInstance, manager: BuffManager) -> void:
	var final_damage: float = damage
	# 使用了该effect的buff可能叠层也可能只有一层
	# per_stack决定本effect是否会根据buff的层数重复效果
	if per_stack:
		final_damage *= instance.stacks
	if manager.owner_character != null and manager.owner_character.has_method("take_damage"):
		manager.owner_character.take_damage(final_damage)

func remove(_instance: BuffInstance, _manager: BuffManager) -> void:
	pass
#endregion

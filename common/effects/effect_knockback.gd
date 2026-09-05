extends BuffEffectDefinition
class_name EffectKnockback

#region 配置
var speed: float = 200.0
#endregion

#region 生命周期
func apply(instance: BuffInstance, manager: BuffManager) -> void:
	var dir: Vector2 = instance.get_dynamic_value(&"direction", Vector2.ZERO)
	if dir != Vector2.ZERO:
		manager.set_forced_velocity(dir.normalized() * speed)
	manager.add_tag(StatusTags.STAGGERED)

func remove(_instance: BuffInstance, manager: BuffManager) -> void:
	manager.set_forced_velocity(Vector2.ZERO)
	manager.remove_tag(StatusTags.STAGGERED)
#endregion

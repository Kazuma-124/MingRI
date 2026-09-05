extends BuffEffectDefinition
class_name EffectControl

#region 配置
var tags: Array[StringName] = []
#endregion

#region 生命周期
func apply(_instance: BuffInstance, manager: BuffManager) -> void:
	for tag in tags:
		manager.add_tag(tag)

func remove(_instance: BuffInstance, manager: BuffManager) -> void:
	for tag in tags:
		manager.remove_tag(tag)
#endregion

extends BuffEffect
class_name EffectControl

#region 配置
var tags: Array[StringName] = []
#endregion

#region 生命周期
func apply(_manager:BuffManager)->void:
    for tag in tags:
        _manager.add_tag(tag)
func remove(_manager:BuffManager)->void:
    for tag in tags:
        _manager.remove_tag(tag)
#endregion

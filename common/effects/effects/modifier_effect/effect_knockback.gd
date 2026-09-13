extends BuffModifierEffect
class_name EffectKnockback


func _init() -> void:
    stat_name = StatusStats.FORCED_VELOCITY
    calc_layer = BuffEnums.CalcLayer.OVERRIDE
    priority = 100

func apply(_manager:BuffManager)->void:
    super.apply(_manager)# 创建modifier，施加
    _manager.add_tag(StatusTags.STAGGERED)
func remove(_manager:BuffManager)->void:
    super.remove(_manager)# 移除modifier
    _manager.remove_tag(StatusTags.STAGGERED)

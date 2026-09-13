extends RefCounted
class_name BuffEffect

# 两类effect的基类

var source_buff_id:StringName = &""
var effect_id:StringName = &""

func apply(_manager:BuffManager)->void:
    pass
func remove(_manager:BuffManager)->void:
    pass

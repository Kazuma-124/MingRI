extends BuffEffect
class_name BuffModifierEffect

var stat_name:StringName=&""
var calc_layer:BuffEnums.CalcLayer = BuffEnums.CalcLayer.FLAT_ADD
var value:Variant = 0.0
var priority:int = 0

func apply(_manager:BuffManager)->void:
    var modifier:=_build_modifier()
    if modifier!=null:
        _manager.add_modifier(modifier)
func remove(_manager:BuffManager)->void:
    _manager.remove_modifiers_from_buff_effect(source_buff_id,effect_id)
# 状态对齐
func sync(manager:BuffManager)->void:
    remove(manager)
    apply(manager)


func _build_modifier()->BuffModifier:
    return BuffModifier.new(source_buff_id,effect_id,stat_name,calc_layer,value,priority)

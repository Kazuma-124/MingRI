extends BuffEffect
class_name BuffActionEffect

var triggers:int = BuffEnums.TriggerFlag.ON_APPLY

func apply(_manager:BuffManager)->void:
    var action:=_build_action()
    if action!=null:
        _manager.execute_action(action)
func remove(_manager:BuffManager)->void:
    pass

func trigger(manager:BuffManager,flag:int)->void:
    if triggers & flag:
        apply(manager)

func _build_action()->BuffAction:
    return null
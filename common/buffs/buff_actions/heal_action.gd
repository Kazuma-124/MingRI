extends BuffAction
class_name HealAction

var amount:float = 0.0

func _init(p_amount:float = 0.0)->void:
    amount = p_amount

func execute(target:Node,converter:AttributeConverter)->void:
    if target!=null and target.has_method("heal"):
        target.heal(converter.get_final_heal(amount))
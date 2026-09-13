extends BuffAction
class_name DamageAction

var amount:float = 0.0

func _init(p_amount:float = 0.0)->void:
    amount = p_amount

func execute(target:Node,converter:AttributeConverter)->void:
    if target!=null and target.has_method("take_damage"):
        target.take_damage(converter.get_final_damage(amount))
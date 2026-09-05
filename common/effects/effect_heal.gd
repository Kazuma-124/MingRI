extends BuffEffectDefinition
class_name EffectHeal

# 治疗

# 数值可被使用本effect的buff_definition自定义以定制需要的effect
var heal_amount:float = 0.0
var per_stack:bool = false

func apply(_instance: BuffInstance, _manager: BuffManager) -> void:
    var final_heal:float = heal_amount
    # 假如使用了当前effect的buff被施加了多层buff
    # per_stack决定是否每次都治疗一次
    if per_stack:
        final_heal*=_instance.stacks
    if _manager.owner_character!=null and _manager.owner_character.has_method("heal"):
        _manager.owner_character.heal(final_heal)

func remove(_instance: BuffInstance, _manager: BuffManager) -> void:
    pass
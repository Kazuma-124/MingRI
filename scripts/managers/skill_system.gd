extends Node

var skill_slots: Array[SkillBase] = []  # 技能槽位列表

# 施放指定槽位的技能
func cast_skill(slot_index: int, caster: Node) -> bool:
    if slot_index < 0 or slot_index >= skill_slots.size():
        return false
    return skill_slots[slot_index].cast(caster)

# 每帧更新所有技能冷却
func _process(delta: float) -> void:
    for skill in skill_slots:
        skill._process(delta)  # 或者技能自己挂到场景树上自动process

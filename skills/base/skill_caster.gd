extends Node
class_name SkillCaster

@export var player:CharacterBody2D
var state:PlayerSaveableState

func setup(player_ref:CharacterBody2D,state_ref:PlayerSaveableState)->void:
    player = player_ref
    state = state_ref

func caster_skill(skill_id:StringName)->bool:
    if not state.try_cast_skill(skill_id):
        return false
    # 能量已消耗，冷却计时已开启
    var skill_data = state.get_skill_data(skill_id)
    if not skill_data or not skill_data.scene:
        # 没有场景也算释放成功
        return true
    var skill_instances = skill_data.scene.instantiate()
    
    return true
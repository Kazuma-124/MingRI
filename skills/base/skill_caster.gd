extends Node
class_name SkillCaster

@export var player:CharacterBody2D
var state:PlayerSaveableState

func setup(player_ref:CharacterBody2D,state_ref:PlayerSaveableState)->void:
    player = player_ref
    state = state_ref


func cast_skill(skill_id:StringName)->bool:
    if not state.try_cast_skill(skill_id):
        return false
    # 能量已消耗，冷却计时已开启
    var skill_data = state.get_skill_data(skill_id)
    if not skill_data or not skill_data.scene:
        # 没有场景也算释放成功
        return true
    var skill_instances = skill_data.scene.instantiate()
    if skill_instances.has_method("setup"):
        skill_instances.setup(_build_cast_context())
    player.get_parent().add_child(skill_instances)
    return true

func cast_primary_skill()->bool:
    if state.primary_attack_skill_ids.size()==0:
        return false
    var primary_attack_id = state.curr_primary_attack_skill_id
    return cast_skill(primary_attack_id)

func _build_cast_context()->CastContext:
    var context = CastContext.new()
    context.caster = player
    context.caster_state = state
    context.caster_position = player.global_position
    context.cast_direction = (player.get_global_mouse_position()-player.global_position)
    context.mouse_position = player.get_global_mouse_position()
    return context
extends Node

#region 信号
signal player_initialized(player: CharacterBody2D)
#endregion

#region 成员变量
var current_player: CharacterBody2D = null
#endregion

#region 外部接口
func set_player(p: CharacterBody2D) -> void:
	current_player = p
	player_initialized.emit(p)

func get_player_skill_instance(skill_id:StringName)->SkillInstance:
	if current_player:
		return current_player.get_state().get_skill_instance(skill_id)
	return null
#endregion

extends RefCounted
class_name SkillInstance

var data:SkillData
var current_cooldown:float

func _init(data_input:SkillData) -> void:
    data = data_input
    current_cooldown = 0

func update_cooldown(delta:float)->void:
    if current_cooldown>0:
        current_cooldown-=delta
        if current_cooldown<0:
            current_cooldown=0

func start_cooldown()->void:
    current_cooldown = data.cooldown

func get_cooldown_ratio()->float:
    return current_cooldown/data.cooldown
func get_remaining_cooldown()->float:
    return current_cooldown
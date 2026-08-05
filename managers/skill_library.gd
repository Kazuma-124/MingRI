extends Node

var _all_skills:Dictionary = {
    # key:StringName id,value:SkillData
    
}

func _ready() -> void:
    _load_all_skills()

func _load_all_skills()->void:
    var dir = DirAccess.open("res://data/skills/")
    if dir:
        # 初始化流，该流可以通过get_next()逐个获取所有文件和目录
        dir.list_dir_begin()
        var file_name = dir.get_next()
        while file_name!="":
            if file_name.ends_with("tres"):
                var skill = load("res://data/skills/"+file_name) as SkillData
                if skill:
                    _all_skills[skill.id] = skill
            file_name = dir.get_next()
        dir.list_dir_end()

func get_skill(id:StringName)->SkillData:
    return _all_skills.get(id,null)

extends Buff
class_name RootBuff

# 定身：贡献 ROOTED 标签，翻译层将速度清零，不冻结攻击/施法

func update(delta:float,manager:StatusManager)->bool:
	manager.add_tag(StatusTags.ROOTED)
	return super.update(delta,manager)

func _init(root_duration:float)->void:
	duration = root_duration


extends RefCounted
class_name SkillLogicBase

## 无状态技能逻辑基类
## 所有具体技能逻辑继承此类，重写 execute() 方法
## 全局只创建一份实例，不保存任何运行时状态
func execute(caster: EntityBase, data: SkillData) -> void:
    push_warning("技能逻辑未实现: %s" % data.id)

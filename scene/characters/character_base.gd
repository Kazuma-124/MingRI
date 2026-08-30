extends CharacterBody2D
class_name CharacterBase

#region 成员
var _effects:Array[StatusEffect]=[]
var external_velocity:Vector2 = Vector2.ZERO # 状态施加的速度
#endregion


#region 外部接口
func add_effect(effect:StatusEffect)->void:
    effect.apply(self) # 将效果施加到自身身上
    _effects.append(effect)
#endregion


#region 内部函数
func _ready()->void:
    motion_mode = MotionMode.MOTION_MODE_FLOATING;

func _update_effects(delta:float)->void:
    external_velocity = Vector2.ZERO
    for i in range(_effects.size()-1,-1,-1):# 反向遍历，可以安全地在遍历途中移除元素
        # updatae获取本轮时间内的状态效果，更新状态时间,若下一轮状态失效则移除
        if not _effects[i].update(delta):
            _effects[i].remove()
            _effects.remove_at(i) # 将后面的元素全部前移一位
#endregion
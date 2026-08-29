# cast_context.gd
extends RefCounted
class_name CastContext
# 释放者
var caster: Node2D

var direction:Vector2 = Vector2.ZERO # 施法方向
var position:Vector2 = Vector2.ZERO # 施法位置
var target:Node2D=null# 施法目标
var shape_rotation:float = 0.0 # POSITION型的形状旋转弧度, 单位为弧度
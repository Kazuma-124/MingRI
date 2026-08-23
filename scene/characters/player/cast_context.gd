# cast_context.gd
extends RefCounted
class_name CastContext
# 释放者
var caster: Node2D

var direction:Vector2 # 施法方向
var position:Vector2  # 施法位置
var target:Node2D=null# 施法目标
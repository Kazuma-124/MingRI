# cast_context.gd
extends RefCounted
class_name CastContext

# 释放者
var caster: Node2D
var caster_state: PlayerSaveableState

# 位置/方向
var caster_position: Vector2
var cast_direction: Vector2

# 目标（可能为空，比如火球术不需要目标）
var target: Node2D = null
var target_position: Vector2 = Vector2.ZERO

# 鼠标位置（指向类技能用）
var mouse_position: Vector2

# 以后可以加：施法等级、暴击率、伤害加成等
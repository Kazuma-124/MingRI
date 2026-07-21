extends CharacterBody2D
class_name Player


# ==================== 状态变量 ====================
var is_dead:bool = false
var is_hurt:bool = false# 受击中

var is_attacking:bool = false
var is_casting:bool = false #施法中

# 移动速度
@export var move_speed:float = 120.0

# 朝向后缀：up / down / left / right
var facing_suffix: StringName = &"down"

func _physics_process(delta: float) -> void:
	if is_dead:
		return
		
	if is_hurt:
		pass
	
	if is_casting:
		velocity = Vector2.ZERO
		move_and_slide()

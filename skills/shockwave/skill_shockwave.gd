extends Node2D

#region export
@export var damage_radius:float = 80.0
@export var knockback_distance:float = 80
@export var effect_duration:float = 0.4
@export var ring_width:float = 3.0
#endregion

#region 成员变量
var _caster:CharacterBody2D = null
var _data:SkillDataInstant
var _skill_progress:float = 0.0 # 技能特效播放进度，1=播放结束
var _hit_bodies:Array[Node2D] = []
#endregion

#region 外部接口
func setup(skill_data:SkillDataInstant,ctx:CastContext)->void:
	_data = skill_data
	global_position = ctx.caster.global_position
	_caster = ctx.caster
#endregion

#region 生命周期
func _process(delta: float) -> void:
	if _skill_progress >= 1.0:
		queue_free()
	_skill_progress = min(_skill_progress+delta/effect_duration,1.0)
	_check_hits()
	queue_redraw()

func _draw() -> void:
	var radius := damage_radius*_skill_progress
	var color = GameColors.SHOCKWAVE_ANIME
	color.a =0.9*(1.0-_skill_progress)# 透明度
	draw_circle(Vector2.ZERO,radius,color,false,ring_width,true)
#endregion

#region 内部函数
func _check_hits()->void:
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = CircleShape2D.new()
	query.shape.radius = damage_radius
	# 把查询形状放到世界空间，(旋转，位置)
	query.transform = Transform2D(0,global_position)
	query.collide_with_bodies = true

	var results := get_world_2d().direct_space_state.intersect_shape(query)
	for result in results:
		var body:Node2D = result.collider
		if body == _caster or _hit_bodies.has(body):
			continue
		if body.has_method("take_damage"):
			body.take_damage(_data.damage)
		var dir:=(body.global_position-global_position).normalized()
		body.add_effect(KnockbackEffect.new(dir,knockback_distance))
		_hit_bodies.append(body)
#endregion

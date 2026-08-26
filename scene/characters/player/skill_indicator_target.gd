extends SkillIndicator
class_name SkillIndicatorTarget

#region 属性
var _skill_data:SkillDataTarget = null
var _caster:Node2D = null
var _hovered_target:Node2D = null
var _is_valid:bool = false
#endregion

#region 接口
func setup(skill_data:SkillData,caster:Node2D)->void:
    _skill_data = skill_data as SkillDataTarget
    _caster = caster
    z_index = 10
    # 初始位置设在施法者出，后面跟随鼠标位置
    global_position = caster.global_position

func generate_castcontext()->CastContext:
    var ctx:=CastContext.new()
    ctx.target = _hovered_target
    if _hovered_target:
        ctx.position = _hovered_target.global_position
        ctx.direction = (_hovered_target.global_position-_caster.global_position).normalized()
    return ctx

func get_is_valid()->bool:
    return _is_valid and _hovered_target!=null

func get_aim_direction()->Vector2:
    if _hovered_target and is_instance_valid(_hovered_target):
        return (_hovered_target.global_position-_caster.global_position).normalized()
    return Vector2.ZERO
#endregion

#region 内部函数
func _process(_delta:float)->void:
    if not _skill_data or not _caster:
        return
    var mouse_pos := get_global_mouse_position()
    global_position = mouse_pos
    # 把鼠标位置的情况更新给_horvered_target，
    _hovered_target = _find_target_at(mouse_pos)
    _is_valid = _caster.global_position.distance_to(mouse_pos)<=_skill_data.cast_range
    queue_redraw()

func _find_target_at(mouse_pos:Vector2)->Node2D:
    var space_state:=get_world_2d().direct_space_state
    var query := PhysicsShapeQueryParameters2D.new()
    query.shape = CircleShape2D.new()
    query.shape.radius = _skill_data.select_tolerance
    query.transform = Transform2D(0,mouse_pos)
    query.collide_with_bodies = true
    query.collision_mask = 2 # Entity层
    var results := space_state.intersect_shape(query)
    var nearest:Node2D = null
    var nearest_dist:float = INF
    for result in results:
        var body:Node2D =  result.collider
        if body.is_in_group("enemy") and is_instance_valid(body):
            var dist:=body.global_position.distance_to(mouse_pos)
            if dist <  nearest_dist:
                nearest_dist = dist
                nearest = body
    if _skill_data.can_target_self and nearest==null:
        if _caster.global_position.distance_to(mouse_pos)<=_skill_data.select_tolerance:
            nearest = _caster
    return nearest

func _draw() -> void:
    if not _skill_data:
        return
    var color := _skill_data.indicator_color if _is_valid else _skill_data.invalid_color
    # 鼠标位置小圆点(圆心在局部位置的坐标,半径,颜色,filed是否填充,线宽,是否抗锯齿)
    draw_circle(Vector2.ZERO,_skill_data.cursor_radius,color,true,-1.0,true)
    # 放在对象上面时，画一个圈
    if _is_valid and _hovered_target and is_instance_valid(_hovered_target):
        var target_local := _hovered_target.global_position-global_position
        draw_circle(target_local,_skill_data.highlight_radius,color,false,2.0,true)
#endregion
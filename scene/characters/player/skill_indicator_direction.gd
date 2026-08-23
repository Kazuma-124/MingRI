extends SkillIndicator
class_name SkillIndicatorDirection

#region 运行时状态
var _skill_data:SkillDataDirection = null
var _direction:Vector2 = Vector2.RIGHT
var _color:Color = Color(0.75, 0.85, 1.0, 0.35)
#endregion


#region 接口实现
func setup(skill_data:SkillData, caster:Node2D)->void:
    _skill_data = skill_data as SkillDataDirection
    global_position = caster.global_position
    # z_index会影响结点的绘制顺序，越大越优先
    z_index = 10
    # 加入重绘队列
    queue_redraw()

func update_aim(mouse_world:Vector2)->CastContext:
    _direction = (mouse_world - global_position).normalized()
    if _direction == Vector2.ZERO:
        _direction = Vector2.RIGHT
    rotation = _direction.angle()
    queue_redraw()

    var ctx := CastContext.new()
    ctx.direction = _direction
    ctx.position = global_position
    return ctx

func get_is_valid()->bool:
    return _skill_data!=null
#endregion

#region 绘制
func _draw()->void:
    if not _skill_data:
        return
    match _skill_data.indicator_shape:
        SkillDataDirection.IndicatorShape.RECTANGLE:
            _draw_rectangle()
        SkillDataDirection.IndicatorShape.SECTOR:
            _draw_sector()
        SkillDataDirection.IndicatorShape.NONE:
            _draw_direction_line()

func _draw_rectangle()->void:
    var length:float = _skill_data.indicator_length
    var half_w:float = _skill_data.indicator_width/2.0

    draw_colored_polygon(
        PackedVector2Array([
            Vector2(0,-half_w),
            Vector2(length,-half_w),
            Vector2(length,half_w),
            Vector2(0,half_w)
        ]),
        _color
    )
func _draw_sector()->void:
    var radius:float = _skill_data.indicator_length
    var angle_rad:float = deg_to_rad(_skill_data.indicator_angle)
    var segments:int = 16  # 圆弧分段数，越大越平滑

    # 使用绘制多边形的方法绘制扇形
    var points := PackedVector2Array()
    points.append(Vector2.ZERO) # 先把多边形的圆心放进去，圆心是玩家位置
    for i in range(segments+1):
        var t:float = float(i)/float(segments)

        # 从 -angle/2 到 +angle/2，中心朝+X方向
        var a:float = -angle_rad/2.0+t*angle_rad
        points.append(Vector2(cos(a),sin(a))*radius)
    draw_colored_polygon(points,_color)

func _draw_direction_line()->void:
    # NONE类型，画一条端方向线
    var line_length:float = 48.0
    draw_line(Vector2.ZERO,Vector2(line_length,0),_color,2.0)

#endregion

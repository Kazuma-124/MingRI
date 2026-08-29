extends SkillIndicator
class_name SkillIndicatorDirection

#region 运行时状态
var _skill_data:SkillDataDirection = null
var _caster:Node2D
#endregion



#region 接口实现
func setup(skill_data:SkillData, caster:Node2D)->void:
    _skill_data = skill_data as SkillDataDirection
    _caster = caster
    # z_index会影响结点的绘制顺序，越大越优先
    z_index = 10
    # 加入重绘队列
    queue_redraw()

func generate_castcontext()->CastContext:
    var ctx := CastContext.new()
    ctx.direction = (get_global_mouse_position()-_caster.global_position).normalized()
    return ctx

func get_is_valid()->bool:
    return _skill_data!=null

func get_aim_direction()->Vector2:
    return (get_global_mouse_position()-_caster.global_position).normalized()
#endregion


#region 内部函数
func _process(_delta: float) -> void:
    if not _skill_data:
        return
    var mouse_pos:Vector2 = get_global_mouse_position()
    var new_dir = (mouse_pos-global_position).normalized()
    if new_dir!=Vector2.ZERO:
        rotation = new_dir.angle()
    queue_redraw()
#endregion

#region 绘制
func _draw()->void:
    # 飞行距离圈
    if _skill_data and _skill_data.show_fly_range and _skill_data.fly_distance>0:
        draw_circle(Vector2.ZERO,_skill_data.fly_distance,Color(1,1,1,0.25),false,1.5,true)
    if not _skill_data:
        return
    if _skill_data.indicator_shape:
        _skill_data.indicator_shape.draw(self,_skill_data.indicator_color)
    else:
        var line_length:=48.0
        draw_line(Vector2.ZERO,Vector2(line_length,0),_skill_data.indicator_color,2.0)
#endregion

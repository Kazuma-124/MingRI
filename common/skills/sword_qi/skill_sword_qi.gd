extends Node2D

# 剑气斩，扇形近战瞬发
# DIRECTION型，无飞行物

#region export
@export var effect_duration:float = 0.2 # 动画持续时间
@export var slice_count:int = 16     # 切分数(挥砍段数)
@export var sword_width: float = 5.0         # 剑刃根部宽度
#endregion


#region 成员变量
var _data:SkillDataDirection
var _caster:Node2D
var _direction:Vector2 = Vector2.RIGHT
var _elapsed:float = 0.0
var _current_slice:int = 0
var _hit_rangle_rad:float = 0
var _slice_polygons:Array[PackedVector2Array] = []
var _hited_bodies:Array[Node2D] = []
#endregion


#region 外部接口
func setup(skill_data:SkillData,ctx:CastContext)->void:
    _data = skill_data
    _caster = ctx.caster
    _direction = ctx.direction
    global_position = _caster.global_position
    rotation = _direction.angle()
    _hit_rangle_rad = deg_to_rad(_data.indicator_shape.angle_deg)
#endregion


#region 生命周期
func _process(delta: float) -> void:
    _elapsed += delta

    while _current_slice<slice_count && effect_duration*float(_current_slice+1)/slice_count < _elapsed:
        # 还有可画的切片且下一个切片已经可以绘制了
        _current_slice+=1
        # 准备下一个切片多边形的points
        var slice_poly = _generate_slice_polygon(_current_slice)
        _slice_polygons.append(slice_poly)
        _apply_damage_in_slice(slice_poly)
    queue_redraw()

    if _elapsed >= effect_duration:
        queue_free()

func _draw() -> void:
    for i in range(_current_slice):
        var color := GameColors.SWORD_QI
        # 调整透明度
        color.a = 0.9*(i+1)/_current_slice
        draw_colored_polygon(_slice_polygons[i],color)
    # 剑刃
    if _current_slice>0:
        _draw_sword_blade()

#endregion


#region 内部函数
func _generate_slice_polygon(i:int)->PackedVector2Array:
    var radius:float = _data.indicator_shape.radius
    var points:=PackedVector2Array()
    points.append(Vector2.ZERO)# 圆心
    var t0 := float(i-1)/float(slice_count) - 0.5
    var a0 := t0*_hit_rangle_rad
    points.append(Vector2(cos(a0),sin(a0))*radius)
    var t1 := float(i)/float(slice_count) - 0.5
    var a1 := t1*_hit_rangle_rad
    points.append(Vector2(cos(a1),sin(a1))*radius)
    return points

func _apply_damage_in_slice(points:PackedVector2Array)->void:
    var query := PhysicsShapeQueryParameters2D.new()
    query.shape = ConvexPolygonShape2D.new()
    query.shape.points = points
    # transform2D的第一个参数是形状的旋转，与自身的rotation保持一致
    query.transform = Transform2D(rotation,global_position)
    query.collide_with_bodies = true
    query.collision_mask = 2 # Entity层

    var results:=get_world_2d().direct_space_state.intersect_shape(query)

    for result in results:
        var body:Node2D = result.collider
        if body == _caster or _hited_bodies.has(body):
            continue
        if body.has_method("take_damage"):
            body.take_damage(_data.damage)
        _hited_bodies.append(body)

func _draw_sword_blade()->void:
    var radius:float = _data.indicator_shape.radius
    # 第一个-0.5是把位置定在最新的扇形切片的中心，第二个-0.5是将完整扇形转动一般保持中间正对朝向
    var t_center:=(float(_current_slice)-0.5)/float(slice_count)-0.5
    var center_angle := t_center*_hit_rangle_rad

    var blade_length := radius*0.75 # 剑身长度
    var tip_length := radius-blade_length # 剑尖长度
    var hilt_half := sword_width/2.0    # 剑身半宽

    # 方向
    var forward:=Vector2(cos(center_angle),sin(center_angle)) # 剑指向方向
    var right:=Vector2(-sin(center_angle),cos(center_angle)) # 垂直剑身，朝右

    # 剑多边形
    var p1 := right*hilt_half
    var p2 := right*hilt_half + forward*blade_length
    var p3 := forward*(blade_length+tip_length)
    var p4 := -right*hilt_half + forward*blade_length
    var p5 := -right*hilt_half
    draw_colored_polygon(PackedVector2Array([p1,p2,p3,p4,p5]),GameColors.SWORD_QI_SWORD_BLADE)
    draw_line(Vector2.ZERO,forward*blade_length,GameColors.SWORD_QI_SWORD_BLADE,2.0,true)
#endregion
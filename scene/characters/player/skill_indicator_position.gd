extends SkillIndicator
class_name SkillIndicatorPosition

# 位置类技能指示器
# 跟随鼠标位置，clamp 在以玩家为中心的cast_range圆内
# 滚轮可旋转形状朝向(skill_data里配置allot_rotation=true)
# 超出释放范围时形状变红色且 get_is_valid() 返回false

#region 运行时状态
var _skill_data:SkillDataPosition = null
var _caster:Node2D = null
var _is_valid:bool = true
#endregion

#region 外部接口
func setup(skill_data:SkillData,caster:Node2D)->void:
    _skill_data = skill_data as SkillDataPosition
    _caster = caster
    # 指示器属于 UI 引导层，z_index 高于所有游戏对象（默认 0），确保不被遮挡
    z_index = 10
    # 初始位置设在玩家处
    global_position = caster.global_position
func generate_castcontext()->CastContext:
    var ctx:=CastContext.new()
    ctx.position = global_position
    # 形状朝向，滚轮旋转后的朝向
    ctx.shape_rotation = rotation   # 单位为弧度
    return ctx
func get_is_valid()->bool:
    return _is_valid and _skill_data!=null
#endregion

#region 内部函数
func _process(_delta:float)->void:
    if not _skill_data or not _caster:
        return
    
    # 跟随鼠标，clamp到以玩家为中心的cast_range圈内
    var mouse_pos:=get_global_mouse_position()
    var caster_pos:=_caster.global_position
    var offset := mouse_pos-caster_pos
    var max_dist := _skill_data.cast_range
    if max_dist>0.0 and offset.length()>max_dist:
        offset = offset.limit_length(max_dist)
        _is_valid = false
    else:
        _is_valid = true
    global_position = caster_pos+offset
    queue_redraw()

# 滚轮旋转
func _unhandled_input(event: InputEvent) -> void:
    if not _skill_data or not _skill_data.allow_rotation:
        return
    if event is InputEventMouseButton and event.pressed:
        match event.button_index:
            MOUSE_BUTTON_WHEEL_UP:
                rotation += deg_to_rad(_skill_data.rotation_step)
                get_viewport().set_input_as_handled()
            MOUSE_BUTTON_WHEEL_DOWN:
                rotation -= deg_to_rad(_skill_data.rotation_step)
                get_viewport().set_input_as_handled()

func _draw() -> void:
    # 施法范围圈，以施法者为中心，先画在底层
    if _skill_data:
        var caster_local := _caster.global_position-global_position
        draw_circle(caster_local,_skill_data.cast_range,GameColors.INDICATOR_RANGE_CIRCLE,false,1.5,true)

    if not _skill_data or not _skill_data.indicator_shape:
        return
    var color := _skill_data.indicator_color
    if not _is_valid:
        color = _skill_data.invalid_color
    _skill_data.indicator_shape.draw(self,color)
#endregion
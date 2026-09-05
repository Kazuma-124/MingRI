extends Node2D

# POSITION型持续地面AOE：在落点生成持续3秒的冰霜区域
# 每0.5秒对范围内敌人造成伤害+减速
# 领域半径从 indicator_shape.radius 读取（指示器作为唯一数据源）

#region export
@export var effect_duration: float = 4.0      # 领域持续时间
@export var tick_interval: float = 0.5        # 伤害间隔
@export var slow_factor: float = 0.8          # 减速乘率（0.8=速度变为80%）
@export var slow_duration: float = 1.0         # 减速持续时间
@export var border_min_width: float = 2.0      # 边缘最小宽度
@export var border_max_width: float = 4.0      # 边缘最大宽度
#endregion

#region 成员变量
var _caster: CharacterBody2D = null
var _data: SkillDataPosition = null
var _field_radius: float = 0.0                 # 领域半径，setup时从indicator_shape读取
var _elapsed: float = 0.0                       # 领域已存在时间
var _tick_elapsed: float = 0.0                  # 距上次伤害tick的时间
var _current_tick_hits: Array[Node2D] = []     # 当前tick已命中的敌人（防同一次查询重复）
#endregion

#region 外部接口
func setup(skill_data: SkillDataPosition, ctx: CastContext) -> void:
    _data = skill_data
    _caster = ctx.caster
    global_position = ctx.position
    # 从指示器形状读取领域半径，避免参数双份同步
    if _data.indicator_shape is CircleIndicatorShape:
        _field_radius = (_data.indicator_shape as CircleIndicatorShape).radius
    else:
        _field_radius = 80.0  # fallback
#endregion

#region 生命周期
func _process(delta: float) -> void:
    if _elapsed >= effect_duration:
        queue_free()
        return
    _elapsed += delta
    # 伤害tick
    _tick_elapsed += delta
    var is_damage_tick := false
    if _tick_elapsed >= tick_interval:
        _tick_elapsed -= tick_interval
        _current_tick_hits.clear()
        is_damage_tick = true
    _check_hits(is_damage_tick)
    queue_redraw()

func _draw() -> void:
    var progress:float = abs(cos(PI*(_tick_elapsed/tick_interval)))
    # 半透明填充
    var fill_color := GameColors.FROST_FIELD
    fill_color.a = 0.3+progress*0.5
    draw_circle(Vector2.ZERO, _field_radius, fill_color, true)
    # 脉动边缘
    var pulse := 0.5 + progress*0.5
    var border_width := lerpf(border_min_width, border_max_width, pulse)
    var border_color := GameColors.FROST_FIELD
    border_color.a = 0.8
    draw_circle(Vector2.ZERO, _field_radius, border_color, false, border_width, true)
#endregion

#region 内部函数
func _check_hits(is_damage_tick: bool) -> void:
    var query := PhysicsShapeQueryParameters2D.new()
    query.shape = CircleShape2D.new()
    query.shape.radius = _field_radius
    query.transform = Transform2D(0, global_position)
    query.collide_with_bodies = true

    var results := get_world_2d().direct_space_state.intersect_shape(query)
    for result in results:
        var body: Node2D = result.collider
        # 减速：每帧施加，buff 系统的叠加策略自动处理刷新/加层
        body.add_buff(SlowBuffDefinition.new(1.0 - slow_factor, slow_duration, 3), _caster, {})
        if is_damage_tick and not _current_tick_hits.has(body):
            if body.has_method("take_damage"):
                body.take_damage(_data.damage)
            _current_tick_hits.append(body)
#endregion


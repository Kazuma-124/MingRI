extends CharacterBody2D

# 状态枚举
enum STATE{
    WANDER,
    WANDER_PAUSE,
    CHARGE,
    SLIDE
}

@export var data:EnemyData


var cur_hp:float
var target:CharacterBody2D = null # 当前追击目标
var current_state:STATE
var move_dir:Vector2 = Vector2.RIGHT

var state_timer:float = 0.0
var slide_remaining:float = 0.0 # 剩余滑行距离

@onready var vision_area: Area2D = $VisionArea
@onready var vision_collision_shape: CollisionShape2D = $VisionArea/VisionCollisionShape

func _ready() -> void:
    cur_hp = data.max_hp

    # 视野半径和信号设置
    vision_collision_shape.shape.radius = data.vision_radius
    # vision_area.body_entered.connect(_on_body_enter_vision)
    # vision_area.body_exited.connect(_on_body_exit_vision)

    # 初始状态，游荡
    _switch_state(STATE.WANDER_PAUSE)

func _physics_process(delta: float) -> void:
    if cur_hp <= 0:
        queue_free()
        return
    match current_state:
        STATE.WANDER:
            _update_wander(delta)
        STATE.WANDER_PAUSE:
            _update_wander_pause(delta)
        STATE.CHARGE:
            _update_charge(delta)
        STATE.SLIDE:
            _update_slide(delta)
    move_and_slide()
    # 检测撞击目标
    _check_contact_damage()

func take_damage(damage:float)->void:
    cur_hp-=damage


func _switch_state(new_state:STATE)->void:
    current_state = new_state
    match current_state:
        STATE.WANDER:
            # 向随机方向游荡
            move_dir = Vector2(randf_range(-1,1),randf_range(-1,1)).normalized()
            state_timer = data.wander_distance/data.wander_speed
            velocity = move_dir*data.wander_speed
        STATE.WANDER_PAUSE:
            velocity = Vector2.ZERO
            state_timer = randf_range(data.wander_pause_min,data.wander_pause_max)
        STATE.CHARGE:
            # 冲向目标
            _update_charge_direction()
            velocity = move_dir*data.charge_speed
        STATE.SLIDE:
            slide_remaining = data.max_slide_distance
            velocity = move_dir*data.charge_speed

# ============= 各状态逻辑,接收时间
func _update_wander(delta:float)->void:
    state_timer -= delta
    if state_timer<=0:
        _switch_state(STATE.WANDER_PAUSE)

func _update_wander_pause(delta:float)->void:
    state_timer-=delta
    if state_timer<=0:
        _switch_state(STATE.WANDER)

func _update_charge(delta:float)->void:
    # 检查目标是否有效
    if not is_instance_valid(target):
        target = null
        _switch_state(STATE.WANDER)
        return
    
    # 朝向实时追踪目标
    _update_charge_direction()
    velocity = move_dir*data.charge_speed

func _update_slide(delta:float)->void:
    # 速度按摩擦系数衰减
    velocity*=data.slide_friction
    # 本帧移动距离
    var move_this_frame = velocity.length()*delta
    slide_remaining -= move_this_frame

    if velocity.length()<=data.slide_min_speed or slide_remaining<=0:
        if target:
            _switch_state(STATE.CHARGE)
        else:
            _switch_state(STATE.WANDER)

# 物体进入视野
func _on_body_enter_vision(body:Node)->void:
    if body.is_in_group("player") and target == null:
        target = body
        _switch_state(STATE.CHARGE)

# 目标离开视野
func _on_body_exit_vision(body:Node)->void:
    if body == target:
        target = null
        _switch_state(STATE.WANDER)

# =========== 工具函数

func _update_charge_direction()->void:
    if not target:
        return
    move_dir = (target.global_position-global_position).normalized()


func _check_contact_damage()->void:
    if current_state!=STATE.CHARGE:
        return
    
    # 记录本次移动是否发生有效撞击
    var hit_occurred = false
    # get_slide_collision_count()最近一次调用move_and_slide()时发生碰撞并改变方向的次数
    for i in get_slide_collision_count():
        # 获取碰撞信息,可能发生多次碰撞，用i指定获取哪次
        var collision = get_slide_collision(i)
        # 返回射线相交的第一个物体
        var collider = collision.get_collider()
        if collider.has_method("take_damage"):
            collider.take_damage(data.contact_damage)
        # 碰撞点的发现，垂直于碰撞表面，从被碰撞体指向我方,通常会与自己的移动方向夹角大于90度
        var hit_normal = collision.get_normal()
        # 将法线反转，变成从我方指向被撞物体，接着点积，判断此次碰撞是否是正面撞击，是否要进入滑行模式
        var dot = move_dir.dot(-hit_normal)
        if dot>0.5:
            hit_occurred = true
    if hit_occurred:
        _switch_state(STATE.SLIDE)
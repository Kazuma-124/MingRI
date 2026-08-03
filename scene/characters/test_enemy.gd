extends CharacterBase

# ========== 大状态（组） ==========
enum SUPER_STATE {
    IDLE,       # 游荡组：WANDER + WANDER_PAUSE
    COMBAT,     # 战斗组：CHARGE + BOUNCE + RECOVERY
    RETURNING   # 返回组：RETURN_HOME
}

# ========== 子状态
enum SUB_STATE {
    # IDLE 组的子状态
    WANDER,
    WANDER_PAUSE,
    # COMBAT 组的子状态
    CHARGE,
    BOUNCE,
    RECOVERY,
    # RETURNING 组的子状态（只有一个）
    RETURN_HOME
}

# ========== 当前状态
var current_super_state: SUPER_STATE
var current_sub_state: SUB_STATE


@export var data:EnemyData


var home_position:Vector2
var home_radius:float
var cur_hp:float
var target:CharacterBody2D = null # 当前追击目标
var move_dir:Vector2 = Vector2.RIGHT

var state_timer:float = 0.0
var bounce_dir:Vector2
var bounce_remaining:float = 0.0 # 剩余滑行距离
var curr_bounce_speed:float

@onready var vision_area: Area2D = $VisionArea
@onready var vision_collision_shape: CollisionShape2D = $VisionArea/VisionCollisionShape

func _ready() -> void:
    super._ready()
    cur_hp = data.max_hp

    # 视野半径和信号设置
    vision_collision_shape.shape.radius = data.vision_radius
    vision_area.body_entered.connect(_on_body_enter_vision)
    vision_area.body_exited.connect(_on_body_exit_vision)

    home_position = Vector2.ZERO
    home_radius = 200
    _switch_super_state(SUPER_STATE.IDLE)

func _physics_process(delta: float) -> void:
    if cur_hp <= 0:
        queue_free()
        return
    
    # 第一步：执行当前大状态的公共逻辑
    # （可能会触发大状态切换）
    _update_super_state(delta)
    
    move_and_slide()
    # 游荡中碰撞或冲锋中碰撞不同需要分别处理==============
    # _check_contact_damage()

func take_damage(damage:float)->void:
    cur_hp-=damage

func _update_super_state(delta: float) -> void:
    match current_super_state:
        SUPER_STATE.IDLE:
            _update_idle_super(delta)
        SUPER_STATE.COMBAT:
            _update_combat_super(delta)
        SUPER_STATE.RETURNING:
            _update_returning_super(delta)

func _update_idle_super(delta:float)->void:
    # 如果离开领地则返回
    if global_position.distance_to(home_position)>home_radius:
        _switch_super_state(SUPER_STATE.RETURNING)
        return
    # 如果发现玩家则进入战斗
    if is_instance_valid(target):
        _switch_super_state(SUPER_STATE.COMBAT)
        return
    _update_idle_sub(delta)

func _update_combat_super(delta:float)->void:
    # 追出领地则放弃追击，回家
    if global_position.distance_to(home_position)>home_radius:
        target = null
        _switch_super_state(SUPER_STATE.RETURNING)
        return
    # 目标丢失
    if not is_instance_valid(target):
        target = null
        _switch_super_state(SUPER_STATE.IDLE)
        return
    _update_combat_sub(delta)
    
func _update_returning_super(delta:float)->void:
    if global_position.distance_to(home_position)<(home_radius/2):
        _switch_super_state(SUPER_STATE.IDLE)
        return
    _update_returning_sub(delta)

func _update_idle_sub(delta)->void:
    match current_sub_state:
        SUB_STATE.WANDER:
            _update_wander(delta)
        SUB_STATE.WANDER_PAUSE:
            _update_wander_pause(delta)
        _:
            push_warning("super state idle has wrong sub state when update: ",current_sub_state)

func _update_combat_sub(delta)->void:
    match current_sub_state:
        SUB_STATE.CHARGE:
            _update_charge(delta)
        SUB_STATE.BOUNCE:
            _update_bounce(delta)
        SUB_STATE.RECOVERY:
            _update_recovery(delta)
        _:
            push_warning("super state combat has wrong sub state when update: ",current_sub_state)
func _update_returning_sub(delta)->void:
    match current_sub_state:
        SUB_STATE.RETURN_HOME:
            _update_return_home(delta)
        _:
            push_warning("super state returning has wrong sub state when update: ",current_sub_state)

# ============= 各状态逻辑,接收时间
func _update_wander(delta:float)->void:
    # 维持速度，以防移动过程中velocity被改变
    velocity = move_dir*data.wander_speed
    state_timer -= delta
    if state_timer<=0:
        _switch_sub_state_idle(SUB_STATE.WANDER_PAUSE)

func _update_wander_pause(delta:float)->void:
    state_timer-=delta
    if state_timer<=0:
        _switch_sub_state_idle(SUB_STATE.WANDER)

func _update_charge(delta:float)->void:
    # 朝向实时追踪目标
    _update_charge_direction()
    velocity = move_dir*data.charge_speed

    # 检测冲锋是否撞击到敌人
    # 记录本次移动是否发生有效撞击
    var hit_occurred = false
    # 造成伤害
    # 记录已经攻击过的对象，避免重复扣血
    var hited_targets = []
    # get_bounce_collision_count()最近一次调用move_and_slide()时发生碰撞并改变方向的次数
    for i in get_slide_collision_count():
        # 获取碰撞信息,可能发生多次碰撞，用i指定获取哪次
        var collision = get_slide_collision(i)
        # 返回射线相交的第一个物体
        var collider = collision.get_collider()
        if not hited_targets.has(collider):
            hit_occurred = true
            if collider.has_method("take_damage"):
                collider.take_damage(data.contact_damage)
            hited_targets.append(collider)

    if hit_occurred:
        var collision = get_last_slide_collision()
        # 入射方向.bounce(法线) == 反射方向
        bounce_dir = move_dir.bounce(collision.get_normal())
        _switch_sub_state_combat(SUB_STATE.BOUNCE)

func _update_bounce(delta: float) -> void:
    # 弹开状态属于后摇，自己无法控制，必须走完整个流程
    # 速度按摩擦系数衰减（帧率无关）
    # bounce_friction 表示每秒的衰减比例（0.5 = 每秒衰减到50%）
    curr_bounce_speed *= pow(data.bounce_friction,delta)
    velocity = move_dir * curr_bounce_speed
    # 本帧移动距离
    var move_this_frame = get_real_velocity().length() * delta
    bounce_remaining -= move_this_frame
    
    if curr_bounce_speed <= data.bounce_min_speed or bounce_remaining <= 0:
        _switch_sub_state_combat(SUB_STATE.RECOVERY)

    var last_collision = get_last_slide_collision()
    if last_collision:
        move_dir = move_dir.bounce(last_collision.get_normal())
    
func _update_recovery(delta:float)->void:
    state_timer -= delta
    if state_timer<=0:
        _switch_sub_state_combat(SUB_STATE.CHARGE)
    
func _update_return_home(delta:float)->void:
    move_dir = (global_position-home_position).normalized()
    velocity = move_dir*data.wander_speed

func _switch_super_state(new_super: SUPER_STATE) -> void:
    # 退出旧的大状态
    match current_super_state:
        SUPER_STATE.IDLE:
            _exit_idle_super()
        SUPER_STATE.COMBAT:
            _exit_combat_super()
        SUPER_STATE.RETURNING:
            _exit_returning_super()
    
    # 切换状态
    current_super_state = new_super
    
    # 进入新的大状态
    match current_super_state:
        SUPER_STATE.IDLE:
            _enter_idle_super()
        SUPER_STATE.COMBAT:
            _enter_combat_super()
        SUPER_STATE.RETURNING:
            _enter_returning_super()


func _enter_idle_super()->void:
    _switch_sub_state_idle(SUB_STATE.WANDER_PAUSE)
func _enter_combat_super()->void:
    _switch_sub_state_combat(SUB_STATE.CHARGE)
func _enter_returning_super()->void:
    _switch_sub_state_returning(SUB_STATE.RETURN_HOME)
func _exit_idle_super()->void:
    pass
func _exit_combat_super()->void:
    pass
func _exit_returning_super()->void:
    pass

# 各大父状态切换子状态
func _switch_sub_state_idle(new_sub:SUB_STATE)->void:
    match current_sub_state:
        SUB_STATE.WANDER:
            move_dir = Vector2(randf_range(-1,1),randf_range(-1,1)).normalized()
            state_timer = data.wander_distance/data.wander_speed
        SUB_STATE.WANDER_PAUSE:
            move_dir = Vector2.ZERO
            velocity = Vector2.ZERO
            state_timer = randf_range(data.wander_pause_min,data.wander_pause_max)
        _:
            push_warning("super state idle has wrong sub state when switch: ",current_sub_state)
func _switch_sub_state_combat(new_sub:SUB_STATE)->void:
    match current_sub_state:
        SUB_STATE.CHARGE:
            # 更新方向
            _update_charge_direction()
            # 更新速度
            velocity = move_dir*data.charge_speed
        SUB_STATE.BOUNCE:
            # bounce_dir由_check_contact_and_damage设置
            move_dir = bounce_dir
            curr_bounce_speed = data.bounce_speed
            bounce_remaining = data.bounce_distance
            velocity = move_dir*curr_bounce_speed
        SUB_STATE.RECOVERY:
            move_dir = Vector2.ZERO
            velocity = Vector2.ZERO
            state_timer = data.recovery_time
        _:
            push_warning("super state idle has wrong sub state when switch: ",current_sub_state)

func _switch_sub_state_returning(new_sub:SUB_STATE)->void:
    match current_sub_state:
        SUB_STATE.RETURN_HOME:
            # 目前阶段地图上几乎没有什么障碍，
            # 但是之后地图正式做起来了，就要做寻路系统了
            move_dir = (global_position-home_position).normalized()
            velocity = move_dir*data.wander_speed
        _:
            push_warning("super state idle has wrong sub state when switch: ",current_sub_state)



# 物体进入视野
func _on_body_enter_vision(body:Node)->void:
    # 后续除了玩家还可以有别的攻击对象时要添加一个数组
    # 储存所有可能的攻击对象
    if body.is_in_group("player") and target == null:
        target = body

# 目标离开视野
func _on_body_exit_vision(body:Node)->void:
    if body == target:
        target = null

# =========== 工具函数
func _update_charge_direction()->void:
    if not target:
        return
    move_dir = (target.global_position-global_position).normalized()


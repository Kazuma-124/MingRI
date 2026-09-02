extends CharacterBase

#region 枚举
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
#endregion


#region export

@export var data:EnemyData

#endregion


#region 成员变量
# ========== 当前状态
var _current_super_state: SUPER_STATE
var _current_sub_state: SUB_STATE

var home_position:Vector2
var home_radius:float
var _cur_hp:float
var _target:CharacterBody2D = null # 当前追击目标
var _move_dir:Vector2 = Vector2.RIGHT
var _state_timer:float = 0.0
var _bounce_dir:Vector2
var _bounce_remaining:float = 0.0 # 剩余滑行距离
var _curr_bounce_speed:float
#endregion


#region onready

@onready var _vision_area: Area2D = $VisionArea
@onready var _vision_collision_shape: CollisionShape2D = $VisionArea/VisionCollisionShape

#endregion


#region 外部接口

func take_damage(damage:float)->void:
	_cur_hp = max(_cur_hp-damage,0.0)
	$HpBar.set_ratio(_cur_hp/data.max_hp)

#endregion

#region 内部函数
#内置函数
#状态机-大状态
#状态机-子状态
#各子状态逻辑
#状态切换
#信号处理
#工具函数
#region 生命周期
func _ready() -> void:
	super._ready()
	add_to_group("enemy")
	_cur_hp = data.max_hp

	$HpBar.set_ratio(_cur_hp/data.max_hp)

	# 视野半径和信号设置
	_vision_collision_shape.shape.radius = data.vision_radius
	_vision_area.body_entered.connect(_on_body_enter_vision)
	_vision_area.body_exited.connect(_on_body_exit_vision)

	_switch_super_state(SUPER_STATE.IDLE)

func _physics_process(delta: float) -> void:
	# 上一帧的状态作为输入
	if _cur_hp <= 0:
		queue_free()
		return
	super._physics_process(delta)
#endregion


#region 属性计算
func _update_base_status(_delta:float)->void:
	_update_super_state(_delta)
	status_manager.set_self_velocity(velocity)
func _post_movement(_delta:float)->void:
	_on_movement_result()
#endregion

#region 状态机-大状态
func _update_super_state(delta: float) -> void:
	match _current_super_state:
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
	if is_instance_valid(_target):
		_switch_super_state(SUPER_STATE.COMBAT)
		return
	_update_idle_sub(delta)

func _update_combat_super(delta:float)->void:
	# 追出领地则放弃追击，回家
	if global_position.distance_to(home_position)>home_radius:
		_target = null
		_switch_super_state(SUPER_STATE.RETURNING)
		return
	# 目标丢失
	if not is_instance_valid(_target):
		_target = null
		_switch_super_state(SUPER_STATE.IDLE)
		return
	_update_combat_sub(delta)

func _update_returning_super(delta:float)->void:
	if global_position.distance_to(home_position)<(home_radius/2):
		_switch_super_state(SUPER_STATE.IDLE)
		return
	_update_returning_sub(delta)
#endregion

#region 状态机-子状态
func _update_idle_sub(delta)->void:
	match _current_sub_state:
		SUB_STATE.WANDER:
			_update_wander(delta)
		SUB_STATE.WANDER_PAUSE:
			_update_wander_pause(delta)
		_:
			push_warning("super state idle has wrong sub state when update: ",_current_sub_state)

func _update_combat_sub(delta)->void:
	match _current_sub_state:
		SUB_STATE.CHARGE:
			_update_charge(delta)
		SUB_STATE.BOUNCE:
			_update_bounce(delta)
		SUB_STATE.RECOVERY:
			_update_recovery(delta)
		_:
			push_warning("super state combat has wrong sub state when update: ",_current_sub_state)

func _update_returning_sub(delta)->void:
	match _current_sub_state:
		SUB_STATE.RETURN_HOME:
			_update_return_home(delta)
		_:
			push_warning("super state returning has wrong sub state when update: ",_current_sub_state)
#endregion

#region 各子状态逻辑
func _update_wander(delta:float)->void:
	# 维持速度，以防移动过程中velocity被改变
	velocity = _move_dir*data.wander_speed
	_state_timer -= delta
	if _state_timer<=0:
		_switch_sub_state_idle(SUB_STATE.WANDER_PAUSE)

func _update_wander_pause(delta:float)->void:
	_state_timer-=delta
	if _state_timer<=0:
		_switch_sub_state_idle(SUB_STATE.WANDER)

func _update_charge(_delta:float)->void:
	# 朝向实时追踪目标
	_update_charge_direction()
	velocity = _move_dir*data.charge_speed

func _update_bounce(delta: float) -> void:
	# 弹开状态属于后摇，自己无法控制，必须走完整个流程
	# 速度按摩擦系数衰减（帧率无关）
	# bounce_friction 表示每秒的衰减比例（0.5 = 每秒衰减到50%）
	_curr_bounce_speed *= pow(data.bounce_friction,delta)
	velocity = _move_dir * _curr_bounce_speed
	# 本帧移动距离
	var move_this_frame = velocity.length() * delta
	_bounce_remaining -= move_this_frame

	if _curr_bounce_speed <= data.bounce_min_speed or _bounce_remaining <= 0:
		_switch_sub_state_combat(SUB_STATE.RECOVERY)
		return

func _update_recovery(delta:float)->void:
	_state_timer -= delta
	if _state_timer<=0:
		_switch_sub_state_combat(SUB_STATE.CHARGE)

func _update_return_home(delta:float)->void:
	_move_dir = (home_position-global_position).normalized()
	velocity = _move_dir*data.wander_speed
#endregion

#region 状态切换
func _switch_super_state(new_super: SUPER_STATE) -> void:
	# 退出旧的大状态
	match _current_super_state:
		SUPER_STATE.IDLE:
			_exit_idle_super()
		SUPER_STATE.COMBAT:
			_exit_combat_super()
		SUPER_STATE.RETURNING:
			_exit_returning_super()

	# 切换状态
	_current_super_state = new_super

	# 进入新的大状态
	match _current_super_state:
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
	match new_sub:
		SUB_STATE.WANDER:
			_current_sub_state = new_sub
			_move_dir = Vector2(randf_range(-1,1),randf_range(-1,1)).normalized()
			_state_timer = data.wander_distance/data.wander_speed
		SUB_STATE.WANDER_PAUSE:
			_current_sub_state = new_sub
			_move_dir = Vector2.ZERO
			velocity = Vector2.ZERO
			_state_timer = randf_range(data.wander_pause_min,data.wander_pause_max)
		_:
			push_warning("super state idle has wrong sub state when switch: ",_current_sub_state)

func _switch_sub_state_combat(new_sub:SUB_STATE)->void:
	match new_sub:
		SUB_STATE.CHARGE:
			_current_sub_state = new_sub
			# 更新方向
			_update_charge_direction()
			# 更新速度
			velocity = _move_dir*data.charge_speed
		SUB_STATE.BOUNCE:
			_current_sub_state = new_sub
			# bounce_dir由_check_contact_and_damage设置
			_move_dir = _bounce_dir
			_curr_bounce_speed = data.bounce_speed
			_bounce_remaining = data.bounce_distance
			velocity = _move_dir*_curr_bounce_speed
		SUB_STATE.RECOVERY:
			_current_sub_state = new_sub
			_move_dir = Vector2.ZERO
			velocity = Vector2.ZERO
			_state_timer = data.recovery_time
		_:
			push_warning("super state combat has wrong sub state when switch: ",_current_sub_state)

func _switch_sub_state_returning(new_sub:SUB_STATE)->void:
	match new_sub:
		SUB_STATE.RETURN_HOME:
			_current_sub_state = new_sub
			# 目前阶段地图上几乎没有什么障碍，
			# 但是之后地图正式做起来了，就要做寻路系统了
			_move_dir = (home_position-global_position).normalized()
			velocity = _move_dir*data.wander_speed
		_:
			push_warning("super state returning has wrong sub state when switch: ",_current_sub_state)
#endregion

#region 信号处理
# 物体进入视野
func _on_body_enter_vision(body:Node)->void:
	# 后续除了玩家还可以有别的攻击对象时要添加一个数组
	# 储存所有可能的攻击对象
	if body.is_in_group("player") and _target == null:
		_target = body

# 目标离开视野
func _on_body_exit_vision(body:Node)->void:
	if body == _target:
		_target = null
#endregion

#region 工具函数
func _update_charge_direction()->void:
	if not _target:
		return
	_move_dir = (_target.global_position-global_position).normalized()

func _on_movement_result()->void:
	if _current_super_state != SUPER_STATE.COMBAT:
		return
	if _current_sub_state != SUB_STATE.CHARGE:
		return
	var hit_occurred = false
	var hit_normal: Vector2
	var hit_targets: Array = []
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		if not hit_targets.has(collider):
			if collider.has_method("take_damage"):
				collider.take_damage(data.contact_damage)
			hit_targets.append(collider)
			var normal = collision.get_normal()
			if _move_dir.dot(-normal) > 0.5:
				hit_occurred = true
				hit_normal = normal
	if hit_occurred:
		_bounce_dir = _move_dir.bounce(hit_normal)
		_switch_sub_state_combat(SUB_STATE.BOUNCE)
#endregion

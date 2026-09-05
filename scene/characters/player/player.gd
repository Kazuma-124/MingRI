# 修改玩家数据机制
extends CharacterBase

#region 信号
signal facing_changed(new_facing:Vector2)
signal target_locked(target:Node2D)
signal target_unlocked()
#endregion

#region export
@export var data:PlayerData
# @export var hp_regen_per_second: float = 5
# @export var mp_regen_per_second: float = 10
#endregion

#region 成员变量
var _state:PlayerSaveableState
var _skill_caster:SkillCaster
# ====== 玩家状态
var _move_speed
var _mouse_dir:Vector2
var _move_dir:Vector2
var _target_dir:Vector2
# 朝向系统
var _facing:Vector2 = Vector2.RIGHT
var _other_facing:Vector2 = Vector2.ZERO
var _locked_target:Node2D = null
#endregion

#region onready
@onready var _animation_player: AnimationPlayer = $AnimationPlayer
@onready var _weapon_pivot: Node2D = $WeaponPivot
@onready var _lock_indicator:CanvasItem = $LockIndicator
#endregion

#region 外部接口
func init_hp_and_mp_signal()->void:
    _state.emit_hp_changed()
    _state.emit_mp_all_changed()
func get_state()->PlayerSaveableState:
    return _state
# 提供给 SkillSlot 调用的能量接口
func has_enough_mp(attr: AttributeTypes.Type, amount: float) -> bool:
    return _state.has_enough_mp(attr, amount)

func cost_mp(attr: AttributeTypes.Type, amount: float) -> bool:
    return _state.cost_mp(attr, amount)

func get_mp(attr: AttributeTypes.Type) -> float:
    return _state.get_mp(attr)
func take_damage(amount: float) -> void:
    _state.take_damage(amount)
func heal(amount:float)->void:
    _state.heal(amount)

func set_other_facing(dir:Vector2)->void:
    _other_facing = dir.normalized()

func get_facing()->Vector2:
    return _facing

func set_lock_target(target:Node2D)->void:
    if is_instance_valid(target):
        if _locked_target == target:
            return
        clear_lock()
        _locked_target = target
        target_locked.emit(target)
        return
func clear_lock()->void:
    if _locked_target:
        _locked_target = null
        target_unlocked.emit()
func get_locked_target()->Node2D:
    if is_instance_valid(_locked_target):
        return _locked_target
    else:
        return null
#endregion


#region 内置函数

func _ready() -> void:
    super._ready()
    # ==== 玩家状态
    _init_saveable_state()
    _skill_caster = SkillCaster.new()
    _skill_caster.setup(self)
    _skill_caster.cast_executed.connect(_on_cast_executed)
    _init_saveable_state_signal_connect()
    # == runtime _state
    _move_speed = data.base_speed
    # 锁定信号
    target_locked.connect(_on_target_locked)
    target_unlocked.connect(_on_target_unlocked)
    # 方向和动画
    _update_dir_status()
    _update_animation()
    # 注册
    EnemyManager.register_player(self)
    GameManager.set_player(self)


func _unhandled_input(event: InputEvent) -> void:
    if _skill_caster.is_aiming():
        return
    if event.is_action_pressed("primary_attack"):
        _skill_caster.cast_primary_skill()
        get_viewport().set_input_as_handled()
    
    if event.is_action_pressed("lock_target"):
        _try_toggle_lock()
        get_viewport().set_input_as_handled()

func _update_base_status(delta:float)->void:
    _update_dir_status()
    _update_skill_status(delta)
    buff_manager.set_self_velocity(_move_dir*_move_speed)

func _try_toggle_lock()->void:
    var mouse_pos := get_global_mouse_position()

    # 在鼠标位置做小圆范围查询
    var query := PhysicsShapeQueryParameters2D.new()
    query.shape = CircleShape2D.new()
    query.shape.radius = 20.0
    # 把查询形状放到世界空间,Transform2D(旋转角度,摆放位置)
    query.transform = Transform2D(0,mouse_pos)
    query.collide_with_bodies = true
    query.collide_with_areas = false
    query.collision_mask = 2 # 只查Entity层
    
    var space_state := get_world_2d().direct_space_state
    var results:=space_state.intersect_shape(query)
    var nearest_target:Node2D = null
    var nearest_dist:float = INF
    for result in results:
        var body:CharacterBody2D = result.collider
        if body.is_in_group("enemy") and is_instance_valid(body):
            var dist = body.global_position.distance_to(mouse_pos)
            if dist < nearest_dist:
                nearest_dist = dist
                nearest_target = body
    if nearest_target:
        # 有可锁定对象，锁定新目标
        set_lock_target(nearest_target)
    else:
        # 鼠标下无敌人，取消锁定
        clear_lock()
# 技能冷却
func _update_skill_status(delta:float)->void:
    _state.update_skill_cooldowns(delta)

func _update_dir_status()->void:
    _update_mouse_dir()

    _update_move_dir()

    _update_target_dir()

    _update_aim_facing()

    _update_facing_dir()


# func _my_move_and_slide()->void:
#     move_and_slide()

func _update_facing_dir()->void:
    # 优先级从高到低
    if _other_facing!=Vector2.ZERO:
        _facing = _other_facing
        # 消费后清零
        _other_facing = Vector2.ZERO
    elif _target_dir!=Vector2.ZERO:
        _facing = _target_dir
    elif _move_dir!=Vector2.ZERO:
        _facing = _move_dir
    # 没有更改则保持不变

func _update_aim_facing()->void:
    if not _skill_caster.is_aiming():
        return
    var indicator:= _skill_caster.get_indicator()
    if not indicator:
        return
    var dir := indicator.get_aim_direction()
    if dir!=Vector2.ZERO:
        set_other_facing(dir)

func _update_target_dir()->void:
    # 朝向跟随被锁定目标，可被其它朝向更改来源覆盖
    if _locked_target and is_instance_valid(_locked_target):
        _target_dir = (_locked_target.global_position-global_position).normalized()
    else:
        _target_dir = Vector2.ZERO


func _update_mouse_dir()->void:
    _mouse_dir = (get_global_mouse_position()-global_position).normalized()
func _update_move_dir()->void:
    _move_dir = Input.get_vector("move_left","move_right","move_up","move_down").normalized()




#region 动画
# ======= 动画
func _update_animation():
    _update_body_animation()
    _update_weapon_animation()

func _update_body_animation():
    if _facing==Vector2.ZERO:
        return

    var animation_suffix:StringName = _vector_to_suffix(_facing)
    var animation_prefix:StringName = "facing"
    var animation_name:StringName = StringName("%s_%s"%[animation_prefix,animation_suffix])
    if not _animation_player.has_animation(animation_name):
        push_warning("Player BodySprite missing animation:%s"%animation_name)
    if _animation_player.current_animation!=animation_name:
        _animation_player.play(animation_name)


func _update_weapon_animation():
    if _skill_caster.is_aiming():
        _weapon_pivot.visible = false
    else:
        _weapon_pivot.visible = true
        if _facing!=Vector2.ZERO:
            _weapon_pivot.rotation = _facing.angle()
            _weapon_pivot.scale.y = 1.0 if _facing.x>=0 else -1.0

#endregion

#region 工具函数
# ============ 工具 =============
func _vector_to_suffix(vec:Vector2)->StringName:
    return &"right" if vec.x>=0 else &"left"
    # if abs(vec.x) >= abs(vec.y):
    #     return &"right" if vec.x>=0 else &"left"
    # else:
    #     return &"down" if vec.y>=0 else &"up"
#endregion

#region 初始化

# 初始化
func _init_saveable_state()->void:
    # 从初始玩家data资源文件中加载新存档的玩家初始状态
    _state = PlayerSaveableState.new()
    _state.init_with_start_data(data)
#endregion

#endregion


#region 信号处理

func _init_saveable_state_signal_connect()->void:
    _state.hp_changed.connect(
        func(cur:float,max_input:float)->void:
            EventBus.player_hp_changed.emit(cur,max_input)
    )
    _state.mp_changed.connect(
        func(attr:AttributeTypes.Type,cur:float)->void:
            EventBus.player_mp_changed.emit(attr,cur)
    )
    _state.mp_all_changed.connect(
        func(mps:Array[float],max_input:float)->void:
            EventBus.player_mp_all_changed.emit(mps,max_input)
    )
    _state.primary_attack_switched.connect(
        func(skill_id:StringName)->void:
            EventBus.player_primary_attack_switched.emit(skill_id)
    )
    _state.slot_skill_changed.connect(
        func(slot_id:int,skill_id:StringName)->void:
            EventBus.shortcut_skill_changed.emit(slot_id,skill_id)
    )

    # UI输入->逻辑
    EventBus.primary_attack_slot_clicked.connect(_state.switch_primary_attack)
    EventBus.shortcut_slot_clicked.connect(_on_shortcut_slot_clicked)
    EventBus.skill_book_skill_clicked.connect(_skill_caster.cast_skill)
    EventBus.skill_book_quick_cast.connect(
        func(skill_id:StringName)->void:
            _skill_caster.cast_skill(skill_id,true)
    )
func _on_shortcut_slot_clicked(slot_id:int)->void:
    _skill_caster.cast_skill(_state.get_slot_skill_id(slot_id))
func _on_cast_executed(skill_id:StringName,ctx:CastContext)->void:
    var dir := _dir_from_castcontext(skill_id,ctx)
    if dir != Vector2.ZERO:
        _other_facing = dir
func _dir_from_castcontext(skill_id:StringName,ctx:CastContext)->Vector2:
    var skill_data := _state.get_skill_data(skill_id)
    if not skill_data:
        return Vector2.ZERO
    match skill_data.targeting_type:
        SkillData.TargetingType.INSTANT:
            var instant_data := skill_data as SkillDataInstant
            if instant_data:
                if instant_data.direction_mode==SkillDataInstant.DirectionMode.NONE:
                    return Vector2.ZERO
                else:
                    # CASTER_FACING,MOUSE_DIRECTION
                    return ctx.direction
        SkillData.TargetingType.DIRECTION:
            if ctx.direction!=Vector2.ZERO:
                return ctx.direction
        SkillData.TargetingType.POSITION:
            return (ctx.position-global_position).normalized()
        SkillData.TargetingType.TARGET:
            if is_instance_valid(ctx.target):
                return (ctx.target.global_position-global_position).normalized()
    return Vector2.ZERO

func _on_target_locked(target:Node2D)->void:
    _lock_indicator.set_target(target)

func _on_target_unlocked()->void:
    _lock_indicator.set_target(null)
#endregion

# 修改玩家数据机制

extends CharacterBase

#region 导出变量
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
#endregion

#region onready
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var weapon_pivot: Node2D = $WeaponPivot
#endregion

#region 内置函数

func _ready() -> void:
    super._ready()
    # ==== 玩家状态
    _init_saveable_state()
    _skill_caster = SkillCaster.new()
    _skill_caster.setup(self)
    _init_saveable_state_signal_connect()
    # == runtime _state
    _move_speed = data.base_speed
    # 方向和动画
    _update_dir_status()
    _update_animation()
    # 注册
    EnemyManager.register_player(self)
    GameManager.set_player(self)

func _physics_process(delta: float) -> void:
    # 鼠标方向等
    _update_dir_status()
    # 更新技能冷却之类的
    _update_skill_status(delta)
    _update_animation()

func _unhandled_input(event: InputEvent) -> void:
    if _skill_caster.is_aiming():
        return
    if event.is_action_pressed("primary_attack"):
        _skill_caster.cast_primary_skill()

#endregion

# ======= 可存档数据
func take_damage(amount: float) -> void:
    _state.take_damage(amount)



#region 运行时更新
# 技能冷却
func _update_skill_status(delta:float)->void:
    _state.update_skill_cooldowns(delta)

# ======= 运行时数据
# 通过输入获取鼠标方向和运动方向
func _update_dir_status():
    # 玩家鼠标方向，决定动画朝向和武器指向
    _mouse_dir = get_global_mouse_position()-global_position
    if _mouse_dir!=Vector2.ZERO:
        _mouse_dir = _mouse_dir.normalized()
    # 玩家移动方向
    _move_dir = Input.get_vector("move_left","move_right","move_up","move_down").normalized()

    if _skill_caster.is_aiming():
        velocity = Vector2.ZERO
    else:
        # 更新玩家速度，移动
        velocity = _move_dir * _move_speed
    move_and_slide()

#endregion



#region 动画
# ======= 动画
func _update_animation():
    _update_body_animation()
    _update_weapon_animation()

func _update_body_animation():
    if _mouse_dir==Vector2.ZERO:
        return

    var animation_suffix:StringName = _vector_to_suffix(_mouse_dir)
    # var animation_prefix:StringName = &"idle" if _move_dir==Vector2.ZERO else &"walk"
    var animation_prefix:StringName = "facing"
    var animation_name:StringName = StringName("%s_%s"%[animation_prefix,animation_suffix])
    if not animation_player.has_animation(animation_name):
        push_warning("Player BodySprite missing animation:%s"%animation_name)
    if animation_player.current_animation!=animation_name:
        animation_player.play(animation_name)


func _update_weapon_animation():
    if _skill_caster.is_aiming():
        weapon_pivot.visible = false
    else:
        weapon_pivot.visible = true
        weapon_pivot.rotation = _mouse_dir.angle()
        weapon_pivot.scale.y = 1.0 if _mouse_dir.x>=0 else -1.0

#endregion


#region 工具函数

# ============ 工具 =============
func get_state()->PlayerSaveableState:
    return _state

func _vector_to_suffix(vec:Vector2)->StringName:
    return &"right" if vec.x>=0 else &"left"
    # if abs(vec.x) >= abs(vec.y):
    #     return &"right" if vec.x>=0 else &"left"
    # else:
    #     return &"down" if vec.y>=0 else &"up"

# 提供给 SkillSlot 调用的能量接口
func has_enough_mp(attr: AttributeTypes.Type, amount: float) -> bool:
    return _state.has_enough_mp(attr, amount)

func cost_mp(attr: AttributeTypes.Type, amount: float) -> bool:
    return _state.cost_mp(attr, amount)

func get_mp(attr: AttributeTypes.Type) -> float:
    return _state.get_mp(attr)

#endregion



#region 初始化

# 初始化
func _init_saveable_state()->void:
    # 从初始玩家data资源文件中加载新存档的玩家初始状态
    _state = PlayerSaveableState.new()
    _state.init_with_start_data(data)
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
    # _state.primary_attack_skills_updated.connect(EventBus.player_primary_attack_skills_updated)
    _state.slot_skill_changed.connect(
        func(slot_id:int,skill_id:StringName)->void:
            EventBus.shortcut_skill_changed.emit(slot_id,skill_id)
    )

    # UI输入->逻辑
    EventBus.primary_attack_slot_clicked.connect(_state.switch_primary_attack)
    EventBus.shortcut_slot_clicked.connect(_on_shortcut_slot_clicked)
    EventBus.skill_book_skill_clicked.connect(_skill_caster.cast_skill)
func _on_shortcut_slot_clicked(slot_id:int)->void:
    _skill_caster.cast_skill(_state.get_slot_skill_id(slot_id))

func init_hp_and_mp_signal()->void:
    _state.emit_hp_changed()
    _state.emit_mp_all_changed()
#endregion

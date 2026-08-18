# 修改玩家数据机制

extends CharacterBase

#region 导出变量
@export var data:PlayerData
# @export var hp_regen_per_second: float = 5
# @export var mp_regen_per_second: float = 10
#endregion

#region 成员变量
var state:PlayerSaveableState
var skill_caster:SkillCaster
# ====== 玩家状态
var move_speed
var mouse_dir:Vector2
var move_dir:Vector2

@onready var body_sprite: AnimatedSprite2D = $BodySprite
@onready var weapon_pivot: Node2D = $WeaponPivot
#endregion

#region 内置函数

func _ready() -> void:
    super._ready()
    # ==== 玩家状态
    _init_saveable_state()
    skill_caster = SkillCaster.new()
    skill_caster.setup(self,state)
    _init_saveable_state_signal_connect()
    # == runtime state
    move_speed = data.base_speed
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
    if event.is_action_pressed("primary_attack"):
        skill_caster.cast_primary_skill()

#endregion

#region 可存档数据接口
# ======= 可存档数据
func take_damage(amount: float) -> void:
    state.take_damage(amount)

#endregion


#region 运行时更新
# 技能冷却
func _update_skill_status(delta:float)->void:
    state.update_skill_cooldowns(delta)

# ======= 运行时数据
# 通过输入获取鼠标方向和运动方向
func _update_dir_status():
    # 玩家鼠标方向，决定动画朝向和武器指向
    mouse_dir = get_global_mouse_position()-global_position
    if mouse_dir!=Vector2.ZERO:
        mouse_dir = mouse_dir.normalized()
    # 玩家移动方向
    move_dir = Input.get_vector("move_left","move_right","move_up","move_down").normalized()

    # 更新玩家速度，移动
    velocity = move_dir * move_speed
    move_and_slide()

#endregion



#region 动画
# ======= 动画
func _update_animation():
    _update_body_animation()
    _update_weapon_animation()

func _update_body_animation():
    if mouse_dir==Vector2.ZERO:
        return

    var animation_suffix:StringName = _vector_to_suffix(mouse_dir)
    var animation_prefix:StringName = &"idle" if move_dir==Vector2.ZERO else &"walk"
    var animation_name:StringName = StringName("%s_%s"%[animation_prefix,animation_suffix])

    if not body_sprite.sprite_frames.has_animation(animation_name):
        push_warning("Player BodySprite missing animation:%s"%animation_name)

    if body_sprite.animation!=animation_name:
        body_sprite.play(animation_name)


func _update_weapon_animation():
    weapon_pivot.rotation = mouse_dir.angle()
    weapon_pivot.scale.y = 1.0 if mouse_dir.x>=0 else -1.0

#endregion


#region 工具函数

# ============ 工具 =============
func _vector_to_suffix(vec:Vector2)->StringName:
    if abs(vec.x) >= abs(vec.y):
        return &"right" if vec.x>=0 else &"left"
    else:
        return &"down" if vec.y>=0 else &"up"

# 提供给 SkillSlot 调用的能量接口
func has_enough_mp(attr: AttributeTypes.Type, amount: float) -> bool:
    return state.has_enough_mp(attr, amount)

func cost_mp(attr: AttributeTypes.Type, amount: float) -> bool:
    return state.cost_mp(attr, amount)

func get_mp(attr: AttributeTypes.Type) -> float:
    return state.get_mp(attr)

#endregion



#region 初始化

# 初始化
func _init_saveable_state()->void:
    # 从初始玩家data资源文件中加载新存档的玩家初始状态
    state = PlayerSaveableState.new()
    state.init_with_start_data(data)
#endregion


#region 信号处理

func _init_saveable_state_signal_connect()->void:
    state.hp_changed.connect(
        func(cur:float,max_input:float)->void:
            EventBus.player_hp_changed.emit(cur,max_input)
    )
    state.mp_changed.connect(
        func(attr:AttributeTypes.Type,cur:float)->void:
            EventBus.player_mp_changed.emit(attr,cur)
    )
    state.mp_all_changed.connect(
        func(mps:Array[float],max_input:float)->void:
            EventBus.player_mp_all_changed.emit(mps,max_input)
    )
    state.primary_attack_switched.connect(
        func(skill_id:StringName)->void:
            EventBus.player_primary_attack_switched.emit(skill_id)
    )
    # state.primary_attack_skills_updated.connect(EventBus.player_primary_attack_skills_updated)
    state.slot_skill_changed.connect(
        func(slot_id:int,skill_id:StringName)->void:
            EventBus.shortcut_skill_changed.emit(slot_id,skill_id)
    )

    # UI输入->逻辑
    EventBus.primary_attack_slot_clicked.connect(state.switch_primary_attack)
    EventBus.shortcut_slot_clicked.connect(_on_shortcut_slot_clicked)
    EventBus.skill_book_skill_clicked.connect(skill_caster.cast_skill)
func _on_shortcut_slot_clicked(slot_id:int)->void:
    skill_caster.cast_skill(state.get_slot_skill_id(slot_id))

func init_hp_and_mp_signal()->void:
    state.emit_hp_changed()
    state.emit_mp_all_changed()
#endregion

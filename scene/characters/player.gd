# 修改玩家数据机制
extends CharacterBase

@export var data:PlayerData

# @export var hp_regen_per_second: float = 5
# @export var mp_regen_per_second: float = 10

var state:PlayerRuntimeState
# 普攻技能槽
var primary_attack_slot:SkillSlot
var primary_attack_skills:Array = []
var current_primary_attack_index:int = 0
# 其它技能槽
var skill_slots:Array[SkillSlot]

# ====== 玩家状态
var move_speed
var mouse_dir:Vector2
var move_dir:Vector2

@onready var body_sprite: AnimatedSprite2D = $BodySprite
@onready var weapon_pivot: Node2D = $WeaponPivot


func _ready() -> void:
    super._ready()
    # 需要存档的玩家状态
    _init_state_data()
    # 不需要存档的状态
    move_speed = data.base_speed
    # 装载技能槽，普攻技能槽和普通技能槽
    _init_defult_skills()
    # 方向和动画
    _update_dir_status()
    _update_animation()
    # 注册
    GameManager.set_player(self,state)
    EnemyManager.register_player(self)
    # 信号,
    # 信号转发到EventBus
    state.hp_changed.connect(_on_state_hp_changed)
    state.mp_changed.connect(_on_state_mp_changed)
    state.mp_all_changed.connect(_on_state_mp_all_changed)
    _skill_signal_connect()

func _physics_process(delta: float) -> void:
    # 鼠标方向等
    _update_dir_status()
    # 更新技能冷却之类的
    _update_skill_status(delta)
    # _update_hp_and_mp_regen(delta)
    _update_animation()

func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("primary_attack"):
        var context = _generate_cast_context()
        var bullet = primary_attack_slot.cast(context)
        if bullet:
            get_parent().add_child(bullet)



# 受伤
func take_damage(amount: float) -> void:
    state.take_damage(amount)

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
    

func _update_skill_status(delta:float)->void:
    primary_attack_slot.update(delta)
    for slot in skill_slots:
        slot.update(delta)

# func _update_hp_and_mp_regen(delta: float) -> void:
#     if cur_hp < data.max_hp:
#         if cur_hp <=0:
#             cur_hp = 0;
#         cur_hp += hp_regen_per_second * delta
#         # 不能超过最大血量
#         if cur_hp > data.max_hp:
#             cur_hp = data.max_hp
#         hp_changed.emit(cur_hp,data.max_hp)
#     if cur_mp < data.max_mp:
#         if cur_hp <=0:
#             cur_hp = 0;
#         cur_mp += mp_regen_per_second * delta
#         # 不能超过最大血量
#         if cur_mp > data.max_mp:
#             cur_mp = data.max_mp
#         mp_changed.emit(cur_mp,data.max_mp)

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


func _generate_cast_context()->CastContext:
    var context = CastContext.new()
    context.caster_position = global_position
    context.cast_direction = mouse_dir
    return context

func _init_state_data()->void:
    state = PlayerRuntimeState.new()

    # learned_skill
    for skill in data.default_skills:
        if skill.unlock_level <= state.base_level:
            state.learned_skills.append(skill)
    # primary_attack_skills
    for skill in state.learned_skills:
        if skill.skill_type == SkillData.SkillType.PRIMARY_ATTACK && skill.unlock_level==0:
            state.primary_attack_skills.append(skill)


func _init_defult_skills()->void:
    # 下面的state相关以后要改为从存档中获取数据???
    # 技能
    # 普攻，默认自动装备0级，普攻技能
    primary_attack_skills = state.primary_attack_skills
    current_primary_attack_index = 0
    var init_skill_data = primary_attack_skills[current_primary_attack_index]
    primary_attack_slot = SkillSlot.from_data(init_skill_data,self)
    # 普通技能
    for skill in state.skill_slots:
        skill_slots.append(SkillSlot.from_data(skill,self))
    if state.skill_slots.size()<4:
        for i in (4-state.skill_slots.size()):
            skill_slots.append(SkillSlot.empty())

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

# 信号
func _on_state_hp_changed(cur:float,max:float)->void:
    EventBus.player_hp_changed.emit(cur,max)

func _on_state_mp_changed(attr:AttributeTypes.Type,cur:float)->void:
    EventBus.player_mp_changed.emit(attr,cur)

func _on_state_mp_all_changed(
    chiyan:float,
    shengxi:float,
    shuangxuan:float,
    youying:float,
    max:float
)->void:
    EventBus.player_mp_all_changed.emit(chiyan,shengxi,shuangxuan,youying,max)


func _on_slot_skill_changed(skill:SkillData,slot_id:int)->void:
    EventBus.equiped_skill_changed.emit(slot_id,skill)
func _on_slot_skill_cooldown_updated(ratio:float,remaining:float,slot_id:int)->void:
    EventBus.equiped_skill_cooldown_updated.emit(slot_id,ratio,remaining)
func _skill_signal_connect()->void:
    primary_attack_slot.skill_changed.connect(_on_slot_skill_changed.bind(0))
    primary_attack_slot.cooldown_updated.connect(_on_slot_skill_cooldown_updated.bind(0))
    for i in range(skill_slots.size()):
        var slot_id = i+1 # 下标从0开始，普通技能槽id从1开始
        skill_slots[i].skill_changed.connect(_on_slot_skill_changed.bind(slot_id))
        skill_slots[i].cooldown_updated.connect(_on_slot_skill_cooldown_updated.bind(slot_id))
    # 监听 UI 输入事件
    EventBus.equiped_skill_slot_clicked.connect(_on_skill_slot_clicked)

func _switch_primary_attack_skill()->void:
    current_primary_attack_index = (current_primary_attack_index+1)%primary_attack_skills.size()

    var new_data = primary_attack_skills[current_primary_attack_index]
    primary_attack_slot.set_skill(new_data)
func _on_skill_slot_clicked(slot_id:int)->void:
    if slot_id<0:
        push_warning("负数的slot_id,in _on_skill_slot_clicked")
        return
    if slot_id==0:
        _switch_primary_attack_skill()
    else:
        #??? 普通技能槽切换逻辑
        pass
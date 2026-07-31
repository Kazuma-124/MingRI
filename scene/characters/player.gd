extends CharacterBase

signal hp_changed(new_hp: float, max_hp: float)
signal mp_changed(new_mp:float,max_mp:float)

# ===== 技能
# 普攻火焰弹场景
const SkillEmptyHandData:SkillData = preload("res://data/skills/skill_empty_hand.tres")
const SkillBulletFlameData:SkillData =    preload("res://data/skills/skill_bullet_flame.tres")

@export var speed:float = 120.0
@export var max_hp:float = 100.0
@export var max_mp:float = 1000.0
@export var hp_regen_per_second: float = 2.0
@export var mp_regen_per_second: float = 10.0

var cur_hp:float
var cur_mp:float
# 普攻技能槽
var primary_attack_slot:SkillSlot
var primary_attack_skill_options:Array = []
var current_primary_attack_index:int = 0

# ====== 玩家状态
var mouse_dir:Vector2
var move_dir:Vector2

@onready var body_sprite: AnimatedSprite2D = $BodySprite
@onready var weapon_pivot: Node2D = $WeaponPivot


func _ready() -> void:
    super._ready()
    # 血量
    cur_hp = max_hp
    cur_mp = max_mp
    emit_update_hp()
    emit_update_mp()
    # 技能
    primary_attack_skill_options = [
        SkillEmptyHandData,
        SkillBulletFlameData
    ]
    var init_data = primary_attack_skill_options[current_primary_attack_index]
    primary_attack_slot = SkillSlot.new(init_data,self)
    # 方向和动画
    _update_dir_status()
    _update_animation()

func _physics_process(delta: float) -> void:
    _update_dir_status()
    _update_skill_status(delta)
    _update_hp_and_mp_regen(delta)
    _update_animation()

func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("primary_attack"):
        # print_debug("get_primary_attack")
        var context = _generate_cast_context()
        var bullet = primary_attack_slot.cast(context)
        if bullet:
            # print_debug("get_bullet_add_to_game")
            get_parent().add_child(bullet)


func switch_primary_attack_skill()->void:
    current_primary_attack_index = (current_primary_attack_index+1)%primary_attack_skill_options.size()

    var new_data = primary_attack_skill_options[current_primary_attack_index]
    primary_attack_slot.set_skill(new_data)

# 血条与蓝条
func emit_update_hp():
    hp_changed.emit(cur_hp,max_hp)
func emit_update_mp():
    mp_changed.emit(cur_mp,max_mp)
func get_mp()->float:
    return cur_mp
func cost_mp(mp_cost:float):
    cur_mp-=mp_cost
    mp_changed.emit(cur_mp,max_mp)
# 受伤
func take_damage(damage: float) -> void:
    cur_hp -= damage
    hp_changed.emit(cur_hp, max_hp) # 血量变了就发信号
    # print_debug("玩家血量：",cur_hp)



func _update_dir_status():
    # 玩家鼠标方向，决定动画朝向和武器指向
    mouse_dir = get_global_mouse_position()-global_position
    if mouse_dir!=Vector2.ZERO:
        mouse_dir = mouse_dir.normalized()
    # 玩家移动方向
    move_dir = Input.get_vector("move_left","move_right","move_up","move_down").normalized()
    
    # 更新玩家速度，移动
    velocity = move_dir * speed
    move_and_slide()
    print_debug("player:",velocity)
    

func _update_skill_status(delta:float)->void:
    primary_attack_slot.update(delta)

func _update_hp_and_mp_regen(delta: float) -> void:
    if cur_hp < max_hp:
        if cur_hp <=0:
            cur_hp = 0;
        cur_hp += hp_regen_per_second * delta
        # 不能超过最大血量
        if cur_hp > max_hp:
            cur_hp = max_hp
        hp_changed.emit(cur_hp,max_hp)
    if cur_mp < max_mp:
        cur_mp += mp_regen_per_second * delta
        # 不能超过最大血量
        if cur_mp > max_mp:
            cur_mp = max_mp
        mp_changed.emit(cur_mp,max_mp)

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

# ============ 工具 =============
func _vector_to_suffix(vec:Vector2)->StringName:
    if abs(vec.x) >= abs(vec.y):
        return &"right" if vec.x>=0 else &"left"
    else:
        return &"down" if vec.y>=0 else &"up"

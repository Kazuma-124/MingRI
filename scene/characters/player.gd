extends CharacterBody2D

signal hp_changed(new_hp: float, max_hp: float)
signal mp_changed(new_mp:float,max_mp:float)

# ===== 技能
# 普攻火焰弹场景
const SkillEmptyHandData:SkillData = preload("res://data/skills/skill_empty_hand.tres")
const SkillBulletFlameData:SkillData =    preload("res://data/skills/skill_bullet_flame.tres")

@export var speed:float = 120.0
@export var max_hp:float = 100.0
@export var max_mp:float = 100.0
@export var hp_regen_per_second: float = 2.0
@export var mp_regen_per_second: float = 5.0

var _cur_hp:float
var _cur_mp:float
# 普攻技能槽
var primary_attack_slot:SkillSlot
var _primary_attack_skill_options:Array = []
var _current_primary_attack_index:int = 0

# ====== 玩家状态
var _mouse_dir:Vector2
var _move_dir:Vector2

@onready var body_sprite: AnimatedSprite2D = $BodySprite
@onready var weapon_pivot: Node2D = $WeaponPivot


func _ready() -> void:
    # 血量
    _cur_hp = max_hp
    _cur_mp = max_mp
    emit_update_hp()
    emit_update_mp()
    # 技能
    _primary_attack_skill_options = [
        SkillEmptyHandData,
        SkillBulletFlameData
    ]
    var init_data = _primary_attack_skill_options[_current_primary_attack_index]
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
    if primary_attack_slot.skill_data.id==&"bullet_flame" && event.is_action_pressed("primary_attack"):
        _shoot()

func switch_primary_attack_skill()->void:
    _current_primary_attack_index = (_current_primary_attack_index+1)%_primary_attack_skill_options.size()

    var new_data = _primary_attack_skill_options[_current_primary_attack_index]
    primary_attack_slot.set_skill(new_data)

# 血条与蓝条
func emit_update_hp():
    hp_changed.emit(_cur_hp,max_hp)
func emit_update_mp():
    mp_changed.emit(_cur_mp,max_mp)
func get_mp()->float:
    return _cur_mp
func cost_mp(mp_cost:float):
    _cur_mp-=mp_cost
    mp_changed.emit(_cur_mp,max_mp)
# 受伤
func take_damage(damage: float) -> void:
    _cur_hp -= damage
    hp_changed.emit(_cur_hp, max_hp) # 血量变了就发信号
    print_debug("玩家血量：",_cur_hp)


func _shoot():
    var bullet = primary_attack_slot.cast(self)
    if bullet==null:
        return
    bullet.global_position = global_position+_mouse_dir*10
    bullet.set_direction(_mouse_dir)
    get_parent().add_child(bullet)
    

func _update_dir_status():
    # 玩家鼠标方向，决定动画朝向和武器指向
    _mouse_dir = get_global_mouse_position()-global_position
    if _mouse_dir!=Vector2.ZERO:
        _mouse_dir = _mouse_dir.normalized()
    # 玩家移动方向
    _move_dir = Input.get_vector("move_left","move_right","move_up","move_down").normalized()
    
    # 更新玩家速度，移动
    velocity = _move_dir * speed
    move_and_slide()
    

func _update_skill_status(delta:float)->void:
    primary_attack_slot.update(delta)

func _update_hp_and_mp_regen(delta: float) -> void:
    if _cur_hp < max_hp:
        _cur_hp += hp_regen_per_second * delta
        # 不能超过最大血量
        if _cur_hp > max_hp:
            _cur_hp = max_hp
        hp_changed.emit(_cur_hp,max_hp)
    if _cur_mp < max_mp:
        _cur_mp += mp_regen_per_second * delta
        # 不能超过最大血量
        if _cur_mp > max_mp:
            _cur_mp = max_mp
        mp_changed.emit(_cur_mp,max_mp)

# ======= 动画
func _update_animation():
    _update_body_animation()
    _update_weapon_animation()

func _update_body_animation():
    if _mouse_dir==Vector2.ZERO:
        return
    var animation_suffix:StringName = _vector_to_suffix(_mouse_dir)
    var animation_prefix:StringName = &"idle" if _move_dir==Vector2.ZERO else &"walk"
    var animation_name:StringName = StringName("%s_%s"%[animation_prefix,animation_suffix])
    if not body_sprite.sprite_frames.has_animation(animation_name):
        push_warning("Player BodySprite missing animation:%s"%animation_name)
    if body_sprite.animation!=animation_name:
        body_sprite.play(animation_name)
    
func _update_weapon_animation():
    weapon_pivot.rotation = _mouse_dir.angle()
    weapon_pivot.scale.y = 1.0 if _mouse_dir.x>=0 else -1.0

# ============ 工具 =============
func _vector_to_suffix(vec:Vector2)->StringName:
    if abs(vec.x) >= abs(vec.y):
        return &"right" if vec.x>=0 else &"left"
    else:
        return &"down" if vec.y>=0 else &"up"

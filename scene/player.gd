extends CharacterBody2D

@export var speed:float = 120.0
@export var max_hp:float = 100.0
var _cur_hp:float

@onready var body_sprite: AnimatedSprite2D = $BodySprite
@onready var weapon_pivot: Node2D = $WeaponPivot

const SkillBulletFlameScene = preload("res://scene/skill_bullet_flame.tscn")

# ====== 玩家状态
var _mouse_dir:Vector2
var _move_dir:Vector2

func _ready() -> void:
    _cur_hp = max_hp
    _update_player_status()
    _update_animation()

func _physics_process(delta: float) -> void:
    _update_player_status()
    _update_animation()

func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("attack_primary"):
        _shoot()

func _shoot():
    var bullet = SkillBulletFlameScene.instantiate()
    bullet.set_direction(_mouse_dir)
    get_parent().add_child(bullet)
    bullet.global_position = global_position+_mouse_dir*8
        
func take_damage(damage:float):
    _cur_hp-=damage
    print_debug("玩家血量：",_cur_hp)
    

func _update_player_status():
    # 玩家鼠标方向，决定动画朝向和武器指向
    _mouse_dir = get_global_mouse_position()-global_position
    if _mouse_dir!=Vector2.ZERO:
        _mouse_dir = _mouse_dir.normalized()
    # 玩家移动方向
    _move_dir = Input.get_vector("move_left","move_right","move_up","move_down").normalized()
    
    # 更新玩家速度，移动
    velocity = _move_dir * speed
    move_and_slide()
    
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

extends EntityBase
class_name Player

# ==================== 配置参数 ====================
@export var move_speed: float = 120.0

# ==================== 状态变量 ====================
enum MoveState { IDLE, MOVE }
var move_state: MoveState = MoveState.IDLE
var facing_suffix: StringName = &"down"  # 朝向后缀：up/down/left/right

# ==================== 节点引用 ====================
@onready var body_sprite: AnimatedSprite2D = $BodySprite
@onready var weapon_pivot:Node2D = $WeaponPivot

# ==================== 生命周期 ====================
func _ready() -> void:
    hp = max_hp  # 初始化血量
    _update_facing()
    _update_animation()

func _physics_process(delta: float) -> void:
    if is_dead:
        return
    # 玩家动画朝向
    _update_facing()
    # 武器指向朝向鼠标 
    _handle_movement()
    _update_animation()


# ==================== 朝向计算 ====================
func _update_facing():
    # 鼠标方向（相对玩家） = 鼠标全局位置-玩家全局位置
    var mouse_dir:Vector2 = get_global_mouse_position()-global_position
    if mouse_dir == Vector2.ZERO:
        return
    
    # 更新决定人物朝向动画后缀名
    facing_suffix = _vector_to_facing(mouse_dir)
    
    # 更新武器360°旋转
    weapon_pivot.rotation = mouse_dir.angle()
    # 武器动画是指向右边的动画，当武器要朝向左半边时，翻转武器
    weapon_pivot.scale.y = 1.0 if mouse_dir.x>=0 else -1.0
    
# ==================== 移动逻辑 ====================
func _handle_movement() -> void:
    # 获取八向输入，自动归一化
    var move_input: Vector2 = Input.get_vector(
        "move_left", "move_right",
        "move_up", "move_down"
    )
    
    velocity = move_input * move_speed
    move_and_slide()
    
    # 更新状态与朝向
    if move_input != Vector2.ZERO:
        move_state = MoveState.MOVE
    else:
        move_state = MoveState.IDLE

# ==================== 动画更新 ====================
func _update_animation() -> void:
    var anim_prefix: StringName
    match move_state:
        MoveState.MOVE:
            anim_prefix = &"walk"
        _:
            anim_prefix = &"idle"
    
    var anim_name: StringName = StringName("%s_%s" % [anim_prefix, facing_suffix])
    
    if not body_sprite.sprite_frames.has_animation(anim_name):
        push_warning("Player missing animation: %s" % anim_name)
        return
    
    if body_sprite.animation != anim_name:
        body_sprite.play(anim_name)

# ==================== 工具函数 ====================
func _vector_to_facing(dir: Vector2) -> StringName:
    if abs(dir.x) >= abs(dir.y):
        return &"right" if dir.x > 0 else &"left"
    else:
        return &"down" if dir.y > 0 else &"up"

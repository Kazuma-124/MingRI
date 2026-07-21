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

# ==================== 生命周期 ====================
func _ready() -> void:
    hp = max_hp  # 初始化血量
    _update_animation()

func _physics_process(delta: float) -> void:
    if is_dead:
        return
    
    _handle_movement()
    _update_animation()

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
        facing_suffix = _vector_to_facing(move_input)
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

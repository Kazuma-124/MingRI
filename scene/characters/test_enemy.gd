extends CharacterBody2D

# 状态枚举
enum STATE{
    WANDER,
    WANDER_PAUSE,
    CHARGE,
    SLIDE
}

@export var data:EnemyData


var cur_hp:float
var target:CharacterBody2D = null # 当前追击目标
var current_state:STATE
var move_dir:Vector2 = Vector2.RIGHT

var state_timer:float = 0.0
var slide_remaining:float = 0.0 # 剩余滑行距离

@onready var vision_area: Area2D = $VisionArea
@onready var vision_collision_shape: CollisionShape2D = $VisionArea/VisionCollisionShape

func _ready() -> void:
    cur_hp = data.max_hp

    # 视野半径和信号设置
    vision_collision_shape.shape.radius = data.vision_radius
    vision_area.body_entered.connect(_on_body_enter_vision)
    vision_area.body_exited.connect(_on_body_exit_vision)

    # 初始状态，游荡
    _switch_state(STATE.WANDER_PAUSE)

func _physics_process(delta: float) -> void:
    if cur_hp <= 0:
        queue_free()
        return
    match current_state:
        STATE.WANDER:
            _update_wander(delta)
        STATE.WANDER_PAUSE:
            _update_wander_pause(delta)
        STATE.CHARGE:
            _update_charge(delta)
        STATE.SLIDE:
            _update_slide(delta)
    move_and_slide()
    # 检测撞击目标
    _check_contact_damage()

func take_damage(damage:float):
    cur_hp-=damage


func _switch_state(state:STATE)->void:
    pass

# 物体进入视野
func _on_body_enter_vision(body:Node)->void:
    if body.is_in_group("player") and target == null:
        target = body
        _switch_state(STATE.CHARGE)

# 目标离开视野
func _on_body_exit_vision(body:Node)->void:
    if body == target:
        target = null
        _switch_state(STATE.WANDER)
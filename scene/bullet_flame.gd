extends Area2D

var data = preload("res://data/skills/skill_bullet_flame.tres")

var _dir:Vector2
var _start_pos:Vector2
var _explored:bool = false


func _ready() -> void:
    _start_pos = global_position
    body_entered.connect(_on_hit_body)
    
func _physics_process(delta: float) -> void:
    if _explored:
        return
    global_position += _dir * data.fly_speed * delta
    if global_position.distance_to(_start_pos) >= data.cast_range:
        _explore()
    
func _on_hit_body(body:Node2D)->void:
    if _explored:
        return
    _explore()

func _explore()->void:
    _explored = true
    # direct_space_state,访问该世界的物理状态，用于查询可能的碰撞
    var space = get_world_2d().direct_space_state
    
    # 圆形爆炸范围查询参数
    var query = PhysicsShapeQueryParameters2D.new()
    

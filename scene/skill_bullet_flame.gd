extends Area2D

var data = preload("res://data/skills/skill_bullet_flame.tres")

@onready var bullet_sprite: Sprite2D = $BulletSprite
@onready var explosion_area: Area2D = $ExplosionArea
@onready var explosion_sprite: Sprite2D = $ExplosionArea/ExplosionSprite
@onready var explosion_collision_shape: CollisionShape2D = $ExplosionArea/ExplosionCollisionShape


var _dir:Vector2
var _start_pos:Vector2
var _exploded:bool = false


func _ready() -> void:
    bullet_sprite.show()
    explosion_sprite.hide()
    explosion_area.monitoring = false
    #explosion_area.monitorable = false
    _start_pos = global_position
    body_entered.connect(_on_hit_body)
    
func _physics_process(delta: float) -> void:
    if _exploded:
        return
    global_position += _dir * data.fly_speed * delta
    if global_position.distance_to(_start_pos) >= data.cast_range:
        _explode()
    
func _on_hit_body(body:Node2D)->void:
    if _exploded:
        return
    _explode()

func _explode()->void:
    _exploded = true
    bullet_sprite.hide()
    explosion_sprite.show()
    
    # 将data.damage_range设置为爆炸的CollisionShape的半径
    if explosion_collision_shape.shape == null:
        explosion_collision_shape.shape = CircleShape2D.new()
    explosion_collision_shape.shape.radius = data.damage_range
    explosion_area.monitoring = true
    # 暂停当前函数，等待1帧，让物理引擎完成碰撞更新
    # get_tree()返回当前游戏的场景树实例(全局游戏的根节点)
    # ，process_frame,SceneTree的一个信号，每一帧渲染开始前都会发射一次
    # await暂停当前函数的执行，等后面的信号/计时器触发了再回来继续执行
    await get_tree().physics_frame
    await get_tree().physics_frame

    print_debug("爆炸范围：",explosion_collision_shape.shape.radius)
    print_debug("爆炸地点",global_position)
    # 伤害爆炸范围内的可受伤对象
    for body in explosion_area.get_overlapping_bodies():
        print_debug("获得可攻击body")
        if body.has_method("take_damage"):
            print_debug("take_damage")
            body.take_damage(data.damage)    
    
    var duration:float = data.get("duration_time")
    if duration==null:
        duration = 0.3
    await get_tree().create_timer(duration).timeout
    queue_free()

func set_direction(dir:Vector2)->void:
    _dir = dir.normalized()

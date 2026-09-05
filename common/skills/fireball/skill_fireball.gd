extends Area2D

#region export
@export var damage_range:float = 32 # 伤害范围，直径
@export var animation_duration_time:float = 0.3
@export var bullet_diameter:float = 8 # 子弹直径（像素）
@export var explosion_diameter:float = 32 # 爆炸特效直径（像素）
#endregion

var _data:SkillData
var _dir:Vector2 = Vector2(0,0)
var _start_pos:Vector2
var _exploded:bool = false

@onready var _bullet_sprite: Sprite2D = $BulletSprite
@onready var _explosion_sprite: Sprite2D = $ExplosionSprite

func _ready() -> void:
    # 调整子弹尺寸，爆炸特效尺寸
    _judge_sprite2D_scale(_explosion_sprite,explosion_diameter)
    _judge_sprite2D_scale(_bullet_sprite,bullet_diameter)
    # 显示子弹，隐藏爆炸特效
    _bullet_sprite.show()
    _explosion_sprite.hide()
    # 连接信号
    body_entered.connect(_on_hit_body)
    
func _physics_process(delta: float) -> void:
    if _exploded:
        return
    global_position += _dir * _data.fly_speed * delta
    if global_position.distance_to(_start_pos) >= _data.fly_distance:
        _explode()

func setup(skill_data:SkillData,context:CastContext)->void:
    _data = skill_data
    global_position = context.caster.global_position + context.direction * 10
    _start_pos = global_position
    _dir = context.direction


func set_direction(d:Vector2)->void:
    _dir = d.normalized()

func _on_hit_body(body:Node2D)->void:
    if _exploded:
        return
    _explode()

func _explode()->void:
    _exploded = true
    _bullet_sprite.hide()
    _explosion_sprite.show()

    # 在当前子弹位置，做一次指定半径的圆形范围检测
    # 1. 创建「物理形状查询参数」对象，所有查询条件都配置在这个对象里
    var query = PhysicsShapeQueryParameters2D.new()
    # 2. 指定查询用的形状为圆形
    query.shape = CircleShape2D.new()
    # 3. 设置圆形的半径 = 爆炸范围大小，从技能配置里读
    query.shape.radius = damage_range/2
    # 4. 设置查询的位置和朝向
    #    Transform2D(旋转角度, 中心点坐标)
    #    爆炸不用旋转，角度填0；中心点就是子弹当前的世界坐标
    query.transform = Transform2D(0, global_position)
    # 5. 配置查询目标：检测物理体（CharacterBody2D/StaticBody2D/RigidBody2D）
    query.collide_with_bodies = true
    # 6. 执行查询：获取当前2D物理世界，调用碰撞检测接口，立刻返回所有命中结果
    #    results是一个字典数组，每个元素包含：
    #    - collider：命中的节点对象
    #    - position：碰撞点坐标
    #    - normal：碰撞法线方向
    var results = get_world_2d().direct_space_state.intersect_shape(query)
    
    for result in results:
        # 取出命中的实体节点
        var body = result.collider
        if body.has_method("take_damage"):
            body.take_damage(_data.damage)

    await get_tree().create_timer(animation_duration_time).timeout
    queue_free()



# =========== 工具函数 ===================
func _judge_sprite2D_scale(sprite:Sprite2D,target_diameter:float):
    var tex_size:Vector2 = sprite.texture.get_size()
    var target_scale:float = target_diameter/tex_size.x
    sprite.scale = Vector2(target_scale,target_scale)

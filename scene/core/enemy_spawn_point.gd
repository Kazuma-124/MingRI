extends Node2D
class_name EnemySpawnPoint

# 生成的敌人的场景
@export var enemy_scene:PackedScene
@export var max_count:int = 6 # 最多生成几只
@export var spawn_radius:float = 60
@export var respawn_delay: float = 8.0 # 刷新冷却


var is_spawn_active:bool = false
var spawned_enemies:Array = []
var respawn_timer: float = 0.0

func _ready() -> void:
    EnemyManager.register_spawn_point(self)

# 结点离开SceneTree时调用
func _exit_tree() -> void:
    if EnemyManager:
        EnemyManager.unregister_spawn_point(self)

func _process(delta:float)->void:
    if not is_spawn_active:
        return
    
    if respawn_timer>0:
        respawn_timer-=delta
    if spawned_enemies.size() < max_count:
        if respawn_timer<=0:
            _spawn_one()
            respawn_timer = respawn_delay


func spawn_activate()->void:
    print_debug("spawn_active")
    if is_spawn_active:
        return
    is_spawn_active = true
    _spawn_all()

func spawn_deactivate()->void:
    if not is_spawn_active:
        return
    is_spawn_active = false


func destroy_all()->void:
    for enemy in spawned_enemies:
        if is_instance_valid(enemy):
            enemy.queue_free()
    spawned_enemies.clear()

func _spawn_all()->void:
    for i in max_count-spawned_enemies.size():
        _spawn_one()

func _spawn_one()->void:
    if not enemy_scene:
        return
    var enemy = enemy_scene.instantiate()

    # 随机位置生成
    var offset = Vector2(
        randf_range(-spawn_radius,spawn_radius),
        randf_range(-spawn_radius,spawn_radius)
    )
    enemy.global_position = global_position+offset

    # 添加到场景树
    spawned_enemies.append(enemy)
    get_parent().add_child(enemy)

    enemy.tree_exited.connect(
        func():
            if spawned_enemies.has(enemy):
                spawned_enemies.erase(enemy)
    )

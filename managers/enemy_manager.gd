extends Node

# player vision,1000
@export var slience_radius:float = 100.0
@export var spawn_radius:float = 240.0
@export var destory_radius:float = 260.0 # 销毁半径
# 销毁半径稍微>激活半径

var player:CharacterBase = null
var spawn_points:Array[EnemySpawnPoint] = []

func register_player(p:CharacterBase)->void:
    player = p

func register_spawn_point(sp:EnemySpawnPoint)->void:
    spawn_points.append(sp)

func unregister_spawn_point(sp:EnemySpawnPoint)->void:
    spawn_points.erase(sp)

# 在渲染之前以及物理周期处理完之后，在每个空闲帧上调用。
func _process(delta: float) -> void:
    if not player:
        return
    
    var player_pos = player.global_position
    for sp in spawn_points:
        var dist = player_pos.distance_to(sp.global_position)
        if (dist-slience_radius)>sp.spawn_radius and sp.is_spawn_active:
            sp.spawn_deactivate()
        elif dist < spawn_radius and not sp.is_spawn_active:
            sp.spawn_activate()
        # spawn_radius与destory_radius之间有一段空隙用于生成和销毁的的缓冲
        elif dist > destory_radius:
            sp.spawn_deactivate()
            sp.destroy_all()

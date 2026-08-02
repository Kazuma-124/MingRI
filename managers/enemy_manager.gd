extends Node
class_name EnemyManager


@export var activation_radius:float = 800.0
@export var deactivation_radius:float = 1200.0 # 销毁半径

var player:CharacterBase = null
var spawn_points:Array[EnemySpawnPoint] = []

func register_player(p:CharacterBase)->void:
    player = p

func register_spawn_point(sp:EnemySpawnPoint)->void:
    spawn_points.append(sp)

func unregister_spawn_point(sp:EnemySpawnPoint)->void:
    spawn_points.erase(sp)
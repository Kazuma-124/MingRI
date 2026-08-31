@tool
extends Node2D
class_name EnemySpawnPoint

#region export
# 生成的敌人的场景
@export var enemy_scene:PackedScene
@export var max_count:int = 30 # 最多生成几只
@export var spawn_radius:float = 500
@export var respawn_delay: float = 8.0 # 刷新冷却
#endregion

#region 成员变量
var is_spawn_active:bool = false
var _spawned_enemies:Array = []
var _respawn_timer: float = 0.0
#endregion

#region 生命周期
func _ready() -> void:
	if Engine.is_editor_hint():
		return
	EnemyManager.register_spawn_point(self)

# 结点离开SceneTree时调用
func _exit_tree() -> void:
	if Engine.is_editor_hint():
		return
	if EnemyManager:
		EnemyManager.unregister_spawn_point(self)

func _draw() -> void:
	# 只在编辑器里画，运行时不画
	if not Engine.is_editor_hint():
		return
	# 画一个居中的矩形生成范围
	var rect = Rect2(Vector2(-spawn_radius,-spawn_radius),Vector2(spawn_radius*2,spawn_radius*2))
	draw_rect(rect,GameColors.EDITOR_SPAWN_AREA_FILL)  # 填充
	draw_rect(rect,GameColors.EDITOR_SPAWN_AREA_BORDER, false, 2.0)  # 边框

func _process(delta:float)->void:
	if Engine.is_editor_hint():
			queue_redraw()
	if not is_spawn_active:
		return

	if _respawn_timer>0:
		_respawn_timer-=delta
	if _spawned_enemies.size() < max_count:
		if _respawn_timer<=0:
			_spawn_one()
			_respawn_timer = respawn_delay
#endregion

#region 外部接口
func spawn_activate()->void:
	if is_spawn_active:
		return
	is_spawn_active = true
	_spawn_all()

func spawn_deactivate()->void:
	if not is_spawn_active:
		return
	is_spawn_active = false

func destroy_all()->void:
	for enemy in _spawned_enemies:
		if is_instance_valid(enemy):
			enemy.queue_free()
	_spawned_enemies.clear()
#endregion

#region 内部函数
func _spawn_all()->void:
	for i in max_count-_spawned_enemies.size():
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
	enemy.home_position = global_position
	enemy.home_radius = spawn_radius*2

	# 添加到场景树
	_spawned_enemies.append(enemy)
	get_parent().add_child(enemy)

	enemy.tree_exited.connect(
		func():
			if _spawned_enemies.has(enemy):
				_spawned_enemies.erase(enemy)
	)
#endregion

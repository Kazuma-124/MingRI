extends CharacterBody2D
class_name CharacterBase

# 角色基类：物理帧模板 + 状态翻译层
# 每帧：① BuffManager 更新 ② 未被控制锁定时子类提交自主属性
#      ③ 翻译层把状态结果写入 velocity ④ 动画 ⑤ 运动 ⑥ 运动后反馈

#region 成员变量
var buff_manager: BuffManager
var stat_component: BuffStatComponent
#endregion

#region 外部接口
func add_buff(definition: BuffDefinition, caster: Node = null, dynamic_values: Dictionary = {}) -> void:
	buff_manager.add_buff(definition, caster, dynamic_values)
#endregion

#region 生命周期
func _ready() -> void:
	motion_mode = MotionMode.MOTION_MODE_FLOATING
	stat_component = BuffStatComponent.new(self)
	stat_component.register_stat(StatusStats.SPEED_MULTIPLIER, 1.0)
	buff_manager = BuffManager.new(self, stat_component)

# 物理帧模板，子类只重写钩子，不要重写本方法
func _physics_process(delta: float) -> void:
	# 1. Buff 更新（计时/tick/过期移除/属性重算）
	buff_manager.update(delta)
	# 2. 自主基础属性（硬直/定身时冻结）
	if not _is_base_status_locked():
		_update_base_status(delta)
	# 3. 翻译为引擎实际成员
	_update_final_status(delta)
	# 4. 动画（被控制也照常播放）
	_update_animation()
	# 5. 运动
	move_and_slide()
	# 6. 运动后反馈
	_post_movement(delta)
#endregion

#region 子类钩子
func _update_base_status(_delta: float) -> void:
	pass

func _update_final_status(_delta: float) -> void:
	if buff_manager.has_tag(StatusTags.STAGGERED):
		# 硬直：自主被接管，速度=强制位移
		velocity = buff_manager.get_forced_velocity()
	elif buff_manager.has_tag(StatusTags.ROOTED):
		# 定身：无法自主移动
		velocity = Vector2.ZERO
	else:
		# 正常：自主速度 × 乘数(下限0防反向) + 外力
		var speed_mult: float = stat_component.final(StatusStats.SPEED_MULTIPLIER, 1.0, 0.0)
		velocity = buff_manager.get_self_velocity() * speed_mult + buff_manager.get_external_velocity()

func _update_animation() -> void:
	pass

func _post_movement(_delta: float) -> void:
	pass
#endregion

#region 内部函数
func _is_base_status_locked() -> bool:
	return buff_manager.has_any_tag([StatusTags.STAGGERED, StatusTags.ROOTED])
#endregion

extends CharacterBody2D
class_name CharacterBase

# 角色基类：物理帧模板 + 状态翻译层
# 每帧：① 管理器清槽并驱动效果 ② 未被控制锁定时子类提交自主属性
#      ③ 翻译层把状态结果写入 velocity 等引擎成员 ④ 动画 ⑤ 运动 ⑥ 运动后反馈

#region 成员变量
var status_manager:StatusManager
#endregion

#region 外部接口
# 施加状态效果（转发管理器，技能侧 body.add_buff 调用方式不变）
func add_buff(effect:Buff)->void:
	status_manager.add_buff(effect)
#endregion

#region 生命周期
func _ready()->void:
	motion_mode = MotionMode.MOTION_MODE_FLOATING
	status_manager = StatusManager.new(self)

# 物理帧模板，子类只重写钩子，不要重写本方法
func _physics_process(delta:float)->void:
	# 1. 清槽并驱动效果（数值修饰/控制标签/强制位移在此产出）
	status_manager.update_buffs(delta)
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
# 自主计算并提交（玩家输入/敌人状态机）
func _update_base_status(_delta:float)->void:
	pass

# 翻译层：移动向量区 + 标量乘数 -> velocity
func _update_final_status(_delta:float)->void:
	if status_manager.has_tag(StatusTags.STAGGERED):
		# 硬直：自主被接管，速度=强制位移
		velocity = status_manager.get_forced_velocity()
	elif status_manager.has_tag(StatusTags.ROOTED):
		# 定身：无法自主移动；若同时硬直（上一分支）击退仍可推动
		velocity = Vector2.ZERO
	else:
		# 正常：自主速度 × 乘数(减速/加速) + 非硬直外力；乘数下限 0 防反向
		var speed_mult:float = status_manager.final(StatusStats.SPEED_MULTIPLIER,1.0,0.0)
		velocity = status_manager.get_self_velocity()*speed_mult+status_manager.get_external_velocity()

func _update_animation()->void:
	pass

func _post_movement(_delta:float)->void:
	pass
#endregion

#region 内部函数
# 是否锁定自主基础状态计算：硬直/定身均冻结自主移动产出
func _is_base_status_locked()->bool:
	return status_manager.has_any_tag([StatusTags.STAGGERED,StatusTags.ROOTED])
#endregion

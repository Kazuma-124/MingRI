extends RefCounted
class_name BuffManager

# Buff 管理器：每个角色持有一个，负责该角色身上所有 Buff 的生命周期
# 职责：容器管理、tick 调度、叠加策略分发、强制接管与抑制映射
# 与 StatComponent 联动：Effect 通过本类向属性组件注册/移除 Modifier

#region 信号
signal buff_added(buff_id: StringName, instance: BuffInstance)
signal buff_removed(buff_id: StringName, instance: BuffInstance)
signal buff_stacks_changed(buff_id: StringName, stacks: int)
#endregion

#region 成员变量
var owner_character: Node = null               # 所属角色
var stat_component: BuffStatComponent = null   # 属性计算组件（由角色注入）
var _buffs: Array[BuffInstance] = []           # 所有生效中的 Buff 实例
# 接管属性的buff
var _override_map: Dictionary = {}             # 属性名 -> Array[BuffInstance]（按优先级降序）
var _active_tags: Dictionary = {}           # tag -> int（引用计数）
var self_velocity: Vector2 = Vector2.ZERO   # 自主移动速度（角色每帧设置）
var external_velocity: Vector2 = Vector2.ZERO  # 非硬直外力（牵引等）
var forced_velocity: Vector2 = Vector2.ZERO   # 硬直强制位移（击退 Effect 设置）
#endregion

#region 构造与初始化
func _init(p_owner: Node = null, p_stat_component: BuffStatComponent = null) -> void:
	owner_character = p_owner
	# 注入包含可修改属性和基础值的属性计算组件
	stat_component = p_stat_component
#endregion

#region 外部接口：增删查

# 施加 Buff（由技能/物品调用）
func add_buff(definition: BuffDefinition, caster: Node = null, dynamic_values: Dictionary = {}) -> void:
	if definition == null:
		push_error("BuffManager.add_buff: definition 为 null")
		return

	var existing: BuffInstance = _find_buff(definition.buff_id)

	if existing == null:
		# 全新 buff
		var instance := BuffInstance.new(definition, caster, dynamic_values)
		_buffs.append(instance)
		definition.on_add(instance, self)
		definition.on_apply(instance, self)
		_register_overrides(instance)
		buff_added.emit(definition.buff_id, instance)
	else:
		# 已有同名 buff，按层数选择叠加策略
		if existing.stacks < definition.max_stacks:
			definition.apply_stack_policy_under(existing, caster, dynamic_values, self)
		else:
			definition.apply_stack_policy_full(existing, caster, dynamic_values, self)
		buff_stacks_changed.emit(definition.buff_id, existing.stacks)

# 移除指定 buff（按 buff_id）
func remove_buff(buff_id: StringName) -> void:
	var instance: BuffInstance = _find_buff(buff_id)
	if instance != null:
		_remove_instance(instance)

# 移除施法者施加的所有 buff（施法者死亡/离开场景时调用）
func remove_buffs_by_caster(caster: Node) -> void:
	var i: int = _buffs.size() - 1
	while i >= 0:
		if _buffs[i].caster == caster:
			_remove_instance(_buffs[i])
		i -= 1

# 查询是否存在指定 buff
func has_buff(buff_id: StringName) -> bool:
	return _find_buff(buff_id) != null

# 获取指定 buff 的实例（只读，外部不应直接修改）
func get_buff(buff_id: StringName) -> BuffInstance:
	return _find_buff(buff_id)

# 获取所有 buff 副本（只读遍历用）
func get_all_buffs() -> Array[BuffInstance]:
	return _buffs.duplicate()
#endregion

#region 外部接口：每帧更新（由角色 _physics_process 调用）
func update(delta: float) -> void:
	var i: int = _buffs.size() - 1
	while i >= 0:
		var instance: BuffInstance = _buffs[i]
		if not instance.tick(delta, self):
			# tick 返回 false 表示已过期，on_expire 已在 instance.tick 内调用（默认转发 on_remove）
			_cleanup_instance(instance)
			_buffs.remove_at(i)
			buff_removed.emit(instance.definition.buff_id, instance)
		i -= 1
#endregion

#region 外部接口：属性 Modifier 转发（Effect 调用）

# Effect 注册属性修改器
func add_modifier(modifier: BuffModifier) -> void:
	if stat_component != null:
		stat_component.add_modifier(modifier)

# Effect 移除指定 buff 的所有修改器
func remove_modifiers_from_buff(buff_id: StringName) -> void:
	if stat_component != null:
		stat_component.remove_modifiers_from_buff(buff_id)
# Effect 精确移除指定 buff 下指定 effect 的修改器（抑制/单 Effect 撤掉时调用）
func remove_modifiers_from_effect(buff_id: StringName, effect_id: StringName) -> void:
	if stat_component != null:
		stat_component.remove_modifiers_from_effect(buff_id, effect_id)

# 获取属性最终值（转发 StatComponent）
func get_stat(stat_name: StringName) -> float:
	if stat_component != null:
		return stat_component.get_final_value(stat_name)
	return 0.0

# 兼容旧 StatusManager.final(stat, default, min) 接口
func final(stat_name: StringName, default_value: float = 0.0, min_value: float = -INF) -> float:
	if stat_component != null:
		return stat_component.final(stat_name, default_value, min_value)
	return default_value
#endregion

#region 外部接口：强制接管查询

# 获取当前接管指定属性的 buff（最高优先级生效者）
func get_overriding_buff(attribute: StringName) -> BuffInstance:
	var list: Array = _override_map.get(attribute, [])
	if list.size() > 0:
		return list[0]
	return null

# 查询指定属性是否被任何 buff 接管
func is_attribute_overridden(attribute: StringName) -> bool:
	return get_overriding_buff(attribute) != null
#endregion

#region 外部接口：标签管理（引用计数，多个 buff 可叠加同一标签）
func add_tag(tag: StringName) -> void:
	_active_tags[tag] = _active_tags.get(tag, 0) + 1

func remove_tag(tag: StringName) -> void:
	if _active_tags.has(tag):
		_active_tags[tag] -= 1
		if _active_tags[tag] <= 0:
			_active_tags.erase(tag)

func has_tag(tag: StringName) -> bool:
	return _active_tags.has(tag)

func has_any_tag(tags: Array) -> bool:
	for tag in tags:
		if _active_tags.has(tag):
			return true
	return false
#endregion

#region 外部接口：移动向量（兼容旧 StatusManager 接口，后续可独立为 MovementComponent）
func set_self_velocity(v: Vector2) -> void:
	self_velocity = v

func get_self_velocity() -> Vector2:
	return self_velocity

func set_external_velocity(v: Vector2) -> void:
	external_velocity = v

func get_external_velocity() -> Vector2:
	return external_velocity

func set_forced_velocity(v: Vector2) -> void:
	forced_velocity = v

func get_forced_velocity() -> Vector2:
	return forced_velocity
#endregion


#region 内部函数：容器操作
func _find_buff(buff_id: StringName) -> BuffInstance:
	for instance in _buffs:
		if instance.definition.buff_id == buff_id:
			return instance
	return null

func _remove_instance(instance: BuffInstance) -> void:
	instance.definition.on_remove(instance, self)
	_cleanup_instance(instance)
	_buffs.erase(instance)
	buff_removed.emit(instance.definition.buff_id, instance)

# 清理 instance 产生的所有外部影响（Modifier 兜底清除、接管映射移除）
func _cleanup_instance(instance: BuffInstance) -> void:
	if stat_component != null:
		stat_component.remove_modifiers_from_buff(instance.definition.buff_id)
	_unregister_overrides(instance)
	# 兜底：遍历该 buff 的所有 Effect，撤掉其注册的标签
	for effect in instance.definition.effects:
		if effect is EffectControl:
			for tag in (effect as EffectControl).tags:
				remove_tag(tag)
		if effect is EffectKnockback:
			remove_tag(StatusTags.STAGGERED)
			forced_velocity = Vector2.ZERO

#endregion

#region 内部函数：强制接管与抑制

# 将 instance 注册到其声明的所有接管属性列表中，按优先级降序排序
func _register_overrides(instance: BuffInstance) -> void:
	for attribute in instance.definition.overridden_attributes:
		if not _override_map.has(attribute):
			_override_map[attribute] = []
		var list: Array = _override_map[attribute]
		list.append(instance)
		list.sort_custom(func(a: BuffInstance, b: BuffInstance) -> bool:
			return a.definition.priority > b.definition.priority
		)
		_recalculate_suppression(attribute)

# 从接管映射中移除 instance，并重新计算该属性的抑制状态
func _unregister_overrides(instance: BuffInstance) -> void:
	for attribute in instance.definition.overridden_attributes:
		if _override_map.has(attribute):
			var list: Array = _override_map[attribute]
			list.erase(instance)
			if list.is_empty():
				_override_map.erase(attribute)
			else:
				_recalculate_suppression(attribute)

# 重新计算指定属性的抑制状态：列表[0]（最高优先级）生效，其余被抑制
func _recalculate_suppression(attribute: StringName) -> void:
	var list: Array = _override_map.get(attribute, [])
	for i in range(list.size()):
		var instance: BuffInstance = list[i]
		if i == 0:
			if instance.is_suppressed:
				instance.is_suppressed = false
				_restore_instance(instance)
				instance.definition.on_restored(instance, self)
		else:
			if not instance.is_suppressed:
				instance.is_suppressed = true
				_suppress_instance(instance, list[0].definition)
				instance.definition.on_suppressed(instance, self)

# 应用抑制策略并撤掉被抑制 buff 的所有效果（等同于临时移除）
func _suppress_instance(suppressed: BuffInstance, suppressor: BuffDefinition) -> void:
	match suppressor.suppression_policy:
		BuffEnums.SuppressionPolicy.PAUSE_DURATION:
			suppressed.pause_duration()
			suppressed.pause_tick()
		BuffEnums.SuppressionPolicy.PAUSE_TICK:
			suppressed.pause_tick()
		BuffEnums.SuppressionPolicy.RESET_STACKS:
			suppressed.stacks = 0
		BuffEnums.SuppressionPolicy.REDUCE_DURATION:
			suppressed.time_scale = 2.0
		_:
			pass  # NORMAL_TICK：时间和 tick 都正常，仅效果被撤掉
	suppressed.definition.on_remove(suppressed, self)

# 恢复被抑制的 instance：重置抑制状态并重新应用所有效果
func _restore_instance(instance: BuffInstance) -> void:
	instance.resume_duration()
	instance.resume_tick()
	instance.time_scale = 1.0
	instance.definition.on_apply(instance, self)
#endregion

#region 调试
func get_debug_string() -> String:
	var lines: Array = []
	for instance in _buffs:
		lines.append(instance.get_debug_string())
	return "BuffManager(%d buffs):\n%s" % [_buffs.size(), "\n".join(lines)]
#endregion

extends RefCounted
class_name BuffStatComponent

# BuffStatComponent管理角色所有可被 Buff 影响的属性
# 角色自己定义BuffStatComponent，决定可以调整的属性
# 然后角色把定义好的BuffStatComponent交给BuffManager管理

# 管理角色所有可被 Buff 影响的属性
# 三层公式：最终值 = (基础值 + ΣFLAT_ADD) × (1 + ΣPERCENT_ADD) × Π(1 + MULTIPLY)
# 采用 dirty 标记 + 缓存：标记未脏时，取值才会从新计算，否则直接取用缓存

#region 信号
signal stat_changed(stat_name: StringName, old_value: float, new_value: float)
#endregion

#region 成员变量
var _owner: Node = null                       # 所属角色（用于事件回调）
# 记录基础值同时也负责管理可被修改的属性名集合
var _base_stats: Dictionary = {}              # 属性名 -> 基础值
# 按属性记录对该属性的修改器数组
var _modifiers: Dictionary = {}               # 属性名 -> Array[BuffModifier]（修改器缓存）
var _cached_values: Dictionary = {}           # 属性名 -> 最终值（计算结果缓存）
var _dirty_stats: Dictionary = {}             # 属性名 -> bool（是否需要重算）
#endregion

#region 构造与初始化
func _init(p_owner: Node = null) -> void:
	_owner = p_owner

# 注册基础属性（角色 _ready 时调用，声明哪些属性可被 buff 影响）
func register_stat(stat_name: StringName, base_value: float) -> void:
	_base_stats[stat_name] = base_value
	_modifiers[stat_name] = []
	_cached_values[stat_name] = base_value
	_dirty_stats[stat_name] = false
#endregion

#region 基础值管理
# 通常是角色使用
func set_base_value(stat_name: StringName, value: float) -> void:
	if not _base_stats.has(stat_name):
		push_error("BuffStatComponent: 未注册的属性 %s" % stat_name)
		return
	_base_stats[stat_name] = value
	_mark_dirty(stat_name)

func get_base_value(stat_name: StringName) -> float:
	return _base_stats.get(stat_name, 0.0)
#endregion

#region Modifier 管理
# effect使用
func add_modifier(modifier: BuffModifier) -> void:
	if not _modifiers.has(modifier.stat_name):
		_modifiers[modifier.stat_name] = []
	_modifiers[modifier.stat_name].append(modifier)
	_mark_dirty(modifier.stat_name)

# 移除指定 buff 产生的所有修改器（buff 移除时调用，保证无残留）
func remove_modifiers_from_buff(buff_id: StringName) -> void:
	for stat_name in _modifiers.keys():
		var mods: Array = _modifiers[stat_name]
		var i: int = mods.size() - 1
		while i >= 0:
			if mods[i].source_buff == buff_id:
				mods.remove_at(i)
			i -= 1
		_mark_dirty(stat_name)
# 移除指定 buff 下指定 effect 的所有修改器（抑制/单 Effect 撤掉时调用，避免影响同 buff 的其他 Effect）
func remove_modifiers_from_effect(buff_id: StringName, effect_id: StringName) -> void:
	for stat_name in _modifiers.keys():
		var mods: Array = _modifiers[stat_name]
		var i: int = mods.size() - 1
		while i >= 0:
			if mods[i].source_buff == buff_id and mods[i].source_effect == effect_id:
				mods.remove_at(i)
			i -= 1
		_mark_dirty(stat_name)

func clear_all_modifiers() -> void:
	for stat_name in _modifiers.keys():
		_modifiers[stat_name].clear()
		_mark_dirty(stat_name)
#endregion

#region 属性值查询
func get_final_value(stat_name: StringName) -> float:
	if not _base_stats.has(stat_name):
		return 0.0
	if _dirty_stats.get(stat_name, false):
		_recalculate(stat_name)
	return _cached_values[stat_name]

#endregion

#region 内部计算
func _recalculate(stat_name: StringName) -> void:
	var base: float = _base_stats[stat_name]
	var mods: Array = _modifiers.get(stat_name, [])

	var flat_sum: float = 0.0
	var percent_sum: float = 0.0
	var multiply_product: float = 1.0

	for mod in mods:
		match mod.layer:
			BuffEnums.CalcLayer.FLAT_ADD:
				flat_sum += mod.value
			BuffEnums.CalcLayer.PERCENT_ADD:
				percent_sum += mod.value
			BuffEnums.CalcLayer.MULTIPLY:
				multiply_product *= (1.0 + mod.value)

	var old_value: float = _cached_values.get(stat_name, base)
	var new_value: float = (base + flat_sum) * (1.0 + percent_sum) * multiply_product

	_cached_values[stat_name] = new_value
	_dirty_stats[stat_name] = false

	# 数值有实质变化时派发事件（UI/特效监听）
	if abs(new_value - old_value) > 0.001:
		stat_changed.emit(stat_name, old_value, new_value)

func _mark_dirty(stat_name: StringName) -> void:
	_dirty_stats[stat_name] = true
#endregion

#region 调试
func get_all_stats() -> Dictionary:
	var result: Dictionary = {}
	for stat_name in _base_stats.keys():
		result[stat_name] = get_final_value(stat_name)
	return result
#endregion

extends RefCounted
class_name BuffInstance

# Buff 运行时实例：每次施加创建一个，有状态
# 不写业务逻辑，只负责状态存储和 tick 调度
# 所有"做什么"的逻辑委托给 definition 的无状态回调

#region 成员变量
var definition: BuffDefinition               # 引用静态模板（不复制）
var remaining_time: float                    # 剩余持续时间
var stacks: int = 1                          # 当前层数
var caster: Node = null                      # 施法者引用（伤害归因，使用前需 is_instance_valid）
var tick_accumulator: float = 0.0            # tick 计时器
var is_suppressed: bool = false              # 是否被高优先级 buff 抑制
var time_scale: float = 1.0                  # 时间流逝倍率（抑制策略 REDUCE_DURATION 用）
var dynamic_values: Dictionary = {}          # 施加时传入的动态数值覆盖（技能等级决定的伤害等）
var custom_state: Variant = null             # buff 特有的内部状态（连击计数、已触发次数等）
var _duration_paused: bool = false           # 持续时间是否暂停（抑制策略 PAUSE_DURATION 用）
var _tick_paused: bool = false               # tick 是否暂停（抑制策略 PAUSE_TICK 用）
#endregion

#region 构造
func _init(p_definition: BuffDefinition, p_caster: Node = null, p_dynamic_values: Dictionary = {}) -> void:
	definition = p_definition
	remaining_time = p_definition.base_duration
	caster = p_caster
	dynamic_values = p_dynamic_values
#endregion

#region Tick 调度（由 BuffManager 每帧调用，返回 false 表示已过期需移除）
func tick(delta: float, manager: Object) -> bool:
	# 1. 持续时间计时（永久 buff 或暂停时跳过）
	if definition.base_duration > 0.0 and not _duration_paused:
		remaining_time -= delta * time_scale
		if remaining_time <= 0.0:
			definition.on_expire(self, manager)
			return false

	# 2. tick 触发（tick 暂停或无 tick 时跳过；is_suppressed 不阻止 on_tick 调用，由 Effect 自行判断是否产出生效）
	if definition.tick_interval > 0.0 and not _tick_paused:
		tick_accumulator += delta * time_scale
		while tick_accumulator >= definition.tick_interval:
			tick_accumulator -= definition.tick_interval
			definition.on_tick(self, manager)

	return true
#endregion

#region 状态控制（由 BuffManager 调用，不直接暴露给外部）
func pause_duration() -> void:
	_duration_paused = true

func resume_duration() -> void:
	_duration_paused = false

func pause_tick() -> void:
	_tick_paused = true

func resume_tick() -> void:
	_tick_paused = false

func refresh() -> void:
	remaining_time = definition.base_duration

func add_stack() -> void:
	if stacks < definition.max_stacks:
		stacks += 1
#endregion

#region 数值查询（Effect 计算时调用，优先动态值回退默认值）
func get_dynamic_value(key: StringName, default_value: Variant = null) -> Variant:
	if dynamic_values.has(key):
		return dynamic_values[key]
	return default_value
#endregion

#region 调试
func get_debug_string() -> String:
	return "BuffInstance(%s, stacks=%d, time=%.1f, suppressed=%s)" % [definition.buff_id, stacks, remaining_time, is_suppressed]
#endregion


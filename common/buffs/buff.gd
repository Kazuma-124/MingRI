extends RefCounted
class_name Buff

# 一个"可施加到角色身上的效果"的唯一代表

const DURATION_PERMANENT: float = -1.0


#region 配置区
var buff_id: StringName = &""
var display_name: String = ""
var effects: Array[BuffEffect] = []
var stack_policy_under: BuffEnums.StackPolicy = BuffEnums.StackPolicy.REFRESH_TIME
var stack_policy_full: BuffEnums.StackPolicy = BuffEnums.StackPolicy.REFRESH_TIME
var base_duration: float = 5.0
var max_stacks: int = 1
var tick_interval: float = 0.0
#endregion

#region 运行时区
var runtime: BuffRuntime = null
#endregion


#region 公共接口
func tick(delta: float, manager: BuffManager) -> bool:
    if base_duration > 0.0 and _does_time_pass():
        runtime.remaining_time -= delta
        if runtime.remaining_time <= 0.0:
            return false  # 只上报过期；清理统一由 manager._remove_buff 做，保证恰好一次
    if tick_interval > 0.0 and _does_tick_pass():
        runtime.tick_accumulator += delta
        while runtime.tick_accumulator >= tick_interval:
            runtime.tick_accumulator -= tick_interval
            on_tick(manager)
    return true

# 生命周期回调
# buff施加
func on_add(manager: BuffManager) -> void:
    _sync_effects()
    for effect in effects:
        if effect is BuffActionEffect:
            effect.trigger(manager,BuffEnums.TriggerFlag.ON_APPLY)
        else:
            effect.sync(manager)
func on_tick(manager: BuffManager) -> void:
    _sync_effects()
    for effect in effects:
        if effect is BuffActionEffect:
            effect.trigger(manager,BuffEnums.TriggerFlag.ON_TICK)
func on_stack_added(manager: BuffManager) -> void:
    _sync_effects()
    for effect in effects:
        if effect is BuffActionEffect:
            effect.trigger(manager,BuffEnums.TriggerFlag.ON_STACK_CHANGED)
        else:
            effect.sync(manager)# 默认sync是移除然后再remove
func on_remove(manager: BuffManager) -> void:
    for effect in effects:
        if effect is BuffActionEffect:
            effect.trigger(manager,BuffEnums.TriggerFlag.ON_REMOVE)
        else:
            effect.remove(manager)
func on_refresh(_manager: BuffManager) -> void:
    pass
# OVERRIDE 控制权纯通知（怎么反应完全由本 buff 重写决定）
func on_override_lost(_manager: BuffManager, _stat: StringName) -> void:
    pass
func on_override_gained(_manager: BuffManager, _stat: StringName) -> void:
    pass

func on_custom_stack(_incoming: Buff, _manager: BuffManager) -> void:
    pass

func refresh() -> void:
    runtime.remaining_time = base_duration
func add_stack() -> void:
    if runtime.stacks < max_stacks:
        runtime.stacks += 1
func stack_buff(incoming: Buff, caster: Node, manager: BuffManager) -> void:
    if runtime.stacks < max_stacks:
        _apply_policy(stack_policy_under, incoming, caster, manager)
    else:
        _apply_policy(stack_policy_full, incoming, caster, manager)
func is_permanent() -> bool:
    return base_duration == DURATION_PERMANENT

# 激活：静态buff变为运行时buff
func activate(caster: Node = null) -> void:
    runtime = BuffRuntime.new(base_duration, caster)
#endregion

#region 私有函数

func _add_effect(effect: BuffEffect) -> void:
    effect.source_buff_id = buff_id
    effects.append(effect)

# 运行节奏钩子：默认都推进；被压制想冻结自己的 buff 重写（见 KnockbackBuff）
func _does_time_pass() -> bool:
    return true
func _does_tick_pass() -> bool:
    return true

# 运行时数据 → effect 字段同步（需要 stacks/caster 的 buff 重写）
func _sync_effects() -> void:
    pass

func _apply_policy(policy: BuffEnums.StackPolicy, incoming: Buff,
        caster: Node, manager: BuffManager) -> void:
    match policy:
        BuffEnums.StackPolicy.REFRESH_TIME:
            refresh()
            on_refresh(manager)
        BuffEnums.StackPolicy.ADD_STACK:
            add_stack()
            on_stack_added(manager)
        BuffEnums.StackPolicy.ADD_STACK_AND_REFRESH:
            add_stack()
            refresh()
            on_stack_added(manager)
            on_refresh(manager)
        BuffEnums.StackPolicy.IGNORE:
            pass
        BuffEnums.StackPolicy.OVERRIDE:
            _override_with(incoming,caster,manager)
        BuffEnums.StackPolicy.CUSTOM:
            on_custom_stack(incoming, manager)
    
func _override_with(incoming:Buff,caster:Node,manager:BuffManager)->void:
    on_remove(manager)# 撤掉旧buff的modifier/tag
    effects = incoming.effects
    base_duration = incoming.base_duration
    activate(caster)
    on_add(manager)
#endregion

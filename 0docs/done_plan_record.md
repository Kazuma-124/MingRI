本文件用于临时存档以及完成的plan.md里的内容

存档是为了更新README.md时作为辅助资料，更新完README.md后可以删除存档

用户可能没有按照plan来进行任务，因此下面内容仅供参考，不是权威信息来源，只作为背景信息使用

真更新README.md时还是要以实际项目状态为准，可以参考git仓库的信息，或者实际读取项目结构、相关代码等去了解真实信息

========================================





## C0. Effect 时机模型重构（已落盘文件，按此增量改）

> 旧设计用单值 `apply_phase` 让 buff 挑 effect 在哪个时机调 apply，导致"首次挂载(ON_APPLY)"和"层数变化更新(ON_STACK_CHANGED)"互斥：持续修正设前者则加层不刷新、设后者则首次不生效（slow_buff 里 `apply_phase =` 填什么都不对，根因在此）。两种东西被混进了一个枚举：
>
> - **持续型**（BuffModifierEffect / EffectControl）：目标是"始终维持一个对齐当前状态的效果"。首次=从无到有对齐一次，加层/夺回=再对齐一次，由 buff 在固定生命周期点统一 `sync()`（撤旧挂新、幂等），**不需要选时机**。
> - **瞬时型**（BuffActionEffect）：在某些时机各触发一次、不可撤销，时机可组合，用**位掩码 triggers**。
>
> `apply/remove` 回归 effect 内部底层原语；buff 对外只调 `sync`（持续）或 `trigger`（瞬时）。

### ① buff_enums.gd：删 enum ApplyPhase，换位掩码

```gdscript
#region 瞬时效果触发时机（位掩码，可 | 组合；仅 BuffActionEffect 使用）
enum TriggerFlag {
	ON_APPLY = 1,         # 施加时
	ON_TICK = 2,          # 每个 tick 间隔
	ON_STACK_CHANGED = 4, # 层数变化时
	ON_REMOVE = 8,        # 移除时（如移除时爆炸）
}
#endregion
```

### ② buff_effect.gd 基类：删 apply_phase 与 on_stack_changed，加 sync

```gdscript
extends RefCounted
class_name BuffEffect

var source_buff_id: StringName = &""
var effect_id: StringName = &""

func apply(_manager: BuffManager) -> void:
	pass
func remove(_manager: BuffManager) -> void:
	pass
# 持续态对齐：撤旧再挂、幂等；首次调用时 remove 是空操作。瞬时型不用它
func sync(manager: BuffManager) -> void:
	remove(manager)
	apply(manager)
```

> 旧 on_stack_changed 删除（编排归 buff；且旧写法 `remove()/apply()` 漏传了 manager）。



### ④ buff_action_effect.gd（瞬时型）：加可组合 triggers + trigger

```gdscript
extends BuffEffect
class_name BuffActionEffect

var triggers: int = BuffEnums.TriggerFlag.ON_APPLY  # 可 ON_TICK|ON_REMOVE 组合

func apply(manager: BuffManager) -> void:
	var action := _build_action()
	if action != null:
		manager.execute_action(action)
func remove(_manager: BuffManager) -> void:
	pass
# buff 在每个生命周期点调用，命中本 effect 声明的时机才执行一次
func trigger(manager: BuffManager, flag: int) -> void:
	if triggers & flag:
		apply(manager)
func _build_action() -> BuffAction:
	return null
```

### ⑤ buff.gd：生命周期编排整体替换（删 on_apply 中转与 apply_phase 挑选）

```gdscript
# 持续型在 施加/层数变化 时 sync 对齐、移除时 remove；瞬时型按 triggers 位触发
func on_add(manager: BuffManager) -> void:
	_sync_effects()
	for effect in effects:
		if effect is BuffActionEffect:
			effect.trigger(manager, BuffEnums.TriggerFlag.ON_APPLY)
		else:
			effect.sync(manager)
func on_tick(manager: BuffManager) -> void:
	_sync_effects()
	# 持续型默认不在 tick 重挂；确需随时间刷新的，由 buff 自行调对应 effect.sync(manager)
	for effect in effects:
		if effect is BuffActionEffect:
			effect.trigger(manager, BuffEnums.TriggerFlag.ON_TICK)
func on_stack_added(manager: BuffManager) -> void:
	_sync_effects()
	for effect in effects:
		if effect is BuffActionEffect:
			effect.trigger(manager, BuffEnums.TriggerFlag.ON_STACK_CHANGED)
		else:
			effect.sync(manager)
func on_remove(manager: BuffManager) -> void:
	for effect in effects:
		if effect is BuffActionEffect:
			effect.trigger(manager, BuffEnums.TriggerFlag.ON_REMOVE)
		else:
			effect.remove(manager)
```

- 删除旧 `on_apply`（原 on_add 只转调它）。
- `_override_with` 末尾的 `on_apply(manager)` 改成 `on_add(manager)`；并统一激活方法名（磁盘定义的是 `activate`，`_override_with` 里误写成 `_activate`）。

### ⑥ slow_buff.gd（已落盘，修半成品）

删掉写了一半的 `slow.apply_phase =`（持续型无需声明时机），补 stat/layer，完整见 D.1。

### ⑦ 其余具体 effect

- effect_heal / effect_damage：沿用默认 triggers=ON_APPLY，自身不改；只有"每跳触发"才在 buff 里设 ON_TICK（见 D.3）。
- effect_knockback：持续型，不设 triggers；现有 apply(super+加 tag)/remove(super+减 tag) 不变，sync 继承基类即可正确撤挂 modifier 与 STAGGERED。



------

## D.1 buffs/buffs/slow_buff.gd

```gdscript
extends Buff
class_name SlowBuff

# 未满加层并刷新，已满刷新时间；持续型 effect 由 buff 在 on_add/on_stack_added 自动 sync
# 减速值随层数烘焙进 modifier_effect.value（MOVE_SPEED 的 PERCENT_ADD）

var _slow_effect: BuffModifierEffect
var _slow_percent: float = 0.0

func _init(p_slow_percent: float = 0.2, p_duration: float = 1.0, p_max_stacks: int = 3) -> void:
	buff_id = &"slow"
	display_name = "减速"
	base_duration = p_duration
	max_stacks = p_max_stacks
	stack_policy_under = BuffEnums.StackPolicy.ADD_STACK_AND_REFRESH
	stack_policy_full = BuffEnums.StackPolicy.REFRESH_TIME

	_slow_percent = p_slow_percent
	var slow := BuffModifierEffect.new()
	slow.effect_id = &"slow_speed_mod"
	slow.stat_name = StatusStats.MOVE_SPEED
	slow.calc_layer = BuffEnums.CalcLayer.PERCENT_ADD
	_add_effect(slow)
	_slow_effect = slow

func _sync_effects() -> void:
	_slow_effect.value = -_slow_percent * runtime.stacks
```

## D.2 definitions/knockback_buff.gd（自定义抑制反应范例）

```gdscript
extends Buff
class_name KnockbackBuff

# FORCED_VELOCITY OVERRIDE + STAGGERED；叠加 OVERRIDE：用新击退数值覆盖自身（_override_with）
# 被更高优先级击退顶掉时自己冻结时间/tick，夺回时恢复

var _control_frozen: bool = false  # 本 buff 自有状态，非框架字段

func _init(p_direction: Vector2, p_speed: float = 200.0, p_duration: float = 0.4) -> void:
	buff_id = &"knockback"
	display_name = "击退"
	base_duration = p_duration
	max_stacks = 1
	stack_policy_under = BuffEnums.StackPolicy.OVERRIDE
	stack_policy_full = BuffEnums.StackPolicy.OVERRIDE

	var kb := EffectKnockback.new()
	kb.effect_id = &"knockback_effect"
	kb.value = p_direction.normalized() * p_speed
	_add_effect(kb)

func on_override_lost(_manager: BuffManager, stat: StringName) -> void:
	if stat == StatusStats.FORCED_VELOCITY:
		_control_frozen = true

func on_override_gained(_manager: BuffManager, stat: StringName) -> void:
	if stat == StatusStats.FORCED_VELOCITY:
		_control_frozen = false

func _does_time_pass() -> bool:
	return not _control_frozen
func _does_tick_pass() -> bool:
	return not _control_frozen
```

## D.3 definitions/heal_over_time_buff.gd

```gdscript
extends Buff
class_name HealOverTimeBuff

# HoT：持续存活的 buff，每个 tick 产出一个瞬时 HealAction
func _init(p_heal_per_tick: float = 5.0, p_duration: float = 3.0, p_tick_interval: float = 0.5) -> void:
	buff_id = &"heal_over_time"
	display_name = "持续回复"
	base_duration = p_duration
	max_stacks = 1
	tick_interval = p_tick_interval
	stack_policy_under = BuffEnums.StackPolicy.REFRESH_TIME
	stack_policy_full = BuffEnums.StackPolicy.REFRESH_TIME

	var effect := EffectHeal.new()
	effect.effect_id = &"heal_on_tick_effect"
	effect.triggers = BuffEnums.TriggerFlag.ON_TICK
	effect.heal_amount = p_heal_per_tick
	_add_effect(effect)
```

------

# Part E 角色层与调用点

## E.1 character_base.gd

```gdscript
extends CharacterBody2D
class_name CharacterBase

# 每帧：① buff 更新 ② 未锁定时子类提交方向/速率(SET_BASE)
#      ③ converter 出最终 velocity ④ 动画 ⑤ 运动 ⑥ 运动后反馈

var attribute_system: AttributeSystem
var buff_manager: BuffManager
var converter: AttributeConverter

func add_buff(buff: Buff, caster: Node = null) -> void:
	buff_manager.add_buff(buff, caster)

func _ready() -> void:
	motion_mode = MotionMode.MOTION_MODE_FLOATING
	_init_attribute_system()
	buff_manager = BuffManager.new(self, attribute_system, converter)

# 中性默认值由 StatusStats.DEFAULTS 提供，一行批量注册；角色不逐项传 base
func _init_attribute_system() -> void:
	attribute_system = AttributeSystem.new(self)
	attribute_system.register_all_defaults()
	converter = AttributeConverter.new(attribute_system)

func _physics_process(delta: float) -> void:
	buff_manager.update(delta)
	if not _is_base_status_locked():
		_update_base_status(delta)
	_update_final_status(delta)
	_update_animation()
	move_and_slide()
	_post_movement(delta)

func _update_base_status(_delta: float) -> void:
	pass
func _update_final_status(_delta: float) -> void:
	velocity = converter.get_final_velocity()
func _update_animation() -> void:
	pass
func _post_movement(_delta: float) -> void:
	pass

func _is_base_status_locked() -> bool:
	return attribute_system.has_any_tag([StatusTags.STAGGERED, StatusTags.ROOTED])
```

## E.2 player.gd（提交方向与速率 + 每帧逸散）

```gdscript
func _update_base_status(delta: float) -> void:
	_update_dir_status()
	_update_skill_status(delta)
	# 方向与速率分离提交；_move_dir 已是单位向量（静止为 ZERO），_move_speed 为基础速率
	attribute_system.set_base_value(StatusStats.MOVE_DIRECTION, _move_dir)
	attribute_system.set_base_value(StatusStats.MOVE_SPEED, _move_speed)

func _update_skill_status(delta: float) -> void:
	_state.update_skill_cooldowns(delta)
	_state.dissipate_if_overflow()
```

## E.3 test_enemy.gd（状态机向量拆成方向/速率，安全归一化）

```gdscript
func _update_base_status(_delta: float) -> void:
	_update_super_state(_delta)  # 内部仍用局部 velocity 向量推进状态机
	var move_dir: Vector2 = velocity.normalized() if velocity.length() > 0.0001 else Vector2.ZERO
	attribute_system.set_base_value(StatusStats.MOVE_DIRECTION, move_dir)
	attribute_system.set_base_value(StatusStats.MOVE_SPEED, velocity.length())
```

## E.4 skill_shockwave.gd

```gdscript
var dir := (body.global_position - global_position).normalized()
var knockback_speed: float = knockback_distance / effect_duration
body.add_buff(KnockbackBuff.new(dir, knockback_speed, effect_duration), _caster)
```

## E.5 skill_frost_field.gd

```gdscript
body.add_buff(SlowBuff.new(1.0 - slow_factor, slow_duration, 3), _caster)
```






extends RefCounted
class_name StatusManager


#region 枚举
enum Op {
	BASE,		# 基础值（角色提交）
	ADD,		# 固定加算
	ADD_PCT,	# 百分比加算（Σ 进同一加算乘区）
	MUL,		# 独立乘区（Π 连乘）
	OVERRIDE,		# 覆盖
}
#endregion

#region 成员变量
var _owner:CharacterBase					# 持有本管理器的角色
var _buffs:Array[Buff] = []		# 活跃效果列表
# A. 标量属性槽（按操作分类，键为属性 StringName）
var _base_slot:Dictionary = {}
var _add_slot:Dictionary = {}
var _add_pct_slot:Dictionary = {}
var _mul_slot:Dictionary = {}
var _override_slot:Dictionary = {}
# B. 控制标签集合（Dictionary 模拟 Set：tag -> true）
var _tags:Dictionary = {}
# C. 移动向量
var _self_velocity:Vector2 = Vector2.ZERO		# 角色自主速度
var _forced_velocity:Vector2 = Vector2.ZERO		# 硬直强制位移
var _external_velocity:Vector2 = Vector2.ZERO	# 非硬直外力，叠加到自主速度
#endregion

#region 生命周期
func _init(owner:CharacterBase)->void:
	_owner = owner

# 帧首：清空全部槽位，再驱动存活效果重新贡献
func update_buffs(delta:float)->void:
	_clear_slots()
	# 反向遍历：遍历途中移除失效元素不会打乱未遍历索引
	for i in range(_buffs.size()-1,-1,-1):
		if not _buffs[i].update(delta,self):
			_buffs[i].remove(self)
			_buffs.remove_at(i)# 将后面的所有元素前移1位

func _clear_slots()->void:
	_base_slot.clear()
	_add_slot.clear()
	_add_pct_slot.clear()
	_mul_slot.clear()
	_override_slot.clear()
	_tags.clear()
	_self_velocity = Vector2.ZERO
	_forced_velocity = Vector2.ZERO
	_external_velocity = Vector2.ZERO
#endregion

#region 效果管理
func add_buff(effect:Buff)->void:
	_buffs.append(effect)

func get_buff_count()->int:
	return _buffs.size()
#endregion

#region A. 标量属性：贡献接口
# 统一入口：op 操作类型，stat 属性键，value 数值
func change_stat_slot(op:Op,stat:StringName,value:float)->void:
	match op:
		Op.BASE:
			_set_base(stat,value)
		Op.ADD:
			_add(stat,value)
		Op.ADD_PCT:
			_add_pct(stat,value)
		Op.MUL:
			_mul(stat,value)
		Op.OVERRIDE:
			_override(stat,value)

func _set_base(stat:StringName,value:float)->void:
	if _base_slot.has(stat):
		push_warning("StatusManager: 属性 %s 的 BASE 本帧已提交，应只设置1次"%stat)
	_base_slot[stat] = value

func _add(stat:StringName,value:float)->void:
	_add_slot[stat] = _add_slot.get(stat,0.0)+value

func _add_pct(stat:StringName,value:float)->void:
	_add_pct_slot[stat] = _add_pct_slot.get(stat,0.0)+value

func _mul(stat:StringName,value:float)->void:
	_mul_slot[stat] = _mul_slot.get(stat,1.0)*value

func _override(stat:StringName,value:float)->void:
	_override_slot[stat] = value
#endregion

#region A. 标量属性：查询接口
# default_value：无 BASE 且无修饰时的缺省值（乘数类属性应传 1.0）
func final(stat:StringName,default_value:float = 0.0,min_value:float = -INF,max_value:float = INF)->float:
	if _override_slot.has(stat):
		return clampf(_override_slot[stat],min_value,max_value)
	var result:float = _base_slot.get(stat,default_value)
	result += _add_slot.get(stat,0.0)
	result *= 1.0+_add_pct_slot.get(stat,0.0)
	result *= _mul_slot.get(stat,1.0)
	return clampf(result,min_value,max_value)
#endregion

#region B. 控制标签
# 效果每帧贡献标签
func add_tag(tag:StringName)->void:
	_tags[tag] = true

func has_tag(tag:StringName)->bool:
	return _tags.has(tag)

# 持有给定标签中的任意一个即为 true
func has_any_tag(tags:Array)->bool:
	for t in tags:
		if _tags.has(t):
			return true
	return false
#endregion

#region C. 移动向量
# 角色提交自主速度（输入/状态机产出）
func set_self_velocity(vel:Vector2)->void:
	_self_velocity = vel

# 硬直强制位移贡献（击退，多效果向量累加，配合 STAGGERED 标签）
func add_forced_velocity(vel:Vector2)->void:
	_forced_velocity += vel

# 非硬直外力贡献（推挤/风流，累加到自主速度）
func add_external_velocity(vel:Vector2)->void:
	_external_velocity += vel

func get_self_velocity()->Vector2:
	return _self_velocity

func get_forced_velocity()->Vector2:
	return _forced_velocity

func get_external_velocity()->Vector2:
	return _external_velocity
#endregion

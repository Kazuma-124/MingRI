extends RefCounted
class_name BuffManager

# buff 施加的效果有两种；
#   add_modifier（持续修正 → 中间属性） / execute_action（瞬时动作 → 目标）

#region 信号
signal buff_added(buff_id: StringName, buff: Buff)
signal buff_removed(buff_id: StringName, buff: Buff)
signal buff_stacks_changed(buff_id: StringName, stacks: int)
#endregion

#region 成员变量
var owner_character: Node = null
var attrs: AttributeSystem = null
var converter: AttributeConverter = null
var _buffs: Array[Buff] = []
#endregion


#region 构造
func _init(p_owner: Node = null, p_attrs: AttributeSystem = null,
        p_converter: AttributeConverter = null) -> void:
    owner_character = p_owner
    attrs = p_attrs
    converter = p_converter
    # 传递信号
    if attrs != null:
        attrs.override_winner_changed.connect(_on_override_winner_changed)
#endregion

#region 公共接口
func add_buff(incoming: Buff, caster: Node = null) -> void:
    if incoming == null:
        push_error("BuffManager.add_buff: buff 为 null")
        return
    var existing := _find_buff(incoming.buff_id)
    if existing == null:
        incoming.activate(caster)# 静态buff激活为运行时buff
        _buffs.append(incoming)
        incoming.on_add(self)
        buff_added.emit(incoming.buff_id, incoming)
    else:
        existing.stack_buff(incoming, caster, self)
        buff_stacks_changed.emit(existing.buff_id, existing.runtime.stacks)

func replace_buff(old_buff: Buff, new_buff: Buff, caster: Node = null) -> void:
    _remove_buff(old_buff)  # 内部已 erase + on_remove
    new_buff._activate(caster)
    _buffs.append(new_buff)
    new_buff.on_add(self)
func remove_buff(buff_id: StringName) -> void:
    var buff := _find_buff(buff_id)
    if buff != null:
        _remove_buff(buff)
func remove_buffs_by_caster(caster:Node2D)->void:
    for i in range(_buffs.size()-1,-1,-1):
        if _buffs[i].runtime.caster == caster:
            _remove_buff(_buffs[i])

func has_buff(buff_id: StringName) -> bool:
    return _find_buff(buff_id) != null
func get_buff(buff_id: StringName) -> Buff:
    return _find_buff(buff_id)
func get_all_buffs() -> Array[Buff]:
    return _buffs.duplicate()

func update(delta:float)->void:
    for i in range(_buffs.size()-1,-1,-1):
        if not _buffs[i].tick(delta,self):
            _remove_buff(_buffs[i])

func add_modifier(modifier:BuffModifier)->void:
    attrs.add_modifier(modifier)
func remove_modifiers_from_buff_effect(buff_id:StringName,effect_id:StringName)->void:
    attrs.remove_modifiers_from_buff_effect(buff_id,effect_id)
func remove_modifiers_from_buff(buff_id:StringName)->void:
    attrs.remove_modifiers_from_buff(buff_id)
func get_stat(stat_name:StringName)->Variant:
    return attrs.get_final_value(stat_name)

func execute_action(action:BuffAction)->void:
    if action==null:
        return
    action.execute(owner_character,converter)

func add_tag(tag:StringName)->void:
    attrs.add_tag(tag)
func remove_tag(tag: StringName) -> void:
    attrs.remove_tag(tag)
func has_tag(tag: StringName) -> bool:
    return attrs.has_tag(tag)
func has_any_tag(tags: Array) -> bool:
    return attrs.has_any_tag(tags)
#endregion

#region 私有函数
func _find_buff(buff_id:StringName)->Buff:
    for buff in _buffs:
        if buff.buff_id==buff_id:
            return buff
    return null
func _remove_buff(buff:Buff)->void:
    _buffs.erase(buff)
    buff.on_remove(self)
    _cleanup_buff(buff)
    buff_removed.emit(buff.buff_id,buff)
func _cleanup_buff(buff:Buff)->void:
    remove_modifiers_from_buff(buff.buff_id)# effect.remove也会清理

func _on_override_winner_changed(stat:StringName,old_id:StringName,new_id:StringName)->void:
    if old_id!=&"":
        var loser:=_find_buff(old_id)
        if loser!=null:
            # 告知在哪个stat上被抑制了
            loser.on_override_lost(self,stat)
    if new_id!=&"":
        var winner:=_find_buff(new_id)
        if winner!=null:
            winner.on_override_gained(self,stat)
#endregion


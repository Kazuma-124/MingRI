extends Node
class_name SkillCaster

#region 枚举
enum CastState{
    IDLE,
    AIMING
}
#endregion

#region 成员
var _cast_state:SkillCaster.CastState = CastState.IDLE
var _aiming_skill_id:StringName = &""
var _aiming_skill:SkillData = null
var _indicator:SkillIndicator = null
var _caster:CharacterBody2D
#endregion

#region 信号
signal cast_started(skill_id:StringName)
signal cast_cancelled(skill_id:StringName)
signal cast_confirmed(skill_id:StringName)
#endregion

#region 公共接口
func setup(player_ref:CharacterBody2D)->void:
    _caster = player_ref
    # 加入场景树，使 _process / _unhandled_input 自动生效
    _caster.add_child(self)

func is_aiming()->bool:
    return _cast_state == CastState.AIMING

func cast_skill(skill_id:StringName)->void:
    # 正在瞄准时再按技能 → 取消当前瞄准, 释放新技能
    if _cast_state == CastState.AIMING:
        _cancel_cast()

    var skill_data:SkillData = _get_skill_data(skill_id)
    if not skill_data:
        return

    # 检查能否释放
    var state = _caster.get_state()
    if not state.can_cast(skill_id):
        return

    # INSTANT 类型直接释放
    if skill_data.targeting_type == SkillData.TargetingType.INSTANT:
        _instant_cast(skill_id, skill_data)
        return

    # DIRECTION / POSITION / TARGET → 进入瞄准
    _enter_aiming(skill_id, skill_data)

func cast_primary_skill()->bool:
    # 普攻不需要瞄准，点击鼠标自动释放
    # 获取state中普攻id
    var state = _caster.get_state()
    if state.primary_attack_skill_ids.size() == 0:
        return false
    var primary_id:StringName = state.curr_primary_attack_skill_id
    var skill_data:SkillData = _get_skill_data(primary_id)
    if not skill_data:
        return false
    return _instant_cast(primary_id, skill_data)
#endregion

#region 内部函数
func _instant_cast(skill_id:StringName, skill_data:SkillData)->bool:
    var state = _caster.get_state()
    if not state.try_cast_skill(skill_id):
        return false
    if not skill_data.scene:
        return true

    # 构建即时释放上下文（方向取当前鼠标方向）
    var ctx := CastContext.new()
    ctx.caster = _caster
    ctx.direction = (_caster.get_global_mouse_position() - _caster.global_position).normalized()
    ctx.position = _caster.global_position

    var instance = skill_data.scene.instantiate()
    if instance.has_method("setup"):
        instance.setup(skill_data, ctx)
    _caster.get_parent().add_child(instance)
    return true

func _enter_aiming(skill_id:StringName, skill_data:SkillData)->void:
    _cast_state = CastState.AIMING
    _aiming_skill_id = skill_id
    _aiming_skill = skill_data

    # 创建并挂载指示器
    _indicator = _create_indicator(_aiming_skill)
    if _indicator:
        _caster.add_child(_indicator)
        _indicator.setup(_aiming_skill, _caster)

    cast_started.emit(skill_id)

func _create_indicator(skill_data:SkillData)->SkillIndicator:
    match skill_data.targeting_type:
        SkillData.TargetingType.DIRECTION:
            return SkillIndicatorDirection.new()
        SkillData.TargetingType.POSITION:
            return SkillIndicatorPosition.new()
        SkillData.TargetingType.TARGET:
            return SkillIndicatorTarget.new()
    return null

func _unhandled_input(event:InputEvent)->void:
    if _cast_state != CastState.AIMING:
        return
    if event is InputEventMouseButton and event.pressed:
        match event.button_index:
            MOUSE_BUTTON_LEFT:
                _confirm_cast()
                get_viewport().set_input_as_handled()
            MOUSE_BUTTON_RIGHT:
                _cancel_cast()
                get_viewport().set_input_as_handled()

func _confirm_cast()->void:
    # 指示器无效则视为取消
    if not _indicator or not _indicator.get_is_valid():
        _cancel_cast()
        return

    # 消耗能量 + 开始冷却
    var state = _caster.get_state()
    if not state.confirm_cast(_aiming_skill_id):
        _cancel_cast()
        return

    # 从指示器取最终瞄准数据，补全施法者信息
    var ctx:CastContext = _indicator.generate_castcontext()
    ctx.caster = _caster

    # 生成技能实例
    if _aiming_skill.scene:
        var instance = _aiming_skill.scene.instantiate()
        if instance.has_method("setup"):
            instance.setup(_aiming_skill, ctx)
        _caster.get_parent().add_child(instance)

    cast_confirmed.emit(_aiming_skill_id)
    _exit_aiming()

func _cancel_cast()->void:
    cast_cancelled.emit(_aiming_skill_id)
    _exit_aiming()

func _exit_aiming()->void:
    if _indicator:
        _indicator.queue_free()
        _indicator = null
    _cast_state = CastState.IDLE
    _aiming_skill = null
    _aiming_skill_id = &""

func _get_skill_data(skill_id:StringName)->SkillData:
    return _caster.get_state().get_skill_data(skill_id)
#endregion

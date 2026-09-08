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
signal cast_executed(skill_id:StringName,ctx:CastContext)
#endregion

#region 公共接口
func setup(player_ref:CharacterBody2D)->void:
    _caster = player_ref
    # 加入场景树，使 _process / _unhandled_input 自动生效
    _caster.add_child(self)

func is_aiming()->bool:
    return _cast_state == CastState.AIMING

func cast_skill(skill_id:StringName,quick:bool=false)->void:
    # 正在瞄准时再按技能 → 取消当前瞄准, 释放新技能
    if _cast_state == CastState.AIMING:
        _cancel_cast()
    var skill_data:SkillData = _get_skill_data(skill_id)
    if not skill_data:
        return

    # state检查能否释放
    var state = _caster.get_state()
    if not state.can_cast(skill_id):
        return

    # 快捷释放：有锁定且在范围内->直接释放
    if quick:
        var locked_target:Node2D = _caster.get_locked_target()
        if locked_target and is_instance_valid(locked_target):
            if _is_target_in_cast_range(skill_data,locked_target):
                _quick_cast(skill_id,skill_data,locked_target)
                return
        # 没有锁定对象或锁定对象不在施法范围内，则进入正常施法流程

    # INSTANT 类型直接释放
    if skill_data.targeting_type == SkillData.TargetingType.INSTANT:
        _instant_cast(skill_id, skill_data)
        return

    # DIRECTION / POSITION / TARGET → 进入瞄准
    _enter_aiming(skill_id, skill_data)

func get_indicator()->SkillIndicator:
    return _indicator

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

    # 构建即时释放上下文（方向取当前鼠标方向）
    var ctx := CastContext.new()
    ctx.caster = _caster
    var instant_data := skill_data as SkillDataInstant
    if instant_data:
        match instant_data.direction_mode:
            SkillDataInstant.DirectionMode.MOUSE_DIRECTION:
                ctx.direction = (_caster.get_global_mouse_position()-_caster.global_position).normalized()
            SkillDataInstant.DirectionMode.CASTER_FACING:
                ctx.direction = _caster.get_facing()
            SkillDataInstant.DirectionMode.NONE:
                ctx.direction = Vector2.ZERO
    else:
        ctx.direction = (_caster.get_global_mouse_position()-_caster.global_position).normalized()

    if skill_data.scene:
        var instance = skill_data.scene.instantiate()
        if instance.has_method("setup"):
            instance.setup(skill_data, ctx)
        _caster.get_parent().add_child(instance)
    # 通知外部玩家，技能已释放，用于更新朝向等
    cast_executed.emit(skill_id,ctx)
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

func _quick_cast(skill_id:StringName,skill_data:SkillData,target:Node2D)->void:
    if not is_instance_valid(target):
        return
    var state = _caster.get_state()
    # can_cast在一开始进行过判断了
    if not state.confirm_cast(skill_id):
        return
    var ctx := CastContext.new()
    ctx.caster = _caster
    match skill_data.targeting_type:
        SkillData.TargetingType.INSTANT:
            var instant_data:=skill_data as SkillDataInstant
            if instant_data and instant_data.direction_mode==SkillDataInstant.DirectionMode.NONE:
                ctx.direction = Vector2.ZERO
            else:
                ctx.direction = (target.global_position-_caster.global_position).normalized()
        SkillData.TargetingType.DIRECTION:
            ctx.direction = (target.global_position-_caster.global_position).normalized()
        SkillData.TargetingType.POSITION:
            ctx.position = target.global_position
            ctx.shape_rotation = 0.0
        SkillData.TargetingType.TARGET:
            ctx.target = target

    # 生成技能实例
    if skill_data.scene:
        var instance = skill_data.scene.instantiate()
        if instance.has_method("setup"):
            instance.setup(skill_data,ctx)
        # 先setup，再加入场景树，因为_ready()可能用到一些setup设定的数据
        _caster.get_parent().add_child(instance)

    cast_executed.emit(skill_id,ctx) 

func _confirm_cast()->void:
    # 指示器无效则视为取消
    if not _indicator or not _indicator.get_is_valid():
        _cancel_cast()
        return

    # 从指示器取最终瞄准数据，补全施法者信息
    var ctx:CastContext = _indicator.generate_castcontext()
    ctx.caster = _caster

    _exit_aiming()

    # 尝试施法，消耗能量 + 开始冷却
    var state = _caster.get_state()
    if not state.confirm_cast(_aiming_skill_id):
        _cancel_cast()
        return

    # 生成技能实例
    if _aiming_skill.scene:
        var instance = _aiming_skill.scene.instantiate()
        if instance.has_method("setup"):
            instance.setup(_aiming_skill, ctx)
        _caster.get_parent().add_child(instance)

    cast_executed.emit(_aiming_skill_id,ctx)

    # cast_confirmed.emit(_aiming_skill_id)

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

func _is_target_in_cast_range(skill_data:SkillData,target:Node2D)->bool:
    var dist := target.global_position.distance_to(_caster.global_position)
    match skill_data.targeting_type:
        SkillData.TargetingType.POSITION:
            var pos_data := skill_data as SkillDataPosition
            return dist <= pos_data.cast_range
        SkillData.TargetingType.TARGET:
            var tar_data := skill_data as SkillDataTarget
            return dist <= tar_data.cast_range
        _: # INSTANT / DIRECTION 无施法距离限制
            return true


#endregion

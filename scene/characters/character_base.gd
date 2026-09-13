extends CharacterBody2D
class_name CharacterBase


var attribute_system:AttributeSystem
var buff_manager:BuffManager
var converter:AttributeConverter



func _ready()->void:
    # CharacterBoyd2D的一个二选一的枚举变量，决定运动模式
    # 俯视角，无重力就是MOTION_MODE_FLOATING; 平台条约，有重力，就是MOTION_MODE_GROUNDED 
    motion_mode = MotionMode.MOTION_MODE_FLOATING

    _init_attribute_system()
    buff_manager = BuffManager.new(self,attribute_system,converter)



#region 公共接口
func add_buff(buff:Buff,caster:Node=null)->void:
    buff_manager.add_buff(buff,caster)
#endregion



#region 私有函数
func _init_attribute_system()->void:
    attribute_system = AttributeSystem.new(self)
    attribute_system.register_all_defaults()
    # 定制converter
    converter = AttributeConverter.new(attribute_system)

func _physics_process(delta: float) -> void:
    buff_manager.update(delta)
    _update_passive_status(delta)
    if not _is_autonomy_locked():
        _update_base_status(delta)
    _update_final_status(delta)
    _update_animation()
    move_and_slide()
    _post_movement(delta)
func _update_passive_status(_delta:float)->void:
    pass
func _update_base_status(_delta:float)->void:
    pass
func _update_final_status(_delta:float)->void:
    velocity = converter.get_final_velocity()
func _update_animation()->void:
    pass
func _post_movement(_delta:float)->void:
    pass
func _is_autonomy_locked()->bool:
    return attribute_system.has_any_tag([StatusTags.STAGGERED,StatusTags.ROOTED])
#endregion
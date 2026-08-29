extends Node2D

@export var _radius:float = 24.0
@export var _color:Color = GameColors.LOCK_TARGET_RING

var _target:Node2D = null

#region 接口函数
func set_target(target:Node2D)->void:
    _target = target
    visible = target!=null and is_instance_valid(target)
    if visible:
        global_position = _target.global_position
        queue_redraw()
#endregion


#region 内部函数
func _ready() -> void:
    visible = false
    z_index = 10

func _process(_delta:float)->void:
    if _target:
        if is_instance_valid(_target):
            global_position = _target.global_position
            queue_redraw()
        else:
            # 目标已死亡，自动清除
            _target = null
            visible = false

func _draw() -> void:
    if not _target or not is_instance_valid(_target):
        return
    draw_circle(Vector2.ZERO,_radius,_color,false,2.0,true)
#endregion
extends Control
class_name Draggable

#region @export
@export var target: Control = null          # 要移动的目标节点，留空则移动自己
@export var drag_handle: Control = null     # 拖动把手，留空则监听自己
@export var save_key: StringName = &""
@export var auto_center_on_start: bool = true
#endregion

#region 成员变量
var _dragging: bool = false
var _drag_offset: Vector2 = Vector2.ZERO
#endregion

#region 静态变量
static var _saved_positions: Dictionary = {}
#endregion

#region 内置函数
func _ready() -> void:
    # 没指定 target 就移动自己
    if target == null:
        target = self
    # 没指定 drag_handle 就监听自己的鼠标事件
    var handle = drag_handle if drag_handle else self
    handle.gui_input.connect(_on_handle_input)
    _restore_position()
#endregion

#region 内部方法
func _restore_position() -> void:
    if save_key != &"" and _saved_positions.has(save_key):
        target.global_position = _saved_positions[save_key]
    elif auto_center_on_start:
        _center_in_viewport()

func _center_in_viewport() -> void:
    var vp_size = get_viewport().get_visible_rect().size
    target.global_position = (vp_size - target.size) / 2.0

func _save_position() -> void:
    if save_key != &"":
        _saved_positions[save_key] = target.global_position
#endregion

#region 信号处理
func _on_handle_input(event: InputEvent) -> void:
    var handle = drag_handle if drag_handle else self
    
    if event is InputEventMouseButton:
        if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
            _dragging = true
            _drag_offset = get_global_mouse_position() - target.global_position
            handle.set_input_as_handled()
        
        elif not event.pressed and _dragging and event.button_index == MOUSE_BUTTON_LEFT:
            _dragging = false
            _save_position()
            handle.set_input_as_handled()

    elif event is InputEventMouseMotion and _dragging:
        target.global_position = get_global_mouse_position() - _drag_offset
        handle.set_input_as_handled()
#endregion
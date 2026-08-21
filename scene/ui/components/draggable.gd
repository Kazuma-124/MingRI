extends Control
class_name Draggable

#region 常量,枚举
enum Corner{
    TL,
    TR,
    BL,
    BR
}
#endregion

#region @export
@export var target: Control = null          # 要移动的目标节点，留空则移动自己
@export var drag_handle: Control = null     # 拖动把手，留空则监听自己
@export var save_key: StringName = &""      # 非空时跨实例记忆位置与尺寸(见 _saved_window_state)
@export var auto_center_on_start: bool = false

@export var resize_tl:Control = null        # 四个角上的缩放把手;为 null 则该角不可拖
@export var resize_tr:Control = null
@export var resize_bl:Control = null
@export var resize_br:Control = null
# 拖拽缩放的“硬下限”。只是兜底值:实际下限会被 set_content_min() 抬到“内容所需尺寸”
  # 之上(内容比它大时以内容为准),所以它只保证一个最小保障,不限制实际窗口下限更大。
@export var min_size:Vector2 = Vector2(100,100)
#endregion

#region 成员变量
var _dragging: bool = false
var _drag_offset: Vector2 = Vector2.ZERO
var _resizing:bool = false
var _resize_corner:Draggable.Corner = Corner.TL #0=TL,1=TR,2=BL,3=BR
var _resize_start_pos:Vector2 = Vector2.ZERO
var _resize_start_size:Vector2 = Vector2.ZERO
var _resize_start_mouse:Vector2 = Vector2.ZERO
#endregion

#region 静态变量
static var _saved_window_state: Dictionary = {} # 按 save_key 记忆各窗口的位置/尺寸
#endregion

#region 内置函数
func _ready() -> void:
    # 没指定 target 就移动自己
    if target == null:
        target = self
    # 初始防止窗口小于下限(此时min_size可能已被set_content_min设定为内容尺寸)
    target.size.x = max(target.size.x,min_size.x)
    target.size.y = max(target.size.y,min_size.y)
    
    
    # 拖动
    # 没指定 drag_handle 就监听自己的鼠标事件
    var handle = drag_handle if drag_handle else self
    handle.gui_input.connect(_on_drag_input)
    if resize_tl:
        resize_tl.gui_input.connect(func(e):_on_resize_input(e,Corner.TL))
    if resize_tr:
        resize_tr.gui_input.connect(func(e):_on_resize_input(e,Corner.TR))
    if resize_bl:
        resize_bl.gui_input.connect(func(e):_on_resize_input(e,Corner.BL))
    if resize_br:
        resize_br.gui_input.connect(func(e):_on_resize_input(e,Corner.BR))
    # 四角的鼠标形状
    # 左上、右下：↘↖ 方向双箭头
    if resize_tl:
        resize_tl.mouse_default_cursor_shape = Control.CURSOR_FDIAGSIZE
    if resize_br:
        resize_br.mouse_default_cursor_shape = Control.CURSOR_FDIAGSIZE
    # 右上、左下：↙↗ 方向双箭头
    if resize_tr:
        resize_tr.mouse_default_cursor_shape = Control.CURSOR_BDIAGSIZE
    if resize_bl:
        resize_bl.mouse_default_cursor_shape = Control.CURSOR_BDIAGSIZE


    _restore_window_state()
#endregion



#region 外部接口
## 把拖拽缩放的下限同步成“内容所需尺寸”。
## 背景:窗口是普通 Control,不会随内容自动变大。内容(如展开 LearnableItems)变高变宽后,
## 若下限仍是固定 min_size,会出现两个问题:① 能把窗口拖得比内容还小(拖进内容里);
## ② 展开后窗口包不住内容(Panel 比窗口大)。
## 做法:
##   1) min_size = 内容最小尺寸 与 硬下限 的逐分量较大者 —— 保证“不低于内容”;
##   2) 若当前窗口比内容小,立刻撑大到内容 —— 解决“展开后 Panel 比窗口大”。
## 由 SkillBook 在内容尺寸变化时(初始化/填充列表/展开收起)调用。
func set_content_min(v:Vector2)->void:
    # 抬下限:内容所需 与 硬下限 取大
    min_size = v.max(Vector2(100,100))
    # 撑大到内容所需尺寸(若已更大则 max 后不变);下限已由上面的 min_size 保证
    target.size = target.size.max(min_size)

# 把拖拽下限设成内容所需尺寸,并让窗口尺寸随下限同量平移,保留窗口与下限间的间隙
# (用户手动放大过的尺寸会被保留;展开/收起时窗口随内容一起长大/折叠)
func set_content_min_keep_margin(v: Vector2) -> void:
    var new_min := v.max(Vector2(100, 100))
    target.size += new_min - min_size          # 下限变多少,窗口同步变多少(保留间隙)
    min_size = new_min
    target.size = target.size.max(min_size)    # 兜底:不低于下限

#endregion

#region 内部方法
func _restore_window_state() -> void:
    if save_key != &"" and _saved_window_state.has(save_key):
        var data = _saved_window_state[save_key]
        target.position = data["position"]
        target.size = data["size"]
    #没有存档信息就保持默认位置(编辑器里放置的位置) 
    # elif auto_center_on_start:
    #     _center_in_viewport()
    # else:
    #     _return_default_position()

# func _center_in_viewport() -> void:
#     var vp_size = get_viewport().get_visible_rect().size
#     target.position = (vp_size - target.size) / 2.0
# func _return_default_position()->void:
#     pass

func _save_window_state() -> void:
    if save_key != &"":
        _saved_window_state[save_key] = {
            "position":target.position,
            "size":target.size
        }
#endregion

#region 信号处理
# 拖动位置
func _on_drag_input(event: InputEvent) -> void:
    
    if event is InputEventMouseButton:
        if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
            _dragging = true
            # 记录“鼠标相对窗口位置的偏移”,拖动时窗口跟随鼠标但要扣除这个偏移,避免跳变
            _drag_offset = get_global_mouse_position() - target.global_position
            get_viewport().set_input_as_handled()
        
        elif not event.pressed and _dragging and event.button_index == MOUSE_BUTTON_LEFT:
            _dragging = false
            _save_window_state()
            get_viewport().set_input_as_handled()

    elif event is InputEventMouseMotion and _dragging:
        # ...Motion 表示鼠标或笔的移动。
        # 鼠标在把手上移动且正在拖动:窗口位置 = 最新鼠标位置 - 初始偏移
        target.global_position = get_global_mouse_position() - _drag_offset
        get_viewport().set_input_as_handled()
func _on_resize_input(event:InputEvent,corner:Draggable.Corner)->void:
    if event is InputEventMouseButton:
        print_debug()
        if event.pressed and event.button_index==MOUSE_BUTTON_LEFT:
            _resizing = true
            _resize_corner = corner
            _resize_start_pos = target.position
            _resize_start_size = target.size
            _resize_start_mouse = get_global_mouse_position()
            get_viewport().set_input_as_handled()
        elif not event.pressed and _resizing and event.button_index==MOUSE_BUTTON_LEFT:
            # 调整大小结束，保存状态
            _resizing = false
            _save_window_state()
            get_viewport().set_input_as_handled()
    elif event is InputEventMouseMotion and _resizing:
        var delta = get_global_mouse_position()-_resize_start_mouse
        var new_pos = _resize_start_pos
        var new_size = _resize_start_size
        # 推导基于:窗口以“左上角”为固定锚点(锚点 0,0)。position是左上角
        match _resize_corner:
            Corner.TL:
                # 向左上角拉动，pos与delta方向相同+，size与delta方向相反-
                new_pos.x = _resize_start_pos.x+delta.x
                new_pos.y = _resize_start_pos.y+delta.y
                new_size.x = _resize_start_size.x-delta.x
                new_size.y = _resize_start_size.y-delta.y
            Corner.TR:
                # 向右上角拉动，pos.x不会被影响, pos.y与delta方向相同+
                #              size.x与delta方向相同+, size.y与delta方向相反-
                # new_pos.x = _resize_start_pos.x
                new_pos.y = _resize_start_pos.y+delta.y
                new_size.x = _resize_start_size.x+delta.x
                new_size.y = _resize_start_size.y-delta.y
            Corner.BL:
                # 向左下角拉动，pos.x与delta方向相同+, pos.y不受影响
                #              size.x与delta方向相反-, size.y与delta方向相同+
                new_pos.x = _resize_start_pos.x+delta.x
                # new_pos.y = _resize_start_pos.y
                new_size.x = _resize_start_size.x-delta.x
                new_size.y = _resize_start_size.y+delta.y
            Corner.BR:
                # 向右下角拉动，pos.x不受影响, pos.y不受影响
                #              size.x与delta方相同+, size.y与delta方向相同+
                # new_pos.x = _resize_start_pos.x
                # new_pos.y = _resize_start_pos.y
                new_size.x = _resize_start_size.x+delta.x
                new_size.y = _resize_start_size.y+delta.y

        # 缩放下限保护:任何方向都不允许小于 min_size(已被 set_content_min 抬到内容尺寸)。
        # new_size无论小于还是大于min_size都能正常起效
        target.size.x = max(min_size.x,new_size.x)
        target.size.y = max(min_size.y,new_size.y)
        # 只有拖动后的new_size大于min_size，才更新对应position
        if new_size.x>=min_size.x:
            target.position.x = new_pos.x
        if new_size.y>=min_size.y:
            target.position.y = new_pos.y
        # 鼠标移动的输入
        get_viewport().set_input_as_handled()
    pass
#endregion

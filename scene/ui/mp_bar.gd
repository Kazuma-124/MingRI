extends Control
class_name MpBar

# ===== 子节点引用 =====
@onready var background: ColorRect = $Background
@onready var chiyan_mp_bar: ColorRect = $ChiyanMpBar
@onready var shengxi_mp_bar: ColorRect = $ShengxiMpBar
@onready var shuangxuan_mp_bar: ColorRect = $ShuangxuanMpBar
@onready var youying_mp_bar: ColorRect = $YouyingMpBar

# ===== 数据 =====
var max_mp: float = 1000.0
var mps: Array[float] = [0.0, 0.0, 0.0, 0.0]

# 能量条 UI 数组，索引对应 AttributeTypes.Type
var _mp_bars: Array[ColorRect] = []

# 动画
var tween: Tween

func _ready() -> void:
    background.size = size
    background.position = Vector2.ZERO
    
    # 把四个能量条放到数组里，顺序和 AttributeTypes.Type 一致
    _mp_bars = [
        chiyan_mp_bar,
        shengxi_mp_bar,
        shuangxuan_mp_bar,
        youying_mp_bar,
    ]
    
    # 设置颜色
    _mp_bars[AttributeTypes.Type.CHIYAN].color = AttributeTypes.CHIYAN_COLOR
    _mp_bars[AttributeTypes.Type.SHENGXI].color = AttributeTypes.SHENGXI_COLOR
    _mp_bars[AttributeTypes.Type.SHUANGXUAN].color = AttributeTypes.SHUANGXUAN_COLOR
    _mp_bars[AttributeTypes.Type.YOUYING].color = AttributeTypes.YOUYING_COLOR

func set_mp(attr: AttributeTypes.Type, value: float) -> void:
    mps[attr] = value
    _update_bars_animated()

func set_all_mp(mps_input: Array[float], max: float) -> void:
    if max > 0:
        max_mp = max
        mps = mps_input
        _update_bars_immediate()

# ===== 内部方法：更新动画 =====

# 带动画地更新
func _update_bars_animated() -> void:
    if tween:
        tween.kill()
    
    tween = create_tween()
    tween.set_ease(Tween.EASE_IN_OUT)
    tween.set_trans(Tween.TRANS_SINE)
    
    var total_width = size.x
    var x = 0.0
    
    for i in range(AttributeTypes.Type.size()):
        var bar_width = (mps[i] / max_mp) * total_width
        tween.tween_property(_mp_bars[i], "position:x", x, 0.3)
        tween.tween_property(_mp_bars[i], "size:x", bar_width, 0.3)
        x += bar_width

# 立即更新（无动画，初始化用）
func _update_bars_immediate() -> void:
    var total_width = size.x
    var x = 0.0
    
    for i in range(AttributeTypes.Type.size()):
        var bar_width = (mps[i] / max_mp) * total_width
        _mp_bars[i].position.x = x
        _mp_bars[i].size.x = bar_width
        x += bar_width

# 尺寸变化时重新计算
func _size_changed() -> void:
    _update_bars_immediate()


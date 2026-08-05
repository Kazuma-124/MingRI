extends Control
class_name MpBar

# ===== 子节点引用 =====
@onready var background: ColorRect = $Background
@onready var chiyan_mp_bar: ColorRect = $ChiyanMpBar
@onready var shengxi_mp_bar: ColorRect = $ShengxiMpBar
@onready var shuangxuan_mp_bar: ColorRect = $ShuangxuanMpBar
@onready var youying_mp_bar: ColorRect = $YouyingMpBar

var max_mp:float
var chiyan_mp:float
var shengxi_mp:float
var shuangxuan_mp:float
var youying_mp:float

# 动画
var tween:Tween

func _ready() -> void:
    background.size = size
    background.position = Vector2.ZERO
    background.color = Color(0.2, 0.2, 0.2, 0.8)
    chiyan_mp_bar.color = AttributeTypes.CHIYAN_COLOR
    shengxi_mp_bar.color = AttributeTypes.SHENGXI_COLOR
    shuangxuan_mp_bar.color = AttributeTypes.SHUANGXUAN_COLOR
    youying_mp_bar.color = AttributeTypes.YOUYING_COLOR
    _update_bars_immediate()

# === 公共接口

func set_mp(attr:AttributeTypes.Type,value:float):
    match attr:
        AttributeTypes.Type.CHIYAN:
            chiyan_mp = value
        AttributeTypes.Type.SHENGXI:
            shengxi_mp = value
        AttributeTypes.Type.SHUANGXUAN:
            shuangxuan_mp = value
        AttributeTypes.Type.YOUYING:
            youying_mp = value
    _update_bars_immediate()

func set_all_mp(
    chiyan:float,
    shengxi:float,
    shuangxuan:float,
    youying:float,
    max:float
)->void:
    if max > 0:
        max_mp = max
    chiyan_mp = chiyan
    shengxi_mp = shengxi
    shuangxuan_mp = shuangxuan
    youying_mp = youying
    _update_bars_animated()

func bind_to_state(state:PlayerRuntimeState)->void:
    state.mp_changed.connect(_on_mp_changed)
    set_all_mp(
        state.chiyan_mp,
        state.shengxi_mp,
        state.shuangxuan_mp,
        state.youying_mp,
        state.max_mp
    )

# == 信号
func _on_mp_changed(attr:AttributeTypes.Type,cur:float)->void:
    set_mp(attr,cur)

# == 内部方法，更新动画
# 带动画地更新
func _update_bars_animated() -> void:
    # 停止之前的动画
    if tween:
        tween.kill()
    
    tween = create_tween()
    tween.set_ease(Tween.EASE_IN_OUT)
    tween.set_trans(Tween.TRANS_SINE)
    
    # 计算目标位置和宽度
    var total_width = size.x
    var x = 0.0
    
    # 赤焰
    var chiyan_width = (chiyan_mp / max_mp) * total_width
    tween.tween_property(chiyan_mp_bar, "position:x", x, 0.3)
    tween.tween_property(chiyan_mp_bar, "size:x", chiyan_width, 0.3)
    x += chiyan_width
    
    # 生息
    var shengxi_width = (shengxi_mp / max_mp) * total_width
    tween.tween_property(shengxi_mp_bar, "position:x", x, 0.3)
    tween.tween_property(shengxi_mp_bar, "size:x", shengxi_width, 0.3)
    x += shengxi_width
    
    # 霜玄
    var shuangxuan_width = (shuangxuan_mp / max_mp) * total_width
    tween.tween_property(shuangxuan_mp_bar, "position:x", x, 0.3)
    tween.tween_property(shuangxuan_mp_bar, "size:x", shuangxuan_width, 0.3)
    x += shuangxuan_width
    
    # 幽影
    var youying_width = (youying_mp / max_mp) * total_width
    tween.tween_property(youying_mp_bar, "position:x", x, 0.3)
    tween.tween_property(youying_mp_bar, "size:x", youying_width, 0.3)

# 立即更新（无动画，初始化用）
func _update_bars_immediate() -> void:
    var total_width = size.x
    var x = 0.0
    
    var chiyan_width = (chiyan_mp / max_mp) * total_width
    chiyan_mp_bar.position.x = x
    chiyan_mp_bar.size.x = chiyan_width
    x += chiyan_width
    
    var shengxi_width = (shengxi_mp / max_mp) * total_width
    shengxi_mp_bar.position.x = x
    shengxi_mp_bar.size.x = shengxi_width
    x += shengxi_width
    
    var shuangxuan_width = (shuangxuan_mp / max_mp) * total_width
    shuangxuan_mp_bar.position.x = x
    shuangxuan_mp_bar.size.x = shuangxuan_width
    x += shuangxuan_width
    
    var youying_width = (youying_mp / max_mp) * total_width
    youying_mp_bar.position.x = x
    youying_mp_bar.size.x = youying_width

# 尺寸变化时重新计算
func _size_changed() -> void:
    _update_bars_immediate()
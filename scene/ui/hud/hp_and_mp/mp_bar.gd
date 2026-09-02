extends Control
class_name MPBar


#region 成员变量
# ===== 数据 =====
var _max_mp: float = 1000.0
var _mps: Array[float] = [0.0, 0.0, 0.0, 0.0]

# 能量条 UI 数组，索引对应 AttributeTypes.Type
var _mp_bars: Array[ColorRect] = []

# 动画
var _tween: Tween
#endregion

#region onready
# ===== 子节点引用 =====
@onready var _chiyan_mp_bar: ColorRect = $ChiyanMpBar
@onready var _shengxi_mp_bar: ColorRect = $ShengxiMpBar
@onready var _shuangxuan_mp_bar: ColorRect = $ShuangxuanMpBar
@onready var _youying_mp_bar: ColorRect = $YouyingMpBar
#endregion

#region 生命周期
func _ready() -> void:
	# background.size = size
	# background.position = Vector2.ZERO

	# 把四个能量条放到数组里，顺序和 AttributeTypes.Type 一致
	_mp_bars = [
		_chiyan_mp_bar,
		_shengxi_mp_bar,
		_shuangxuan_mp_bar,
		_youying_mp_bar,
	]

	# 设置颜色
	_mp_bars[AttributeTypes.Type.CHIYAN].color = AttributeTypes.CHIYAN_COLOR
	_mp_bars[AttributeTypes.Type.SHENGXI].color = AttributeTypes.SHENGXI_COLOR
	_mp_bars[AttributeTypes.Type.SHUANGXUAN].color = AttributeTypes.SHUANGXUAN_COLOR
	_mp_bars[AttributeTypes.Type.YOUYING].color = AttributeTypes.YOUYING_COLOR

	# 信号
	resized.connect(_size_changed)
#endregion

#region 外部接口
func set_mp(attr: AttributeTypes.Type, value: float) -> void:
	_mps[attr] = value
	_update_bars_animated()

func set_all_mp(mps_input: Array[float], max: float) -> void:
	if max > 0:
		_max_mp = max
		_mps = mps_input
		_update_bars_immediate()
#endregion

#region 内部函数
# ===== 内部方法：更新动画 =====

# 带动画地更新
func _update_bars_animated() -> void:
	if _tween:
		_tween.kill()

	_tween = create_tween()
	_tween.set_ease(Tween.EASE_IN_OUT)
	_tween.set_trans(Tween.TRANS_SINE)

	var total_width = size.x
	var x = 0.0

	for i in range(AttributeTypes.Type.size()):
		var bar_width = (_mps[i] / _max_mp) * total_width
		if i == 0:
			# 第一个作为基准 step
			_tween.tween_property(_mp_bars[i], "position:x", x, 0.3)
		else:
			# 后续都与基准并行
			_tween.parallel().tween_property(_mp_bars[i], "position:x", x, 0.3)
		_tween.parallel().tween_property(_mp_bars[i], "size:x", bar_width, 0.3)
		x += bar_width

# 立即更新（无动画，初始化用）
func _update_bars_immediate() -> void:
	var total_width = size.x
	var x = 0.0

	for i in range(AttributeTypes.Type.size()):
		var bar_width = (_mps[i] / _max_mp) * total_width
		_mp_bars[i].position.x = x
		_mp_bars[i].size.x = bar_width
		x += bar_width
#endregion

#region 信号处理
# 尺寸变化时重新计算
func _size_changed() -> void:
	_update_bars_immediate()
#endregion



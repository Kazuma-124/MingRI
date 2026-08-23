extends IndicatorShape
class_name RectIndicatorShape

# 矩形指示器形状
# length:  沿施法方向（局部 +X）的边长度
# width:   垂直施法方向（局部 Y 轴）的边长度
#          - centered=false 时 = 正对玩家的短边长度
#          - centered=true  时 = 上下边之间的距离（矩形幅宽）
# centered=true:  锚点 = 矩形中心（位置类技能，形状以鼠标位置为中心）
# centered=false: 锚点 = 左边缘中点（方向类线型技能，从施法者出发向 +X 延伸）

#region 参数
@export var length: float
@export var width: float
@export var centered: bool = true
#endregion

#region 绘制
func draw(canvas: CanvasItem, color: Color) -> void:
    var half_width := width / 2.0
    var x_start: float
    var x_end: float
    if centered:
        x_start = -length / 2.0
        x_end = length / 2.0
    else:
        x_start = 0.0
        x_end = length
    canvas.draw_colored_polygon(
        PackedVector2Array([
            Vector2(x_start, -half_width),
            Vector2(x_end, -half_width),
            Vector2(x_end, half_width),
            Vector2(x_start, half_width),
        ]),
        color
    )
#endregion

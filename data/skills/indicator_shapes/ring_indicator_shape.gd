extends IndicatorShape
class_name RingIndicatorShape

# 锚点 = 圆心
# 用带切割线的多边形构造填充环形（外边界逆时针 + 内边界顺时针）
#region 参数
@export var outer_radius: float = 64.0
@export var inner_radius: float = 32.0
@export var segments: int = 24  # 每段圆弧的分段数
#endregion


#region 绘制
func draw(canvas: CanvasItem, color: Color) -> void:
    var points := PackedVector2Array()
    # 外圆弧：从角度 0 逆时针走一圈
    for i in range(segments + 1):
        var t := float(i) / float(segments)
        var a := t * TAU
        points.append(Vector2(cos(a), sin(a)) * outer_radius)
    # 内圆弧：从角度 TAU 顺时针走一圈（与外圆形成切割线连接）
    for i in range(segments + 1):
        var t := float(i) / float(segments)
        var a := TAU - t * TAU
        points.append(Vector2(cos(a), sin(a)) * inner_radius)
    canvas.draw_colored_polygon(points, color)
#endregion
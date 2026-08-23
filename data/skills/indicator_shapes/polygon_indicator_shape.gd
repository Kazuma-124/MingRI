extends IndicatorShape
class_name PolygonIndicatorShape

# 任意多边形指示器形状
# 形状在局部坐标系下绘制，原点为形状中心，由指示器结点控制位置和旋转

#region 参数
@export var points:PackedVector2Array = PackedVector2Array()
#endregion

#region 虚接口
# canvas，调用绘制的CanvasItem，通常是指示器节点自身
# color 颜色
func draw(canvas:CanvasItem,color:Color)->void:
    if points.size()<3:
        return
    canvas.draw_colored_polygon(points,color)
#endregion
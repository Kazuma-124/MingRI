extends IndicatorShape
class_name CircleIndicatorShape

# 圆形指示器形状

#region 参数
@export var radius:float
#endregion

#region 绘制
# canvas，调用绘制的CanvasItem，通常是指示器节点自身
# color 颜色
func draw(canvas:CanvasItem,color:Color)->void:
    canvas.draw_circle(Vector2.ZERO,radius,color)
#endregion
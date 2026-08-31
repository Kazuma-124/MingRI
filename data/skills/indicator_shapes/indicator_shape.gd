extends Resource
class_name IndicatorShape

# 指示器形状抽象基类
# 所有具体形状继承此类实现
# 形状在局部坐标系下绘制，原点为形状中心，由指示器节点控制位置和旋转

#region 虚接口
# canvas，调用绘制的CanvasItem，通常是指示器节点自身
# color 颜色
func draw(canvas:CanvasItem,color:Color)->void:
    push_warning("Indicator Shape.draw() must be overridden by subclass")
#endregion
extends IndicatorShape
class_name SectorIndicatorShape

# 扇形指示器形状
# 扇形中心朝向局部+X方向, 由指示器节点rotation控制实际朝向

#region 参数
@export var radius:float
@export var angle_deg:float # 扇形总角度
@export var segments:int = maxi(8, int(ceil(angle_deg / 15.0)))# 圆弧分段数，越大越平滑，每15°一段，最少8段
#endregion

#region 虚接口
# canvas，调用绘制的CanvasItem，通常是指示器节点自身
# color 颜色
func draw(canvas:CanvasItem,color:Color)->void:
    # 角度值转为弧度值
    var angle_rad := deg_to_rad(angle_deg)
    # 通过绘制多边形绘制扇形
    var points := PackedVector2Array()
    # 圆心
    points.append(Vector2.ZERO)
    # 圆弧顶点
    for i in range(segments+1):
        var t := float(i)/float(segments)
        var a := -angle_rad/2 + t*angle_rad
        points.append(Vector2(cos(a),sin(a))*radius)
    canvas.draw_colored_polygon(points,color)
#endregion
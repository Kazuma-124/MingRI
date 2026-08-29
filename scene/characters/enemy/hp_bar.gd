extends Node2D

@export var width:float = 32
@export var height:float = 4
@export var bg_color:Color = GameColors.HP_BAR_BG
@export var fg_color:Color = GameColors.HP_BAR_FG

var _ratio:float = 1.0

func set_ratio(ratio:float)->void:
    # 保证在[0.0,1.0]范围内的赋值
    _ratio = clamp(ratio,0.0,1.0)
    queue_redraw()

func _draw() -> void:
    # draw_rect(矩形在局部坐标系中的定义,颜色,是否填充,空心时的线宽,是否抗锯齿)
    # 背景框,Rect2(左上角.x,左上角.y,宽度,高度)
    draw_rect(Rect2(-width/2,-height/2,width,height),bg_color,true)
    # 前景血条
    var fg_w = width*_ratio
    draw_rect(Rect2(-width/2,-height/2,fg_w,height),fg_color,true)
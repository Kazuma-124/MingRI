# res://data/attribute_types.gd
extends RefCounted
class_name AttributeTypes


enum Type {
    CHIYAN,
    SHENGXI,
    SHUANGXUAN,
    YOUYING,
}

const NAMES: Dictionary = {
    Type.CHIYAN: "赤焰",
    Type.SHENGXI: "生息",
    Type.SHUANGXUAN: "霜玄",
    Type.YOUYING: "幽影",
}

# ===== 颜色配置 =====
const CHIYAN_COLOR: Color = Color(0.9, 0.2, 0.2)    # 赤焰：红
const SHENGXI_COLOR: Color = Color(0.2, 0.8, 0.3)   # 生息：绿
const SHUANGXUAN_COLOR: Color = Color(0.2, 0.5, 0.9) # 霜玄：蓝
const YOUYING_COLOR: Color = Color(0.6, 0.2, 0.9)   # 幽影：紫

extends Resource
class_name SkillData

# 技能在代码中的唯一标识
var id: String
# 技能在游戏中显示的名称
var name: String
# 所属能量体系：flame/life/frost/shadow
var element: String = "flame"
# 技能类型：projectile投射物，melee近战，aoe范围，buff状态
var skill_type: String  # projectile / melee / aoe / buff
# 基础伤害
var damage: float = 0.0
var cooldown: float = 2.0
# 释放距离
var cast_range: float = 200.0
var energy_cost: float = 0.0
# 解锁所需修炼等级
var unlock_level: int = 1
# ===== 吟唱相关 =====
var cast_time: float = 0.0          # 吟唱前摇时间（秒），0就是瞬发
var is_channeled: bool = false      # 是否是通道技能（持续施法）
var channel_duration: float = 0.0   # 通道持续时间
var can_interrupt: bool = true      # 是否可以被打断
# 技能图标
var icon: Texture2D
# 特效场景
var effect_scene: PackedScene
# 技能描述文本
var description: String

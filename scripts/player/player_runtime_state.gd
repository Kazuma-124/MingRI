extends RefCounted
class_name PlayerRuntimeState

# === 基础等级
var base_level:int = 1
var base_exp:int = 0
# === 四属性等级
var chiyan_level:int = 1
var chiyan_exp:int = 0

var shengxi_level:int = 1
var shengxi_exp:int = 0

var shuangxuan_level:int = 1
var shuangxuan_exp:int = 0

var youying_level:int = 1
var youying_exp:int = 0


# === 属性
var max_hp:float = 100.0
var max_mp:float = 1000.0

var cur_hp:float = 100.0
var cur_mp:float = 1000.0




var learned_skills:Array[SkillData] = []
var primary_attack_skills:Array[SkillData] = []
var skill_slots:Array[SkillData] = [] # 索引是槽位号

# var save_position:Vector2 = Vector2.ZERO
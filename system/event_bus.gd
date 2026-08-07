extends Node
# 全局事件总线（Autoload 单例）
# 所有模块通过它收发消息，互不直接依赖

# ==========================================
# 玩家状态变化事件（数据 → UI）
# ==========================================

signal player_hp_changed(cur: float, max: float)
signal player_mp_changed(attr: int, cur: float)
signal player_mp_all_changed(chiyan: float, shengxi: float, shuangxuan: float, youying: float, max: float)

# ==========================================
# 技能槽状态变化事件（数据 → UI）
# ==========================================
signal equiped_skill_changed(slot_id:int,skill:SkillData)
signal equiped_skill_cooldown_updated(slot_id:int,ratio:float,remaining:float)

# ==========================================
# UI 输入事件（UI → 逻辑）
# ==========================================

signal equiped_skill_slot_clicked(slot_id:int)
extends Node
# 全局事件总线（Autoload 单例）
# 所有模块通过它收发消息，互不直接依赖

# ==========================================
# 玩家状态变化事件（数据 → UI）
# ==========================================

signal player_hp_changed(cur: float, max: float)
signal player_mp_changed(attr: int, cur: float)
signal player_mp_all_changed(mp:Array[float], max: float)

# ==========================================
# 技能槽状态变化事件（数据 → UI）
# ==========================================
signal player_primary_attack_switched(skill_id:StringName)
signal shortcut_skill_changed(slot_id:int,skill_id:StringName)

# ==========================================
# UI 输入事件（UI → 逻辑）
# ==========================================
signal primary_attack_slot_clicked()
signal shortcut_slot_clicked(slot_id:int)
signal skill_book_skill_clicked(skill_id:StringName)

# #region 消除未使用警告
# func aaa()->void:
#     player_hp_changed.get_name()
#     player_mp_changed.get_name()
#     player_mp_all_changed.get_name()
#     player_primary_attack_switched.get_name()
#     shortcut_skill_changed.get_name()
#     primary_attack_slot_clicked.get_name()
#     shortcut_slot_clicked.get_name()
#     skill_book_skill_clicked.get_name()
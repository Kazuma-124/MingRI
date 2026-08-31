extends Node
# 全局事件总线（Autoload 单例）
# 所有模块通过它收发消息，互不直接依赖

#region 信号
signal player_hp_changed(cur: float, max: float)
signal player_mp_changed(attr: int, cur: float)
signal player_mp_all_changed(mp:Array[float], max: float)

signal player_primary_attack_switched(skill_id:StringName)
signal shortcut_skill_changed(slot_id:int,skill_id:StringName)

signal hud_action_pressed(action:StringName)
signal skill_book_toggle_requested()

signal primary_attack_slot_clicked()
signal shortcut_slot_clicked(slot_id:int)
signal skill_book_skill_clicked(skill_id:StringName)
signal skill_book_quick_cast(skill_id:StringName)
#endregion

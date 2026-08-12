extends PanelContainer
class_name SkillShortcutBar

@export var slot_ui_scene:PackedScene

# 技能槽引用数组
var primary_slot:SkillSlotUI
var skill_slots: Array[SkillSlotUI] = []

@onready var slots_container: HBoxContainer = $SlotsContainer


func _ready() -> void:
    if GameManager.current_player:
        _init_after_player(GameManager.current_player)
    else:
        GameManager.player_initialized.connect(_on_player_initialized)
func _on_player_initialized(player:CharacterBody2D)->void:
    _init_after_player(player)
    GameManager.player_initialized.disconnect(_on_player_initialized)

func _init_after_player(p:CharacterBody2D)->void:
    # 普攻,点击->EventBus.primary_attack_slot_clicked->state.switch_primary
    primary_slot = slot_ui_scene.instantiate()
    slots_container.add_child(primary_slot)
    primary_slot.clicked.connect(
        func() ->void:
            EventBus.primary_attack_slot_clicked.emit()
    )

    var count = p.data.skill_slot_count
    for i in range(count):
        var slot_ui = slot_ui_scene.instantiate()
        skill_slots.append(slot_ui)
        slots_container.add_child(slot_ui)
        slot_ui.clicked.connect(
            func()->void:
                EventBus.shortcut_slot_clicked.emit(i)
        )
    primary_slot.set_skill(p.state.get_skill_data(p.state.curr_primary_attack_skill_id)) 
    for i in range(count):
        var skill_id:StringName = p.state.get_slot_skill_id(i) 
        var data:SkillData = p.state.get_skill_data(skill_id) if skill_id!=&"" else null
        skill_slots[i].set_skill(data)

    EventBus.player_primary_attack_switched.connect(_on_primary_skill_switched)
    EventBus.shortcut_slot_skill_changed.connect(_on_slot_skill_changed)
    # # EventBus.skill_cooldown_updated.connect(_on_cooldown_updated)
#     # GameManager.current_player.init_skill_slots_signal()

func _on_primary_skill_switched(skill_id):
    primary_slot.set_skill(SkillLibrary.get_skill(skill_id))
func _on_slot_skill_changed(slot_id: int, skill_id: StringName) -> void:
    if slot_id >= 0 && slot_id < skill_slots.size():
        skill_slots[slot_id].set_skill(SkillLibrary.get_skill(skill_id))

func _on_cooldown_updated(slot_id: int, ratio: float, remaining: float) -> void:
    if slot_id >= 0 && slot_id < skill_slots.size():
        skill_slots[slot_id].set_cooldown(ratio, remaining)

func _on_slot_clicked(slot_id:int)->void:
    EventBus.shortcut_slot_skill_changed.emit(slot_id)

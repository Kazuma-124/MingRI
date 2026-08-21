extends PanelContainer
class_name SkillShortcutBar

@export var _slot_ui_scene:PackedScene

# 技能槽引用数组
var _primary_slot:SkillSlotUI
var _short_slots: Array[SkillSlotUI] = []

@onready var _slots_container: HBoxContainer = $SlotsContainer


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
    _primary_slot = _slot_ui_scene.instantiate()
    _slots_container.add_child(_primary_slot)
    _primary_slot.clicked.connect(
        func() ->void:
            EventBus.primary_attack_slot_clicked.emit()
    )

    # ui点击信号->EventBus
    var count = p.data.skill_slot_count
    for i in range(count):
        var slot_ui = _slot_ui_scene.instantiate()
        _short_slots.append(slot_ui)
        _slots_container.add_child(slot_ui)
        slot_ui.clicked.connect(
            EventBus.shortcut_slot_clicked.emit.bind(i)
        )

    # Event技能槽数据信号->技能槽ui
    EventBus.player_primary_attack_switched.connect(_on_primary_skill_switched)
    EventBus.shortcut_skill_changed.connect(_on_shortcut_skill_changed)
    # 手动初始化ui信息
    _primary_slot.set_skill(p.state.curr_primary_attack_skill_id) 
    for i in range(count):
        var skill_id:StringName = p.state.get_slot_skill_id(i) 
        _short_slots[i].set_skill(skill_id)

func _on_primary_skill_switched(skill_id):
    _primary_slot.set_skill(skill_id)
func _on_shortcut_skill_changed(slot_id: int, skill_id: StringName) -> void:
    if slot_id >= 0 && slot_id < _short_slots.size():
        _short_slots[slot_id].set_skill(skill_id)


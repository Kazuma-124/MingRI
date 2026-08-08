extends PanelContainer
class_name SkillShortcutBar

@export var slot_ui_scene:PackedScene

# 技能槽引用数组
var skill_slots: Array[SkillSlotUI] = []
var skill_slots_count:int

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
    var primary_slot = slot_ui_scene.instantiate()
    skill_slots.append(primary_slot)
    slots_container.add_child(primary_slot)
    primary_slot.clicked.connect(_on_slot_clicked.bind(0))

    var count = p.data.skill_slot_count
    for i in range(count):
        var slot_id = i+1
        var slot_ui = slot_ui_scene.instantiate()
        skill_slots.append(slot_ui)
        slots_container.add_child(slot_ui)
        slot_ui.clicked.connect(_on_slot_clicked.bind(slot_id))
    EventBus.equiped_skill_changed.connect(_on_skill_changed)
    EventBus.equiped_skill_cooldown_updated.connect(_on_cooldown_updated)
    p.update_skill_slot_data_to_ui()

func _on_skill_changed(slot_id: int, skill: SkillData) -> void:
    if slot_id >= 0 && slot_id < skill_slots.size():
        skill_slots[slot_id].set_skill(skill)

func _on_cooldown_updated(slot_id: int, ratio: float, remaining: float) -> void:
    if slot_id >= 0 && slot_id < skill_slots.size():
        skill_slots[slot_id].set_cooldown(ratio, remaining)

func _on_slot_clicked(slot_id:int)->void:
    EventBus.equiped_skill_slot_clicked.emit(slot_id)

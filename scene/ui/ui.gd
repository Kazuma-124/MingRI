extends CanvasLayer


var player:CharacterBody2D

@onready var hp_and_mp_status: HBoxContainer = $UiRoot/HpAndMpStatus
@onready var primary_attack_slot: Control = $UiRoot/PrimaryAttackSlot
# ui.gd
func bind_state(state: PlayerRuntimeState) -> void:
    hp_and_mp_status.bind_state(state)

func bind_primary_attack_slot(slot: SkillSlot) -> void:
    primary_attack_slot.bind_skill_slot(slot)


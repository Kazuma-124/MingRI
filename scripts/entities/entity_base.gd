extends CharacterBody2D
class_name EntityBase

@export var max_hp:float = 100.0
@export var defense:float = 100.0


var hp:float 
var is_dead:bool = false

func take_demage(damage_info):
    # 子类可重写
    hp-=damage_info.damage
    if hp<=0:
        die()

func die():
    is_dead = true
    EventBus.entity_die.emit(self)
    queue_free()


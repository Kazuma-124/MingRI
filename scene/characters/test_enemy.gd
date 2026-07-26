extends CharacterBody2D

var max_hp:float = 100
var _cur_hp:float

func _ready() -> void:
    _cur_hp = max_hp

func _physics_process(delta: float) -> void:
    if _cur_hp <= 0:
        queue_free()

func take_damage(damage:float):
    _cur_hp-=damage
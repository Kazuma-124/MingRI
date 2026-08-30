extends RefCounted
class_name StatusEffect

var target:CharacterBody2D
var duration:float = 0.0
var _elapsed:float = 0.0

func apply(_t:CharacterBody2D)->void:
    target = _t

func update(delta:float)->bool:
    _elapsed+=delta
    return _elapsed<duration # false=效果结束

func remove()->void:pass

extends Node

signal entity_damaged(attacker, target, damage_info)
signal entity_died(entity)
signal energy_changed(attribute, amount)
signal level_up(attribute, new_level)
signal item_picked(item)
signal room_loaded(room_data)
signal skill_casted(skill_id, caster)

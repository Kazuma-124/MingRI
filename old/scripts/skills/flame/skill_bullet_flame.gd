extends SkillLogicBase
class_name SkillBulletFlame

    
func execute(caster: EntityBase, data: SkillData) -> void:
    # 1. 拿瞄准方向（统一接口，玩家是鼠标，敌人是AI目标）
    var aim_dir: Vector2 = caster.get_aim_direction()
    if aim_dir == Vector2.ZERO:
        return
    
    # 2. 实例化子弹特效场景
    var bullet = data.effect_scene.instantiate()
    
    # 3. 给子弹初始化参数
    bullet.setup(
        caster,
        data.damage,
        data.element,
        aim_dir,
        data.get("fly_speed"),  # 飞行速度，默认400
        data.get("cast_range")   # 最大飞行距离，默认600
    )
    
    # 4. 加到房间节点（玩家的父节点），不挂玩家下面
    caster.get_parent().add_child(bullet)
    bullet.global_position = caster.global_position

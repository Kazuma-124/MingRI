extends EntityBase
class_name Player

# ==================== 配置参数 ====================
@export var move_speed: float = 120.0

# ==================== 技能槽常量（方便维护，避免魔法数字） ====================
const SLOT_PRIMARY_ATTACK: int = 0  # 0号槽：普攻
const SLOT_SKILL_1: int = 1         # 1号槽：技能1
const SLOT_SKILL_2: int = 2
const SLOT_SKILL_3: int = 3
const SLOT_SKILL_4: int = 4
const TOTAL_SKILL_SLOTS: int = 5

# ==================== 状态变量 ====================
enum MoveState { IDLE, MOVE }
var move_state: MoveState = MoveState.IDLE
var facing_suffix: StringName = &"down"

# ==================== 技能槽 ====================
var skill_slots: Array[SkillSlot] = []  # ✅ 新增：技能槽数组

# ==================== 节点引用 ====================
@onready var body_sprite: AnimatedSprite2D = $BodySprite
@onready var weapon_pivot: Node2D = $WeaponPivot

# ==================== 生命周期 ====================
func _ready() -> void:
    hp = max_hp
    _init_skill_slots()  # ✅ 新增：初始化技能槽
    _update_facing()
    _update_animation()

func _physics_process(delta: float) -> void:
    if is_dead:
        return
    self.energy_flame = 100
    _update_facing()
    _handle_movement()
    _update_skill_cooldowns(delta)  # ✅ 新增：每帧更新所有技能冷却
    _update_animation()

# ==================== 输入处理（新增） ====================
func _unhandled_input(event: InputEvent) -> void:
    if is_dead:
        return
    
    # 鼠标左键 → 普攻
    if event.is_action_pressed("attack_primary"):
        skill_slots[SLOT_PRIMARY_ATTACK].cast(self)
    
    # 键盘 1~4 → 主动技能
    if event.is_action_pressed("skill_1"):
        skill_slots[SLOT_SKILL_1].cast(self)
    if event.is_action_pressed("skill_2"):
        skill_slots[SLOT_SKILL_2].cast(self)
    if event.is_action_pressed("skill_3"):
        skill_slots[SLOT_SKILL_3].cast(self)
    if event.is_action_pressed("skill_4"):
        skill_slots[SLOT_SKILL_4].cast(self)

# ==================== 技能槽初始化（新增） ====================
func _init_skill_slots() -> void:
    # 创建5个空技能槽
    for i in TOTAL_SKILL_SLOTS:
        skill_slots.append(SkillSlot.new())
    
    # 给普攻槽装备烈焰弹
    skill_slots[SLOT_PRIMARY_ATTACK].equip("bullet_flame")

# ==================== 技能冷却更新（新增） ====================
func _update_skill_cooldowns(delta: float) -> void:
    for slot in skill_slots:
        slot.update(delta)

# ==================== 朝向计算 ====================
func get_aim_direction() -> Vector2:
    var dir = get_global_mouse_position() - global_position
    return dir.normalized()

func _update_facing() -> void:
    var mouse_dir: Vector2 = get_global_mouse_position() - global_position
    if mouse_dir == Vector2.ZERO:
        return
    
    facing_suffix = _vector_to_facing(mouse_dir)
    
    weapon_pivot.rotation = mouse_dir.angle()
    weapon_pivot.scale.y = 1.0 if mouse_dir.x >= 0 else -1.0

# ==================== 移动逻辑 ====================
func _handle_movement() -> void:
    var move_input: Vector2 = Input.get_vector(
        "move_left", "move_right",
        "move_up", "move_down"
    )
    
    velocity = move_input * move_speed
    move_and_slide()
    
    move_state = MoveState.MOVE if move_input != Vector2.ZERO else MoveState.IDLE

# ==================== 动画更新 ====================
func _update_animation() -> void:
    var anim_prefix: StringName
    match move_state:
        MoveState.MOVE:
            anim_prefix = &"walk"
        _:
            anim_prefix = &"idle"
    
    var anim_name: StringName = StringName("%s_%s" % [anim_prefix, facing_suffix])
    
    if not body_sprite.sprite_frames.has_animation(anim_name):
        push_warning("Player missing animation: %s" % anim_name)
        return
    
    if body_sprite.animation != anim_name:
        body_sprite.play(anim_name)

# ==================== 工具函数 ====================
func _vector_to_facing(dir: Vector2) -> StringName:
    if abs(dir.x) >= abs(dir.y):
        return &"right" if dir.x > 0 else &"left"
    else:
        return &"down" if dir.y > 0 else &"up"

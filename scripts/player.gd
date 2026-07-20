extends CharacterBody2D

# 普通朝向动画名前缀
const NORMAL_ANIMATION_PREFIX := &"normal"
# 当前朝向后缀, 对应动画名中的up/down/right/left
var facing_suffix:StringName = &"right"

# @onready，场景准备就绪时赋值,
@onready var body_sprite:AnimatedSprite2D = $BodySprite
@onready var armed_effect_sprite: AnimatedSprite2D = $ArmedEffectSprite

# 玩家移动速度，像素/秒
@export var move_speed:float = 120.0

func _ready() -> void:
	_update_animation()

# 移动
func _physics_process(delta: float) -> void:
	# 根据四个方向的移动输入，得到标准化后的八向输入向量
	var move_input := Input.get_vector("move_left","move_right","move_up","move_down")
	
	# 矢量速度move_speed变向量速度,写入属性velocity中
	velocity = move_input * move_speed
	move_and_slide()

	if move_input!=Vector2.ZERO :
		facing_suffix = _vector_to_facing_suffix(move_input)

	_update_animation()

func _update_animation():
	var animation_name = StringName("%s_%s"%[NORMAL_ANIMATION_PREFIX,facing_suffix])
	if not body_sprite.sprite_frames.has_animation(animation_name):
		push_warning("Missing player animation %s"%animation_name)
		return

	if body_sprite.animation!=animation_name:
		body_sprite.play(animation_name)

# 将二维向量映射为四个方向的后缀名
# 四个方向在x轴有两个，y轴有两个
# 优先取绝对值更大的轴作为方向所在轴
func _vector_to_facing_suffix(direction:Vector2)->StringName:
	if abs(direction.x) >= abs(direction.y):
		return &"right" if direction.x>0.0 else &"left"
	return &"down" if direction.y>0.0 else &"up"















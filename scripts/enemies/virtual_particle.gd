# 虚粒子 - 纪元一
# 周期性闪烁进入无敌（不可锁定），考验观测者塔的配合
class_name VirtualParticle
extends EnemyBase

var blink_interval: float = 5.0
var blink_duration: float = 1.0
var blink_timer: float
var is_blinking: bool = false

func _ready() -> void:
	enemy_name = "虚粒子"
	max_health = 10.0
	speed = 90.0
	armor = 0.0
	reward_crystals = 5
	damage_to_base = 1
	blink_timer = blink_interval
	add_to_group("enemy")
	super()

func _process(delta: float) -> void:
	super(delta)
	if is_dead:
		return

	blink_timer -= delta
	if not is_blinking and blink_timer <= 0:
		_start_blink()
	elif is_blinking and blink_timer <= 0:
		_end_blink()

func _start_blink() -> void:
	is_blinking = true
	is_visible_target = false
	blink_timer = blink_duration
	modulate.a = 0.3

func _end_blink() -> void:
	is_blinking = false
	is_visible_target = true
	blink_timer = blink_interval
	modulate.a = 1.0

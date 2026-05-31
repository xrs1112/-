# Bullet - 子弹
# 塔发射后飞向敌人，命中造成伤害后消失

extends Node2D

var damage: float = 1.0
var speed: float = 300.0
var target: Node2D = null
var color: Color = Color.YELLOW

func _ready() -> void:
	add_to_group("bullet")
	queue_redraw()

func setup(tgt: Node2D, dmg: float, spd: float, clr: Color) -> void:
	target = tgt
	damage = dmg
	speed = spd
	color = clr

func _process(delta: float) -> void:
	if not is_instance_valid(target):
		queue_free()
		return

	# 飞向目标
	var dir = target.global_position - global_position
	var dist = dir.length()

	if dist < 8.0:
		# 命中
		_hit_target()
		return

	dir = dir.normalized()
	global_position += dir * speed * delta

func _hit_target() -> void:
	if is_instance_valid(target) and target.has_method("take_damage"):
		target.take_damage(damage)
	queue_free()

func _draw() -> void:
	draw_circle(Vector2.ZERO, 3.0, color)
	draw_circle(Vector2.ZERO, 3.0, Color.WHITE, false, 1.0)

# 虚粒子陷阱 - 纪元一
# 放置在地面，敌人触碰引爆范围伤害，短暂冷却后可再次触发
class_name QuarkTrap
extends TowerBase

var explosion_damage: float = 25.0
var has_exploded: bool = false
var cooldown_after_explosion: float = 3.0
var cooldown_timer: float = 0.0

func _ready() -> void:
	tower_name = "虚粒子陷阱"
	description = "敌人触碰时引爆，造成范围伤害。短暂冷却后可再次触发。"
	build_cost = 80
	attack_damage = 0.0
	attack_speed = 0.0
	attack_range = 60.0
	upgrade_cost = 60
	super()

func _process(delta: float) -> void:
	super(delta)
	if not placed or GameState.game_over or GameState.game_paused:
		return

	if has_exploded:
		cooldown_timer -= delta
		if cooldown_timer <= 0:
			has_exploded = false
		return

	# 检测触碰
	var bodies = range_indicator.get_overlapping_bodies()
	for body in bodies:
		var enemy = body as EnemyBase
		if enemy and not enemy.is_dead:
			_explode()
			break

func _try_attack() -> void:
	pass  # 陷阱不主动攻击

func _explode() -> void:
	has_exploded = true
	cooldown_timer = cooldown_after_explosion
	var bodies = range_indicator.get_overlapping_bodies()
	for body in bodies:
		var enemy = body as EnemyBase
		if enemy and not enemy.is_dead:
			enemy.take_damage(explosion_damage)

func upgrade() -> bool:
	if not super():
		return false
	match level:
		2: explosion_damage = 35.0; cooldown_after_explosion = 2.5
		3: explosion_damage = 50.0; cooldown_after_explosion = 2.0
	_setup_range()
	return true

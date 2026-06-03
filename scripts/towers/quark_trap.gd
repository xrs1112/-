# 虚粒子阱 - 范围爆炸塔
class_name QuarkTrap
extends TowerBase

var explosion_damage: float = 3.0
var explosion_radius: float = 80.0
var has_exploded: bool = false
var cooldown_after_explosion: float = 2.0
var cooldown_timer: float = 0.0

var shockwave_active: bool = false
var shockwave_timer: float = 0.0
var shockwave_duration: float = 0.35

func _ready() -> void:
	tower_name = "虚粒子阱"
	description = "敌人靠近时释放范围脉冲"
	build_cost = 26
	attack_damage = 0.0
	attack_speed = 0.0
	attack_range = explosion_radius
	upgrade_cost = 34
	tower_color = Color(0.7, 0.25, 0.15, 0.8)  # 暗红
	super()

func _process(delta: float) -> void:
	if upgrade_flash_timer > 0.0:
		upgrade_flash_timer -= delta
		queue_redraw()
	if level >= 3:
		queue_redraw()

	if shockwave_active:
		shockwave_timer -= delta
		if shockwave_timer <= 0:
			shockwave_active = false
		queue_redraw()

	if not placed or GameState.game_over or GameState.game_paused:
		return

	if has_exploded:
		cooldown_timer -= delta
		if cooldown_timer <= 0:
			has_exploded = false
		return

	for enemy in get_tree().get_nodes_in_group("enemy"):
		if enemy is EnemyBase and not enemy.is_dead:
			if global_position.distance_to(enemy.global_position) <= explosion_radius:
				_explode()
				break

func _try_attack() -> void:
	pass

func _explode() -> void:
	has_exploded = true
	cooldown_timer = cooldown_after_explosion
	shockwave_active = true
	shockwave_timer = shockwave_duration
	queue_redraw()
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if enemy is EnemyBase and not enemy.is_dead:
			if global_position.distance_to(enemy.global_position) <= explosion_radius:
				enemy.take_damage(explosion_damage)

func upgrade() -> bool:
	if not super():
		return false
	match level:
		2:
			explosion_damage = 5.0
			explosion_radius = 92.0
			attack_range = explosion_radius
			cooldown_after_explosion = 1.5
		3:
			explosion_damage = 8.0
			explosion_radius = 108.0
			attack_range = explosion_radius
			cooldown_after_explosion = 1.0
	queue_redraw()
	return true

func get_upgrade_preview() -> String:
	match level:
		1:
			return "下级: 爆发 5.0，半径 92，冷却 1.5s"
		2:
			return "下级: 爆发 8.0，半径 108，冷却 1.0s"
		_:
			return "已满级: 高密度脉冲阱已激活"

func get_stats_text() -> String:
	return "爆发 %.1f  半径 %d\n冷却 %.1fs" % [
		explosion_damage,
		int(explosion_radius),
		cooldown_after_explosion,
	]

func _draw() -> void:
	super()

	if shockwave_active:
		var progress = 1.0 - shockwave_timer / shockwave_duration
		var radius = lerpf(12.0, explosion_radius, progress)
		var alpha = 1.0 - progress
		var wave_color = Color(1.0, 0.45, 0.15, 0.55 * alpha)
		var edge_color = Color(1.0, 0.9, 0.45, 0.8 * alpha)
		draw_circle(Vector2.ZERO, radius, wave_color, false, 5.0)
		draw_circle(Vector2.ZERO, radius * 0.72, Color(1.0, 0.25, 0.08, 0.3 * alpha), false, 2.5)
		draw_circle(Vector2.ZERO, min(radius + 4.0, explosion_radius), edge_color, false, 1.5)

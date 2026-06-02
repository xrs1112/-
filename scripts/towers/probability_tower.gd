# 量子棱镜 - 基础攻击塔
class_name ProbabilityTower
extends TowerBase

func _ready() -> void:
	tower_name = "量子棱镜"
	description = "稳定发射量子束，适合基础输出"
	build_cost = 10
	attack_damage = 1.0
	attack_speed = 1.0
	attack_range = 150.0
	upgrade_cost = 15
	tower_color = Color(0.3, 0.3, 0.7, 0.8)  # 深蓝紫
	super()

func upgrade() -> bool:
	if not super():
		return false
	match level:
		2:
			attack_damage += 1.0
		3:
			attack_damage += 0.5
			attack_speed += 0.25
	return true

func _perform_attack(target) -> void:
	super(target)
	if level < 3:
		return

	var secondary = _find_secondary_target(target)
	if secondary:
		_fire_bullet(secondary, attack_damage * 0.65, 360.0, Color(0.62, 1.0, 0.96, 0.9))

func _find_secondary_target(primary):
	var enemies = get_tree().get_nodes_in_group("enemy")
	var nearest = null
	var nearest_dist: float = INF
	for enemy in enemies:
		if enemy == primary:
			continue
		if enemy is EnemyBase and not enemy.is_dead and enemy.is_visible_target:
			var dist = global_position.distance_to(enemy.global_position)
			if dist <= attack_range and dist < nearest_dist:
				nearest_dist = dist
				nearest = enemy
	return nearest

func get_upgrade_preview() -> String:
	match level:
		1:
			return "下级: 伤害 +%.1f，强化棱镜导轨" % (upgrade_damage_bonus + 1.0)
		2:
			return "下级: 解锁折射副光束，攻速 +%.1f" % (upgrade_speed_bonus + 0.25)
		_:
			return "已满级: 折射副光束已激活"

func get_stats_text() -> String:
	var text = "伤害 %.1f  攻速 %.1f\n射程 %d" % [
		attack_damage,
		attack_speed,
		int(attack_range),
	]
	if level >= 3:
		text += "\n特性: 折射攻击副目标"
	return text
